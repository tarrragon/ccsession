package main

import (
	"context"
	"fmt"
	"log/slog"
	"sync"
	"time"
)

// DispatchedEvent 是 EventDispatcher 輸出到 WebSocket Hub 的事件。
// 包含變更類型、SessionInfo 快照和時間戳。
type DispatchedEvent struct {
	ChangeType ChangeType `json:"changeType"`
	Session    *SessionInfo `json:"session"`
	Timestamp  time.Time  `json:"timestamp"`
}

// UnifiedEvent 是 EventDispatcher 內部的統一事件表示。
// 用於去重和路由處理。Caller 不應直接使用此型別。
type UnifiedEvent struct {
	Source    EventSource   // 事件來源（JSONL 或 HTTP）
	SessionID string        // 關聯的 session ID
	EventType string        // 事件類型（SessionEvent.Type 或 HookEvent.Type）
	Timestamp time.Time     // 事件時間（用於去重窗口計算）
	AgentID   string        // agent 識別符（用於去重 key 組合）

	// 原始事件（只有一個非 nil）
	SessionEvt *SessionEvent // JSONL 來源事件
	HookEvt    *HookEvent    // HTTP 來源事件
}

// deduplicationKey 是事件去重的組合鍵（內部使用）。
// 去重規則：AgentID + EventType + Timestamp（5 秒窗口內視為重複）
// HTTP 事件優先：若 HTTP 事件已處理，相同 dedup key 的 JSONL 事件被忽略。
type deduplicationKey struct {
	AgentID   string
	EventType string
	// Timestamp 被截斷至 5 秒窗口
	WindowKey time.Time
}

// EventDispatcher 是事件融合層的核心。
// 消費來自 SessionEvent 和 HookEvent 兩個 channel 的事件，
// 執行去重、狀態同步到 SessionRegistry，並輸出到 WebSocket。
//
// 並發安全：使用 sync.Mutex 保護 dedupTable。
type EventDispatcher struct {
	registry        *SessionRegistry
	sessionEventCh  <-chan SessionEvent
	hookEventCh     <-chan HookEvent
	outCh           chan<- DispatchedEvent
	dedupTable      map[string]time.Time  // dedup key -> timestamp
	dedupTableMu    sync.Mutex
	now             func() time.Time
	statusTicker    *time.Ticker
	cleanupTicker   *time.Ticker
}

// NewEventDispatcher 建立一個新的 EventDispatcher。
// registry: SessionRegistry 實例（必須）
// sessionEventCh: JSONL 事件輸入 channel（必須）
// hookEventCh: HTTP Hook 事件輸入 channel（必須）
// outCh: 輸出 channel，用於推送給 WebSocket Hub（必須）
func NewEventDispatcher(
	registry *SessionRegistry,
	sessionEventCh <-chan SessionEvent,
	hookEventCh <-chan HookEvent,
	outCh chan<- DispatchedEvent,
) *EventDispatcher {
	return &EventDispatcher{
		registry:       registry,
		sessionEventCh: sessionEventCh,
		hookEventCh:    hookEventCh,
		outCh:          outCh,
		dedupTable:     make(map[string]time.Time),
		now:            time.Now,
		statusTicker:   time.NewTicker(StatusScanInterval),
		cleanupTicker:  time.NewTicker(DedupCleanupInterval),
	}
}

// Run 開始事件循環，阻塞直到 ctx.Done()。
// 應在 goroutine 中執行：go dispatcher.Run(ctx)
//
// 事件循環：
//   1. 消費 sessionEventCh 和 hookEventCh（多路選擇）
//   2. 定時器：StatusScanInterval 觸發 registry.ScanAndUpdateStatus
//   3. 定時器：DedupCleanupInterval 觸發 cleanupDedupTable
//   4. ctx.Done() 時停止
func (d *EventDispatcher) Run(ctx context.Context) {
	logger := slog.Default()
	logger.Info(LogDispatcherStarted, "layer", "event_dispatcher")

	for {
		select {
		case <-ctx.Done():
			logger.Info(LogDispatcherStopped, "layer", "event_dispatcher")
			d.statusTicker.Stop()
			d.cleanupTicker.Stop()
			return

		case evt := <-d.sessionEventCh:
			// HTTP 優先：JSONL 事件來臨
			d.processSessionEvent(evt, logger)

		case evt := <-d.hookEventCh:
			// HTTP 事件優先級更高
			d.processHookEvent(evt, logger)

		case <-d.statusTicker.C:
			// 定時掃描，更新狀態機
			updated := d.registry.ScanAndUpdateStatus()
			for _, session := range updated {
				d.sendToOutCh(DispatchedEvent{
					ChangeType: ChangeTypeStatusChanged,
					Session:    session,
					Timestamp:  d.now(),
				})
			}

		case <-d.cleanupTicker.C:
			// 清理過期去重記錄
			d.cleanupDedupTable()
		}
	}
}

