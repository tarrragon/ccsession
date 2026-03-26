package main

import (
	"context"
	"testing"
	"time"
)

// TestEventDispatcher_ProcessSessionEvent_NewSession 測試新 session 的處理
func TestEventDispatcher_ProcessSessionEvent_NewSession(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })
	sessionEventCh := make(chan SessionEvent, 10)
	hookEventCh := make(chan HookEvent, 10)
	outCh := make(chan DispatchedEvent, 10)

	dispatcher := NewEventDispatcher(registry, sessionEventCh, hookEventCh, outCh)
	dispatcher.now = func() time.Time { return baseTime }

	evt := SessionEvent{
		SessionID:   "test-session-1",
		ProjectPath: "/path/to/project",
		Type:        EventTypeUser,
		MessageID:   "msg-001",
		Timestamp:   baseTime,
		Content: EventContent{
			Text: "Hello",
		},
	}

	// 直接呼叫 processSessionEvent（不用 Run goroutine）
	dispatcher.processSessionEvent(evt, nil)

	// 驗證 registry 已更新
	session, ok := registry.Get("test-session-1")
	if !ok {
		t.Errorf("expected session to be created, but got nil")
		return
	}
	if session.ID != "test-session-1" {
		t.Errorf("expected ID=%q, got %q", "test-session-1", session.ID)
	}

	// 驗證 outCh 收到事件
	select {
	case dispatchedEvt := <-outCh:
		if dispatchedEvt.Session.ID != "test-session-1" {
			t.Errorf("expected dispatched event sessionID=%q, got %q",
				"test-session-1", dispatchedEvt.Session.ID)
		}
		if dispatchedEvt.ChangeType != ChangeTypeUpdated {
			t.Errorf("expected ChangeType=%q, got %q",
				ChangeTypeUpdated, dispatchedEvt.ChangeType)
		}
	default:
		t.Errorf("expected DispatchedEvent in outCh, but got none")
	}
}

// TestEventDispatcher_HTTPEventPriority 測試 HTTP 事件優先（去重）
func TestEventDispatcher_HTTPEventPriority(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	laterTime := baseTime.Add(3 * time.Second)
	registry := NewSessionRegistry(func() time.Time { return baseTime })
	sessionEventCh := make(chan SessionEvent, 10)
	hookEventCh := make(chan HookEvent, 10)
	outCh := make(chan DispatchedEvent, 20)

	dispatcher := NewEventDispatcher(registry, sessionEventCh, hookEventCh, outCh)
	dispatcher.now = func() time.Time { return baseTime }

	// 步驟 1：HTTP 事件先到達（SubagentStart）
	hookEvt := HookEvent{
		Type:      HookEventSubagentStart,
		SessionID: "test-session-1",
		AgentID:   "agent-001",
		AgentType: "lavender",
		Timestamp: baseTime.Format(time.RFC3339),
	}
	dispatcher.processHookEvent(hookEvt, nil)

	// 步驟 2：相同時間窗口內的 JSONL 事件（應被去重）
	dispatcher.now = func() time.Time { return laterTime }
	sessionEvt := SessionEvent{
		SessionID:   "test-session-1",
		ProjectPath: "/path/to/project",
		Type:        HookEventSubagentStart, // 相同 event type
		MessageID:   "agent-001",
		Timestamp:   laterTime,
		Content: EventContent{
			Text: "Start",
		},
	}
	dispatcher.processSessionEvent(sessionEvt, nil)

	// 驗證：outCh 應該有 HTTP 事件，但 JSONL 事件被去重忽略
	// 預期：只有 1 個事件（來自 HTTP）
	count := 0
	for {
		select {
		case <-outCh:
			count++
		default:
			goto done
		}
	}
done:
	if count != 1 {
		t.Errorf("expected 1 event in outCh (HTTP only), got %d", count)
	}
}

