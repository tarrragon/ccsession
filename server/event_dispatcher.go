package main

import (
	"context"
	"log/slog"
	"sync"
	"time"
)

// DispatchedEvent 是事件融合層的輸出結構體，
// 代表一個單一的狀態變更事件。
type DispatchedEvent struct {
	ChangeType ChangeType    `json:"changeType"`
	Session    *SessionInfo  `json:"session"`
	Timestamp  time.Time     `json:"timestamp"`
	Event      *SessionEvent `json:"event,omitempty"`
}

// deduplicationKey 用於去重檢查的複合鍵。
// unexported，不對外暴露實作細節。
type deduplicationKey struct {
	AgentID   string
	EventType string
	WindowKey time.Time
}

// EventDispatcher 融合 JSONL 事件和 HTTP Hook 事件，
// 推送統一的狀態變更事件到輸出通道。
//
// 去重邏輯：
//   - HTTP 事件優先。若 HTTP 先到，後續相同鍵的 JSONL 被忽略。
//   - 去重窗口為 DedupWindowDuration（5 秒）。
//   - 定期清理過期的去重記錄。
type EventDispatcher struct {
	registry    *SessionRegistry
	sessionEvCh <-chan SessionEvent
	hookEvCh    <-chan HookEvent
	outCh       chan<- DispatchedEvent
	dedupTable  map[deduplicationKey]EventSource
	dedupMu     sync.Mutex
	now         func() time.Time
}

// NewEventDispatcher 建構並初始化一個 EventDispatcher。
func NewEventDispatcher(
	registry *SessionRegistry,
	sessionEvCh <-chan SessionEvent,
	hookEvCh <-chan HookEvent,
	outCh chan<- DispatchedEvent,
	timeProvider func() time.Time,
) *EventDispatcher {
	if timeProvider == nil {
		timeProvider = time.Now
	}
	return &EventDispatcher{
		registry:    registry,
		sessionEvCh: sessionEvCh,
		hookEvCh:    hookEvCh,
		outCh:       outCh,
		dedupTable:  make(map[deduplicationKey]EventSource),
		now:         timeProvider,
	}
}

// Run 啟動 EventDispatcher 的主迴圈。
// 此方法阻塞，直到 ctx 被取消或輸入通道關閉。
func (d *EventDispatcher) Run(ctx context.Context) {
	logger := slog.Default()
	logger.Info(LogDispatcherStarted, "layer", "event_dispatcher")

	// 定時器：狀態掃描
	statusTicker := time.NewTicker(StatusScanInterval)
	defer statusTicker.Stop()

	// 定時器：去重表清理
	dedupTicker := time.NewTicker(DedupCleanupInterval)
	defer dedupTicker.Stop()

	for {
		select {
		case <-ctx.Done():
			logger.Info(LogDispatcherStopped, "layer", "event_dispatcher")
			return

		case event, ok := <-d.sessionEvCh:
			if !ok {
				logger.Info(LogSessionEvChClosed, "layer", "event_dispatcher")
				d.sessionEvCh = nil // 防止重複讀取
				continue
			}
			d.processSessionEvent(event)

		case event, ok := <-d.hookEvCh:
			if !ok {
				logger.Info(LogHookEvChClosed, "layer", "event_dispatcher")
				d.hookEvCh = nil // 防止重複讀取
				continue
			}
			d.processHookEvent(event)

		case <-statusTicker.C:
			d.performStatusScan()

		case <-dedupTicker.C:
			d.cleanupDedupTable()
		}
	}
}

// dispatchAfterUpdate 記錄舊狀態、執行 update、取得新狀態、推送事件。
// 提取自 processSessionEvent 和 processHookEvent 的共同邏輯。
func (d *EventDispatcher) dispatchAfterUpdate(sessionID string, timestamp time.Time, sessionEvent *SessionEvent, update func()) {
	oldSession, _ := d.registry.Get(sessionID)
	oldStatus := ""
	if oldSession != nil {
		oldStatus = string(oldSession.Status)
	}

	update()

	newSession, _ := d.registry.Get(sessionID)
	if newSession == nil {
		return
	}

	var changeType ChangeType
	if oldStatus == "" {
		changeType = ChangeTypeNew
	} else if string(newSession.Status) != oldStatus {
		changeType = ChangeTypeStatusChanged
	} else {
		changeType = ChangeTypeUpdated
	}

	d.sendToOutCh(DispatchedEvent{
		ChangeType: changeType,
		Session:    newSession,
		Timestamp:  timestamp,
		Event:      sessionEvent,
	})
}

