package main

import (
	"errors"
	"log/slog"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
)

// SessionRegistry 是所有 session 狀態的 Source of Truth。
// 所有對 session 狀態的讀取和修改都透過此結構體進行。
//
// 並發安全：使用 sync.RWMutex 保護所有欄位存取。
//   - 讀取操作（Get, List）使用 RLock
//   - 寫入操作（Upsert, UpdateStatus）使用 Lock
// errSessionNotFound is returned when a session is not found in the registry.
var errSessionNotFound = errors.New("session not found")

type SessionRegistry struct {
	sessions map[string]*SessionInfo
	history  map[string][]*SessionEvent
	mu       sync.RWMutex
	now      func() time.Time // 時間提供者，便於測試注入
}

// NewSessionRegistry 建立並初始化一個空的 SessionRegistry。
// timeProvider 用於注入時間函式（便於測試），若為 nil 則使用 time.Now。
func NewSessionRegistry(timeProvider func() time.Time) *SessionRegistry {
	if timeProvider == nil {
		timeProvider = time.Now
	}
	return &SessionRegistry{
		sessions: make(map[string]*SessionInfo),
		history:  make(map[string][]*SessionEvent),
		now:      timeProvider,
	}
}

// UpsertFromSessionEvent 依據 JSONL 事件更新或建立 SessionInfo。
//
// 行為規則：
//   - 若 sessionID 不存在 → 建立新的 SessionInfo，Status 設為 active
//   - 若 sessionID 已存在 → 更新 LastEventAt、EventCount（+1）
//   - 若 type == "session_completed" → 強制設定 Status 為 completed
//   - 其他類型 → 重新計算 Status（呼叫 computeStatus，傳入當前時間）
//   - 若為首個 user 訊息（FirstUserMessageAt 未設定且 Type == "user"）→ 填入時戳
//   - 每次 user 事件都覆蓋 Summary（截斷至 MaxSummaryLength）
func (r *SessionRegistry) UpsertFromSessionEvent(event SessionEvent) {
	if event.SessionID == "" {
		return // 忽略空 SessionID
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	now := r.now()

	// 若事件帶有實際時間戳（如初始掃描的檔案修改時間），優先使用；
	// 否則使用當前時間（即時事件）。
	eventTime := now
	if !event.Timestamp.IsZero() {
		eventTime = event.Timestamp
	}

	session, exists := r.sessions[event.SessionID]

	if !exists {
		// 新建 session
		session = &SessionInfo{
			ID:           event.SessionID,
			ProjectPath:  event.ProjectPath,
			Status:       SessionStatusActive,
			FirstEventAt: eventTime,
			LastEventAt:  eventTime,
			EventCount:   0,
		}
		r.sessions[event.SessionID] = session
	}

	// 更新現有或新建的 session
	session.EventCount++

	// 即時事件（非初始掃描）：LastEventAt 使用當前時間，
	// 因為 eventTime 是 JSONL 中記錄的歷史時間，可能遠早於偵測時刻，
	// 會導致 ScanAndUpdateStatus 用真正的 now 計算時誤判為 idle/completed。
	// 初始掃描事件：使用 eventTime（檔案修改時間）保持一致性。
	if event.Type == EventTypeSessionDiscovered {
		session.LastEventAt = eventTime
	} else {
		session.LastEventAt = now
	}

	// 記錄首個 user 事件時戳
	if event.Type == EventTypeUser && session.FirstUserMessageAt.IsZero() {
		session.FirstUserMessageAt = eventTime
	}

	// 每次 user 事件覆蓋 Summary 為最新內容
	if event.Type == EventTypeUser {
		session.Summary = truncateSummary(event.Content.Text, MaxSummaryLength)
	}

	// 若為 session_completed 事件，強制設定狀態
	if event.Type == EventTypeSessionCompleted {
		session.Status = SessionStatusCompleted
	} else if event.Type == EventTypeSessionDiscovered {
		// 初始掃描事件：使用事件時間（檔案修改時間）作為 now，
		// 避免因 now - ModTime 過大而誤判 active session 為 idle/completed。
		// 後續的 ScanAndUpdateStatus 會用真正的 now 重新計算正確狀態。
		session.Status = r.computeStatus(session, eventTime)
	} else {
		// 即時事件表示 session 正在活動，直接設為 active，
		// 繞過 computeStatus 的終態保護（IMP-040）
		session.Status = SessionStatusActive
	}
}

// UpsertFromHookEvent 依據 HTTP Hook 事件更新 SessionInfo。
//
// 行為規則（依 event.Type）：
//   - SubagentStart:
//     - 若 sessionID 不存在 → 建立 SessionInfo（最小化填充，等待 JSONL 補充）
//     - 更新 AgentID、AgentType
//     - 若 ParentAgentID 非空 → 填入 SessionInfo.ParentAgentID（v0.3 預留）
//     - 強制設定 Status 為 active
//   - SubagentStop:
//     - 若 sessionID 不存在 → 忽略（孤立事件）
//     - 更新 LastMessage、LastEventAt
//     - 強制設定 Status 為 completed（即時，不等候超時）
//   - TaskCompleted:
//     - 若 sessionID 不存在 → 忽略
//     - 更新 LastEventAt
//     - 重新計算 Status（不強制 completed）
//   - TeammateIdle:
//     - 若 sessionID 不存在 → 忽略
//     - 更新 LastEventAt
//     - 強制設定 Status 為 idle
func (r *SessionRegistry) UpsertFromHookEvent(event HookEvent) {
	if event.SessionID == "" {
		return // 忽略空 SessionID
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	now := r.now()
	session, exists := r.sessions[event.SessionID]

	// 根據事件類型進行不同的處理
	switch event.Type {
	case HookEventSubagentStart:
		// SubagentStart 可創建新 session
		if !exists {
			session = &SessionInfo{
				ID:         event.SessionID,
				Status:     SessionStatusActive,
				FirstEventAt: now,
				LastEventAt:  now,
			}
			r.sessions[event.SessionID] = session
		}
		session.AgentID = event.AgentID
		session.AgentType = event.AgentType
		session.LastEventAt = now
		if event.ParentAgentID != "" {
			session.ParentAgentID = event.ParentAgentID
		}
		session.Status = SessionStatusActive

	case HookEventSubagentStop:
		// SubagentStop 的 session_id 是主 session ID（非 subagent）。
		// 主 session 仍在運行，不應被標記為 completed。
		// 若 TranscriptPath 存在，從中提取 subagent session ID 並註冊。
		if exists {
			session.LastEventAt = now
		}

		// 從 TranscriptPath 提取 subagent session ID 並建立獨立的 registry 條目
		subagentID := extractSessionIDFromPath(event.TranscriptPath)
		if subagentID == "" {
			slog.Debug(LogSubagentPathEmpty,
				"layer", "session_registry",
				"mainSessionID", event.SessionID)
			return
		}

		subSession, subExists := r.sessions[subagentID]
		if !subExists {
			subSession = &SessionInfo{
				ID:           subagentID,
				Status:       SessionStatusCompleted,
				FirstEventAt: now,
				LastEventAt:  now,
			}
			r.sessions[subagentID] = subSession
		}
		subSession.AgentID = event.AgentID
		subSession.AgentType = event.AgentType
		subSession.LastMessage = event.LastMessage
		subSession.LastEventAt = now
		subSession.ParentAgentID = event.ParentAgentID
		subSession.Status = SessionStatusCompleted

		slog.Info(LogSubagentRegistered,
			"layer", "session_registry",
			"subagentID", subagentID,
			"mainSessionID", event.SessionID)

	case HookEventTaskCompleted:
		// TaskCompleted 只在已存在的 session 上處理
		if !exists {
			return
		}
		session.LastEventAt = now
		session.Status = r.computeStatus(session, now)

	case HookEventTeammateIdle:
		// TeammateIdle 只在已存在的 session 上處理
		if !exists {
			return
		}
		session.LastEventAt = now
		session.Status = SessionStatusIdle // 強制 idle

	default:
		// 未知 Hook 事件類型，忽略
		return
	}
}

// Get 查詢單一 session，若不存在返回 nil。
func (r *SessionRegistry) Get(sessionID string) (*SessionInfo, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	session, ok := r.sessions[sessionID]
	if !ok {
		return nil, false
	}

	// 返回深度複製，避免外部修改
	return copySessionInfo(session), true
}

// List 返回所有 session 的深度複製列表。
func (r *SessionRegistry) List() []*SessionInfo {
	r.mu.RLock()
	defer r.mu.RUnlock()

	result := make([]*SessionInfo, 0, len(r.sessions))
	for _, session := range r.sessions {
		result = append(result, copySessionInfo(session))
	}
	return result
}

// Count 返回當前 registry 中 session 的總數。
func (r *SessionRegistry) Count() int {
	r.mu.RLock()
	defer r.mu.RUnlock()

	return len(r.sessions)
}

// ScanAndUpdateStatus 定時掃描所有 session，根據時間戳更新狀態。
// 此方法應定期呼叫（例如每 30 秒一次），以驅動狀態機轉換。
func (r *SessionRegistry) ScanAndUpdateStatus() []*SessionInfo {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := r.now()
	updated := make([]*SessionInfo, 0)

	for id, session := range r.sessions {
		// 需求：[0.4.0-W2-003] completed session 超過 eviction timeout 後從記憶體移除
		if session.Status == SessionStatusCompleted && now.Sub(session.LastEventAt) > CompletedSessionEvictionTimeout {
			slog.Info(LogSessionEvicted,
				"layer", "session_registry",
				"session_id", id,
				"lastEventAt", session.LastEventAt)
			delete(r.sessions, id)
			delete(r.history, id)
			continue
		}

		oldStatus := session.Status
		newStatus := r.computeStatus(session, now)

		if oldStatus != newStatus {
			session.Status = newStatus
			updated = append(updated, copySessionInfo(session))

			// 需求：[0.2.1-W5-002] 當 session 轉為 completed 時，
			// 裁剪歷史事件至 CompletedSessionMaxEvents，釋放記憶體。
			// 需求：[0.4.0-W2-003] 使用 copy-to-new-slice 確保舊 backing array 可被 GC。
			if newStatus == SessionStatusCompleted {
				if events := r.history[session.ID]; len(events) > CompletedSessionMaxEvents {
					slog.Warn(LogCompletedEventsTrimmed,
						"layer", "session_registry",
						"session_id", session.ID,
						"before", len(events),
						"after", CompletedSessionMaxEvents,
					)
					trimmed := make([]*SessionEvent, CompletedSessionMaxEvents)
					copy(trimmed, events[len(events)-CompletedSessionMaxEvents:])
					r.history[session.ID] = trimmed
				}
			}
		}
	}

	return updated
}

// computeStatus 根據 LastEventAt 計算 session 應該處於的狀態。
// 計算邏輯：
//   - 若距上次事件 < 2 分鐘 → active
//   - 若 2 分鐘 <= 距上次事件 < 30 分鐘 → idle
//   - 若 >= 30 分鐘 → completed
func (r *SessionRegistry) computeStatus(session *SessionInfo, now time.Time) SessionStatus {
	if session == nil {
		return SessionStatusActive // 預設狀態
	}

	// completed 是終態，不可被時間計算覆蓋
	if session.Status == SessionStatusCompleted {
		return SessionStatusCompleted
	}

	elapsed := now.Sub(session.LastEventAt)

	switch {
	case elapsed < ActiveThreshold:
		return SessionStatusActive
	case elapsed < IdleThreshold:
		return SessionStatusIdle
	default:
		return SessionStatusCompleted
	}
}

// truncateSummary 將字串截斷至最多 maxLen 字元。
func truncateSummary(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	// 使用 []rune 截斷，確保 UTF-8 字元邊界安全。
	// 先做 byte 長度快速路徑避免不必要的 rune 轉換。
	runes := []rune(s)
	if len(runes) <= maxLen {
		return s
	}
	return string(runes[:maxLen])
}

// AppendEvent appends a SessionEvent to the history for the given session.
// 需求：[0.2.1-W5-002] 限制每 session 事件數，防止記憶體無限增長。
// 超過 MaxEventsPerSession 時淘汰最早的事件。
func (r *SessionRegistry) AppendEvent(sessionID string, event SessionEvent) {
	r.mu.Lock()
	defer r.mu.Unlock()

	copied := event
	events := append(r.history[sessionID], &copied)

	// 需求：[0.4.0-W2-003] 使用 copy-to-new-slice 確保舊 backing array 可被 GC。
	if len(events) > MaxEventsPerSession {
		trimmed := make([]*SessionEvent, MaxEventsPerSession)
		copy(trimmed, events[len(events)-MaxEventsPerSession:])
		events = trimmed
	}
	r.history[sessionID] = events
}

// GetHistory returns paginated history events for the given session.
// Events are returned in ascending timestamp order.
// If before is zero, all events are considered (latest limit events).
// Returns errSessionNotFound if the session does not exist.
func (r *SessionRegistry) GetHistory(sessionID string, limit int, before time.Time) ([]*SessionEvent, bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	if _, exists := r.sessions[sessionID]; !exists {
		return nil, false, errSessionNotFound
	}

	events := r.history[sessionID]
	if len(events) == 0 {
		return []*SessionEvent{}, false, nil
	}

	// Filter by before if non-zero
	filtered := events
	if !before.IsZero() {
		filtered = make([]*SessionEvent, 0)
		for _, e := range events {
			if e.Timestamp.Before(before) {
				filtered = append(filtered, e)
			}
		}
	}

	// 不變式：append 順序 = 時間順序。
	// 依賴來源：AppendEvent 按 file watcher 的逐行讀取順序 append，
	// 而 JSONL 檔案由 Claude Code CLI 按時間順序寫入，因此 append 順序即時間順序。
	// 若此不變式被打破（例如亂序插入），非分頁路徑的結果將不正確。
	// 分頁路徑（before 篩選）額外排序作為防禦性保護。
	if !before.IsZero() {
		sort.Slice(filtered, func(i, j int) bool {
			return filtered[i].Timestamp.Before(filtered[j].Timestamp)
		})
	}

	hasMore := len(filtered) > limit
	if len(filtered) > limit {
		// Return the latest `limit` events
		filtered = filtered[len(filtered)-limit:]
	}

	// Deep copy
	result := make([]*SessionEvent, len(filtered))
	for i, e := range filtered {
		copied := *e
		result[i] = &copied
	}

	return result, hasMore, nil
}

// copySessionInfo 返回 SessionInfo 的深度複製。
func copySessionInfo(session *SessionInfo) *SessionInfo {
	if session == nil {
		return nil
	}
	copy := *session
	return &copy
}

// extractSessionIDFromPath 從 JSONL 檔案路徑提取 session UUID。
// 路徑格式：{any_prefix}/{session_uuid}.jsonl
// 返回空字串若路徑無效或不含 .jsonl 副檔名。
func extractSessionIDFromPath(path string) string {
	if path == "" {
		return ""
	}
	base := filepath.Base(path)
	if !strings.HasSuffix(base, JSONLExtension) {
		return ""
	}
	return strings.TrimSuffix(base, JSONLExtension)
}