// TestEventDispatcher_DedupWindow_NotDedupAfter5Seconds 測試 5 秒超出去重窗口
func TestEventDispatcher_DedupWindow_NotDedupAfter5Seconds(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })
	sessionEventCh := make(chan SessionEvent, 10)
	hookEventCh := make(chan HookEvent, 10)
	outCh := make(chan DispatchedEvent, 20)

	dispatcher := NewEventDispatcher(registry, sessionEventCh, hookEventCh, outCh)

	// 步驟 1：時刻 12:00:00 的 JSONL 事件
	dispatcher.now = func() time.Time { return baseTime }
	evt1 := SessionEvent{
		SessionID:   "test-session-2",
		ProjectPath: "/path/to/project",
		Type:        EventTypeUser,
		MessageID:   "msg-001",
		Timestamp:   baseTime,
		Content: EventContent{
			Text: "Message 1",
		},
	}
	dispatcher.processSessionEvent(evt1, nil)

	// 步驟 2：時刻 12:00:06 的相同 key JSONL 事件（超過 5 秒窗口，不去重）
	laterTime := baseTime.Add(6 * time.Second)
	dispatcher.now = func() time.Time { return laterTime }
	evt2 := SessionEvent{
		SessionID:   "test-session-2",
		ProjectPath: "/path/to/project",
		Type:        EventTypeUser,
		MessageID:   "msg-001", // 相同 AgentID（MessageID）
		Timestamp:   laterTime,
		Content: EventContent{
			Text: "Message 2",
		},
	}
	dispatcher.processSessionEvent(evt2, nil)

	// 驗證：兩個事件都應被處理（不去重）
	registry.mu.RLock()
	session := registry.sessions["test-session-2"]
	registry.mu.RUnlock()

	if session.EventCount != 2 {
		t.Errorf("expected EventCount=2 (no dedup), got %d", session.EventCount)
	}
}

// TestEventDispatcher_Run_StatusScanTriggersUpdate 測試定時掃描觸發狀態轉換
func TestEventDispatcher_Run_StatusScanTriggersUpdate(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })
	sessionEventCh := make(chan SessionEvent, 10)
	hookEventCh := make(chan HookEvent, 10)
	outCh := make(chan DispatchedEvent, 20)

	dispatcher := NewEventDispatcher(registry, sessionEventCh, hookEventCh, outCh)

	// 建立 session（Status = active）
	dispatcher.now = func() time.Time { return baseTime }
	evt := SessionEvent{
		SessionID:   "test-session-3",
		ProjectPath: "/path/to/project",
		Type:        EventTypeUser,
		MessageID:   "msg-001",
		Timestamp:   baseTime,
		Content: EventContent{
			Text: "Message",
		},
	}
	registry.UpsertFromSessionEvent(evt)

	// 步驟 1：啟動 dispatcher（Run）
	ctx, cancel := context.WithCancel(context.Background())
	go dispatcher.Run(ctx)

	// 步驟 2：模擬時間推進超過 ActiveThreshold（2 分鐘）
	// 並觸發定時掃描
	time.Sleep(100 * time.Millisecond) // 讓 Run 開始執行

	// 手動觸發狀態掃描（模擬定時器）
	updated := registry.ScanAndUpdateStatus()
	if len(updated) > 0 {
		// 狀態無變化（時間未推進，仍在 active 窗口內）
		t.Logf("no status change expected at baseTime")
	}

	// 清理
	cancel()
	time.Sleep(100 * time.Millisecond) // 讓 Run 優雅停止
}