// processSessionEvent 處理來自 JSONL 的 SessionEvent。
//
// 去重鍵構建：
//   - 優先使用 session 的 AgentID（若 session 已存在）
//   - 若 session 不存在，使用 SessionID 作為臨時識別符
//   - 目標：確保 JSONL 和 HTTP Hook 事件使用相同的語義去重
func (d *EventDispatcher) processSessionEvent(event SessionEvent) {
	logger := slog.Default()

	// 從 registry 讀取 session 的 AgentID（若存在）
	agentID := ""
	if session, ok := d.registry.Get(event.SessionID); ok && session != nil {
		agentID = session.AgentID
	}

	// 若 session 不存在或 AgentID 未設置，使用 SessionID 作為臨時識別符
	// 確保不同事件源的去重鍵語義一致
	if agentID == "" {
		agentID = event.SessionID
	}

	key := deduplicationKey{
		AgentID:   agentID,
		EventType: event.Type,
		WindowKey: event.Timestamp.Truncate(DedupWindowDuration),
	}

	d.dedupMu.Lock()
	if source, exists := d.dedupTable[key]; exists && source == EventSourceHTTP {
		d.dedupMu.Unlock()
		logger.Debug(LogEventDeduplicated,
			"layer", "event_dispatcher",
			"sessionID", event.SessionID,
			"reason", "HTTP event already processed",
			"agentID", agentID)
		return
	}
	d.dedupTable[key] = EventSourceJSONL
	d.dedupMu.Unlock()

	eventCopy := event
	d.dispatchAfterUpdate(event.SessionID, d.now(), &eventCopy, func() {
		d.registry.UpsertFromSessionEvent(event)
		d.registry.AppendEvent(event.SessionID, event)
	})

	logger.Info(LogJSONLEventProcessed,
		"layer", "event_dispatcher",
		"sessionID", event.SessionID,
		"agentID", agentID,
		"eventType", event.Type)
}

// processHookEvent 處理來自 HTTP Hook 的 HookEvent。
//
// 去重鍵構建：
//   - 優先使用 event.AgentID
//   - 若 AgentID 為空，使用 SessionID 作為臨時識別符
//   - 目標：確保去重鍵語義與 JSONL 事件一致
func (d *EventDispatcher) processHookEvent(event HookEvent) {
	logger := slog.Default()

	// 解析 Timestamp，預設使用當前時間
	timestamp := d.now()
	if event.Timestamp != "" {
		if t, err := time.Parse(time.RFC3339, event.Timestamp); err == nil {
			timestamp = t
		} else {
			logger.Warn(LogTimestampParseFailed,
				"layer", "event_dispatcher",
				"timestamp", event.Timestamp,
				"error", err)
		}
	}

	// 若 AgentID 為空，使用 SessionID 作為臨時識別符
	agentID := event.AgentID
	if agentID == "" {
		agentID = event.SessionID
	}

	key := deduplicationKey{
		AgentID:   agentID,
		EventType: event.Type,
		WindowKey: timestamp.Truncate(DedupWindowDuration),
	}

	d.dedupMu.Lock()
	if _, exists := d.dedupTable[key]; exists {
		d.dedupMu.Unlock()
		logger.Debug(LogEventDeduplicated,
			"layer", "event_dispatcher",
			"sessionID", event.SessionID,
			"reason", "duplicate HTTP event")
		return
	}
	d.dedupTable[key] = EventSourceHTTP
	d.dedupMu.Unlock()

	d.dispatchAfterUpdate(event.SessionID, timestamp, nil, func() {
		d.registry.UpsertFromHookEvent(event)
	})

	// 若 dispatchAfterUpdate 內 newSession 為 nil（孤立事件），
	// 不會推送事件，此處 log 仍記錄嘗試
	logger.Info(LogHookEventProcessed,
		"layer", "event_dispatcher",
		"sessionID", event.SessionID,
		"hookType", event.Type)
}

// sendToOutCh 嘗試將事件推送到輸出通道。
// 若通道滿，丟棄事件（non-blocking）。
func (d *EventDispatcher) sendToOutCh(event DispatchedEvent) {
	logger := slog.Default()
	select {
	case d.outCh <- event:
		// 成功推送
	default:
		logger.Warn(LogOutChFull,
			"layer", "event_dispatcher",
			"sessionID", event.Session.ID)
	}
}

// performStatusScan 定期掃描所有 session，推送狀態變更事件。
func (d *EventDispatcher) performStatusScan() {
	logger := slog.Default()

	// 呼叫 registry 掃描
	updated := d.registry.ScanAndUpdateStatus()

	if len(updated) > 0 {
		logger.Info(LogStatusScanCompleted,
			"layer", "event_dispatcher",
			"updatedCount", len(updated))

		// 為每個狀態變更推送事件
		for _, session := range updated {
			d.sendToOutCh(DispatchedEvent{
				ChangeType: ChangeTypeStatusChanged,
				Session:    session,
				Timestamp:  d.now(),
			})
		}
	}
}

// cleanupDedupTable 清理過期的去重記錄。
func (d *EventDispatcher) cleanupDedupTable() {
	logger := slog.Default()

	d.dedupMu.Lock()
	defer d.dedupMu.Unlock()

	now := d.now()
	expireTime := now.Add(-DedupWindowDuration)
	removed := 0

	for key := range d.dedupTable {
		if key.WindowKey.Before(expireTime) {
			delete(d.dedupTable, key)
			removed++
		}
	}

	if removed > 0 {
		logger.Debug(LogDedupTableCleaned,
			"layer", "event_dispatcher",
			"removed", removed,
			"remaining", len(d.dedupTable))
	}
}