// processSessionEvent 處理來自 JSONL file watcher 的 SessionEvent。
// 步驟：
//   1. 嘗試 HTTP 事件去重（已有相同 dedup key 的 HTTP 事件則跳過）
//   2. 呼叫 registry.UpsertFromSessionEvent 更新狀態
//   3. 發送 DispatchedEvent 到 outCh
func (d *EventDispatcher) processSessionEvent(evt SessionEvent, logger *slog.Logger) {
	if evt.SessionID == "" {
		return
	}

	// 用 MessageID 作為 AgentID（JSONL 事件無 AgentID）
	agentID := evt.MessageID
	if agentID == "" {
		agentID = evt.SessionID
	}

	key := d.buildDedupKey(agentID, evt.Type, evt.Timestamp)

	// 檢查是否應該去重（HTTP 事件優先）
	if !d.shouldDeduplicate(key, EventSourceJSONL) {
		// 不去重，處理此事件
		d.registry.UpsertFromSessionEvent(evt)

		// 記錄去重 key（JSONL 已處理）
		d.recordDedupKey(key)

		// 發送到 outCh
		if session, ok := d.registry.Get(evt.SessionID); ok {
			d.sendToOutCh(DispatchedEvent{
				ChangeType: ChangeTypeUpdated,
				Session:    session,
				Timestamp:  d.now(),
			})
		}

		logger.Debug(LogSessionEventProcessed,
			"layer", "event_dispatcher",
			"sessionID", evt.SessionID,
			"eventType", evt.Type)
	} else {
		// 被去重忽略
		logger.Debug(LogDedupIgnoredEvent,
			"layer", "event_dispatcher",
			"sessionID", evt.SessionID,
			"eventType", evt.Type,
			"source", EventSourceJSONL)
	}
}

// processHookEvent 處理來自 HTTP Hooks 的 HookEvent。
// HTTP 事件優先級更高，會覆蓋去重表。
// 步驟：
//   1. 呼叫 registry.UpsertFromHookEvent 更新狀態
//   2. 記錄去重 key（HTTP 優先）
//   3. 發送 DispatchedEvent 到 outCh
func (d *EventDispatcher) processHookEvent(evt HookEvent, logger *slog.Logger) {
	if evt.SessionID == "" {
		return
	}

	// 解析 Hook 事件的時間戳
	ts, err := time.Parse(time.RFC3339, evt.Timestamp)
	if err != nil {
		ts = d.now()
	}

	key := d.buildDedupKey(evt.AgentID, evt.Type, ts)

	// 更新 registry（無去重判斷，HTTP 直接更新）
	d.registry.UpsertFromHookEvent(evt)

	// HTTP 優先：覆蓋去重表
	d.recordDedupKey(key)

	// 發送到 outCh
	if session, ok := d.registry.Get(evt.SessionID); ok {
		d.sendToOutCh(DispatchedEvent{
			ChangeType: ChangeTypeStatusChanged,
			Session:    session,
			Timestamp:  d.now(),
		})
	}

	logger.Debug(LogHookEventProcessed,
		"layer", "event_dispatcher",
		"sessionID", evt.SessionID,
		"eventType", evt.Type,
		"agentID", evt.AgentID)
}

// buildDedupKey 構建去重鍵。
// 格式：agentID + "|" + eventType + "|" + timestamp(5秒窗口)
func (d *EventDispatcher) buildDedupKey(agentID, eventType string, ts time.Time) string {
	windowKey := ts.Truncate(DedupWindowDuration)
	return fmt.Sprintf("%s|%s|%d", agentID, eventType, windowKey.Unix())
}

// shouldDeduplicate 判斷給定的去重 key 在對應 source 下是否應被去重。
// 規則：
//   - 若去重表中已有此 key → 返回 true（應去重）
//   - 若未在去重表中 → 返回 false（不去重）
// HTTP 事件總是返回 false（HTTP 永不被去重）
func (d *EventDispatcher) shouldDeduplicate(key string, source EventSource) bool {
	d.dedupTableMu.Lock()
	defer d.dedupTableMu.Unlock()

	_, exists := d.dedupTable[key]
	if source == EventSourceHTTP {
		// HTTP 事件永不被去重
		return false
	}

	// JSONL 事件：若 dedup table 中已存在 key，則被去重
	return exists
}

// recordDedupKey 記錄一個去重 key 和其時間戳。
func (d *EventDispatcher) recordDedupKey(key string) {
	d.dedupTableMu.Lock()
	defer d.dedupTableMu.Unlock()

	d.dedupTable[key] = d.now()
}

// cleanupDedupTable 清理過期的去重記錄（超過 5 秒窗口的）。
// 應定期呼叫（例如每 30 秒一次），防止記憶體洩漏。
func (d *EventDispatcher) cleanupDedupTable() {
	d.dedupTableMu.Lock()
	defer d.dedupTableMu.Unlock()

	now := d.now()
	threshold := now.Add(-DedupWindowDuration)

	for key, ts := range d.dedupTable {
		if ts.Before(threshold) {
			delete(d.dedupTable, key)
		}
	}

	slog.Default().Debug(LogDedupTableCleanup,
		"layer", "event_dispatcher",
		"remainingEntries", len(d.dedupTable))
}

// sendToOutCh 向 outCh 發送 DispatchedEvent。
// 非阻塞發送：若 outCh 滿則丟棄事件（但不影響 registry 已更新的狀態）。
func (d *EventDispatcher) sendToOutCh(evt DispatchedEvent) {
	select {
	case d.outCh <- evt:
		// 成功發送
	default:
		// outCh 滿，丟棄此事件（但 registry 已更新）
		slog.Default().Warn(LogDispatcherOutChanFull,
			"layer", "event_dispatcher",
			"sessionID", evt.Session.ID)
	}
}