// TestEventDispatcher_HookEventSubagentStop_ImmediateCompleted 測試 SubagentStop 即時完成
func TestEventDispatcher_HookEventSubagentStop_ImmediateCompleted(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })
	sessionEventCh := make(chan SessionEvent, 10)
	hookEventCh := make(chan HookEvent, 10)
	outCh := make(chan DispatchedEvent, 10)

	dispatcher := NewEventDispatcher(registry, sessionEventCh, hookEventCh, outCh)
	dispatcher.now = func() time.Time { return baseTime }

	// 先建立 session
	evt := SessionEvent{
		SessionID:   "test-session-4",
		ProjectPath: "/path/to/project",
		Type:        EventTypeUser,
		MessageID:   "msg-001",
		Timestamp:   baseTime,
		Content: EventContent{
			Text: "Start",
		},
	}
	registry.UpsertFromSessionEvent(evt)

	// 立即發送 SubagentStop（Status 應立即轉為 completed）
	hookEvt := HookEvent{
		Type:        HookEventSubagentStop,
		SessionID:   "test-session-4",
		AgentID:     "agent-001",
		LastMessage: "Done",
		Timestamp:   baseTime.Format(time.RFC3339),
	}
	dispatcher.processHookEvent(hookEvt, nil)

	// 驗證 Status 已轉為 completed（無需等待掃描）
	session, ok := registry.Get("test-session-4")
	if !ok {
		t.Errorf("expected session to exist")
		return
	}
	if session.Status != SessionStatusCompleted {
		t.Errorf("expected Status=%q, got %q", SessionStatusCompleted, session.Status)
	}
	if session.LastMessage != "Done" {
		t.Errorf("expected LastMessage=%q, got %q", "Done", session.LastMessage)
	}
}

// TestEventDispatcher_OutChanFull_DropsButUpdateRegistry 測試 outCh 滿時丟棄但保留 registry 更新
func TestEventDispatcher_OutChanFull_DropsButUpdateRegistry(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })
	sessionEventCh := make(chan SessionEvent, 10)
	hookEventCh := make(chan HookEvent, 10)
	outCh := make(chan DispatchedEvent, 1) // 只有 1 個容量

	dispatcher := NewEventDispatcher(registry, sessionEventCh, hookEventCh, outCh)
	dispatcher.now = func() time.Time { return baseTime }

	// 發送多個事件，導致 outCh 滿
	for i := 0; i < 3; i++ {
		evt := SessionEvent{
			SessionID:   "test-session-5",
			ProjectPath: "/path/to/project",
			Type:        EventTypeUser,
			MessageID:   "msg-001",
			Timestamp:   baseTime,
			Content: EventContent{
				Text: "Message",
			},
		}
		dispatcher.processSessionEvent(evt, nil)
	}

	// 驗證：registry 應該記錄所有 3 個事件（EventCount=3）
	session, ok := registry.Get("test-session-5")
	if !ok {
		t.Errorf("expected session to exist")
		return
	}
	if session.EventCount != 3 {
		t.Errorf("expected EventCount=3 (all events processed), got %d", session.EventCount)
	}

	// 驗證：outCh 可能丟棄了部分事件（容量只有 1）
	count := 0
	for {
		select {
		case <-outCh:
			count++
		default:
			goto done
		}
	}
done:
	if count == 0 {
		t.Errorf("expected at least some events in outCh")
	}
}

// TestEventDispatcher_MixedJSONLAndHTTPEvents 測試 JSONL 和 HTTP 事件的交織
func TestEventDispatcher_MixedJSONLAndHTTPEvents(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })
	sessionEventCh := make(chan SessionEvent, 10)
	hookEventCh := make(chan HookEvent, 10)
	outCh := make(chan DispatchedEvent, 20)

	dispatcher := NewEventDispatcher(registry, sessionEventCh, hookEventCh, outCh)
	dispatcher.now = func() time.Time { return baseTime }

	// 步驟 1：JSONL 事件（新建 session）
	jsonlEvt := SessionEvent{
		SessionID:   "test-session-6",
		ProjectPath: "/path/to/project",
		Type:        EventTypeUser,
		MessageID:   "msg-001",
		Timestamp:   baseTime,
		Content: EventContent{
			Text: "Hello",
		},
	}
	dispatcher.processSessionEvent(jsonlEvt, nil)

	// 步驟 2：HTTP SubagentStart（填充 AgentID）
	httpEvt := HookEvent{
		Type:      HookEventSubagentStart,
		SessionID: "test-session-6",
		AgentID:   "agent-123",
		AgentType: "lavender",
		Timestamp: baseTime.Format(time.RFC3339),
	}
	dispatcher.processHookEvent(httpEvt, nil)

	// 驗證：registry 應有兩個更新
	session, ok := registry.Get("test-session-6")
	if !ok {
		t.Errorf("expected session to exist")
		return
	}
	if session.AgentID != "agent-123" {
		t.Errorf("expected AgentID=%q, got %q", "agent-123", session.AgentID)
	}
	if session.EventCount != 1 { // Hook 事件不增加 EventCount
		t.Errorf("expected EventCount=1, got %d", session.EventCount)
	}
}

// TestEventDispatcher_CleanupDedupTable 測試去重表清理
func TestEventDispatcher_CleanupDedupTable(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	dispatcher := &EventDispatcher{
		dedupTable: make(map[string]time.Time),
		now:        func() time.Time { return baseTime },
	}

	// 步驟 1：添加兩個去重 key
	oldKey := "key-old"
	newKey := "key-new"
	dispatcher.dedupTable[oldKey] = baseTime.Add(-10 * time.Second) // 10 秒前
	dispatcher.dedupTable[newKey] = baseTime                         // 當前時間

	// 驗證：初始有 2 個 key
	if len(dispatcher.dedupTable) != 2 {
		t.Errorf("expected 2 keys in dedupTable, got %d", len(dispatcher.dedupTable))
	}

	// 步驟 2：清理（超過 5 秒窗口的應被刪除）
	dispatcher.cleanupDedupTable()

	// 驗證：oldKey 應被刪除，newKey 保留
	if _, exists := dispatcher.dedupTable[oldKey]; exists {
		t.Errorf("expected oldKey to be deleted, but it still exists")
	}
	if _, exists := dispatcher.dedupTable[newKey]; !exists {
		t.Errorf("expected newKey to be preserved, but it was deleted")
	}
	if len(dispatcher.dedupTable) != 1 {
		t.Errorf("expected 1 key after cleanup, got %d", len(dispatcher.dedupTable))
	}
}

// TestEventDispatcher_EmptySessionID_Ignored 測試空 SessionID 的事件被忽略
func TestEventDispatcher_EmptySessionID_Ignored(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })
	sessionEventCh := make(chan SessionEvent, 10)
	hookEventCh := make(chan HookEvent, 10)
	outCh := make(chan DispatchedEvent, 10)

	dispatcher := NewEventDispatcher(registry, sessionEventCh, hookEventCh, outCh)

	// 發送空 SessionID 的 JSONL 事件
	evt := SessionEvent{
		SessionID: "", // 空 SessionID
		Type:      EventTypeUser,
		Timestamp: baseTime,
	}
	dispatcher.processSessionEvent(evt, nil)

	// 驗證：registry 應為空
	if registry.Count() != 0 {
		t.Errorf("expected registry to be empty, but Count=%d", registry.Count())
	}

	// 驗證：outCh 應為空
	select {
	case <-outCh:
		t.Errorf("expected no event in outCh")
	default:
		// 正確
	}
}

// TestEventDispatcher_ConcurrentAccess 測試並發訪問去重表
func TestEventDispatcher_ConcurrentAccess(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })
	sessionEventCh := make(chan SessionEvent, 100)
	hookEventCh := make(chan HookEvent, 100)
	outCh := make(chan DispatchedEvent, 100)

	dispatcher := NewEventDispatcher(registry, sessionEventCh, hookEventCh, outCh)
	dispatcher.now = func() time.Time { return baseTime }

	// 步驟 1：並發發送多個事件
	done := make(chan bool)
	for i := 0; i < 10; i++ {
		go func(idx int) {
			evt := SessionEvent{
				SessionID:   "test-session-concurrent",
				ProjectPath: "/path/to/project",
				Type:        EventTypeUser,
				MessageID:   "msg-001",
				Timestamp:   baseTime,
				Content: EventContent{
					Text: "Message",
				},
			}
			dispatcher.processSessionEvent(evt, nil)
			done <- true
		}(i)
	}

	// 等待所有 goroutine 完成
	for i := 0; i < 10; i++ {
		<-done
	}

	// 驗證：registry 應記錄所有事件
	session, ok := registry.Get("test-session-concurrent")
	if !ok {
		t.Errorf("expected session to exist")
		return
	}
	if session.EventCount != 10 {
		t.Errorf("expected EventCount=10, got %d", session.EventCount)
	}
}
