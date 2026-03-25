package main

import (
	"context"
	"testing"
	"time"
)

func TestEventDispatcher_ProcessSessionEvent_NewSession(t *testing.T) {
	tests := []struct {
		name         string
		event        SessionEvent
		expectedType ChangeType
	}{
		{
			name: "new session from JSONL user event",
			event: SessionEvent{
				SessionID:    "sess-1",
				ProjectPath:  "/path/to/project",
				Type:         EventTypeUser,
				Timestamp:    time.Now(),
				MessageID:    "msg-1",
				ContentIndex: 0,
				IsLastContent: true,
				Content: EventContent{
					Text: "Hello",
				},
			},
			expectedType: ChangeTypeNew,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			registry := NewSessionRegistry(time.Now)
			sessionEvCh := make(chan SessionEvent, 10)
			hookEvCh := make(chan HookEvent, 10)
			outCh := make(chan DispatchedEvent, 10)

			dispatcher := NewEventDispatcher(registry, sessionEvCh, hookEvCh, outCh, time.Now)

			dispatcher.processSessionEvent(tt.event)

			select {
			case dispatched := <-outCh:
				if dispatched.ChangeType != tt.expectedType {
					t.Errorf("expected ChangeType %v, got %v", tt.expectedType, dispatched.ChangeType)
				}
				if dispatched.Session.ID != tt.event.SessionID {
					t.Errorf("expected SessionID %s, got %s", tt.event.SessionID, dispatched.Session.ID)
				}
			case <-time.After(100 * time.Millisecond):
				t.Error("expected event on output channel")
			}
		})
	}
}

func TestEventDispatcher_ProcessHookEvent_SubagentStart(t *testing.T) {
	tests := []struct {
		name         string
		event        HookEvent
		expectedType ChangeType
	}{
		{
			name: "SubagentStart creates new session",
			event: HookEvent{
				Type:      HookEventSubagentStart,
				AgentID:   "agent-1",
				AgentType: "rosemary",
				SessionID: "sess-hook-1",
				Timestamp: time.Now().Format(time.RFC3339),
			},
			expectedType: ChangeTypeNew,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			registry := NewSessionRegistry(time.Now)
			sessionEvCh := make(chan SessionEvent, 10)
			hookEvCh := make(chan HookEvent, 10)
			outCh := make(chan DispatchedEvent, 10)

			dispatcher := NewEventDispatcher(registry, sessionEvCh, hookEvCh, outCh, time.Now)

			dispatcher.processHookEvent(tt.event)

			select {
			case dispatched := <-outCh:
				if dispatched.ChangeType != tt.expectedType {
					t.Errorf("expected ChangeType %v, got %v", tt.expectedType, dispatched.ChangeType)
				}
				if dispatched.Session.AgentID != tt.event.AgentID {
					t.Errorf("expected AgentID %s, got %s", tt.event.AgentID, dispatched.Session.AgentID)
				}
			case <-time.After(100 * time.Millisecond):
				t.Error("expected event on output channel")
			}
		})
	}
}

func TestEventDispatcher_ProcessHookEvent_SubagentStop_Completed(t *testing.T) {
	tests := []struct {
		name         string
		setup        func(*SessionRegistry)
		event        HookEvent
		expectedType ChangeType
	}{
		{
			name: "SubagentStop sets status to completed immediately",
			setup: func(registry *SessionRegistry) {
				// Pre-create session with SubagentStart
				registry.UpsertFromHookEvent(HookEvent{
					Type:      HookEventSubagentStart,
					AgentID:   "agent-1",
					AgentType: "rosemary",
					SessionID: "sess-stop-1",
					Timestamp: time.Now().Format(time.RFC3339),
				})
			},
			event: HookEvent{
				Type:      HookEventSubagentStop,
				AgentID:   "agent-1",
				SessionID: "sess-stop-1",
				Timestamp: time.Now().Format(time.RFC3339),
				LastMessage: "Task completed",
			},
			expectedType: ChangeTypeStatusChanged,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			registry := NewSessionRegistry(time.Now)
			tt.setup(registry)

			sessionEvCh := make(chan SessionEvent, 10)
			hookEvCh := make(chan HookEvent, 10)
			outCh := make(chan DispatchedEvent, 10)

			dispatcher := NewEventDispatcher(registry, sessionEvCh, hookEvCh, outCh, time.Now)

			dispatcher.processHookEvent(tt.event)

			select {
			case dispatched := <-outCh:
				if dispatched.Session.Status != SessionStatusCompleted {
					t.Errorf("expected status completed, got %s", dispatched.Session.Status)
				}
			case <-time.After(100 * time.Millisecond):
				t.Error("expected event on output channel")
			}
		})
	}
}

func TestEventDispatcher_Dedup_HTTPFirst_JSONLIgnored(t *testing.T) {
	mockTime := time.Date(2024, 1, 1, 12, 0, 0, 0, time.UTC)
	timeProvider := func() time.Time { return mockTime }

	registry := NewSessionRegistry(timeProvider)
	sessionEvCh := make(chan SessionEvent, 10)
	hookEvCh := make(chan HookEvent, 10)
	outCh := make(chan DispatchedEvent, 10)

	dispatcher := NewEventDispatcher(registry, sessionEvCh, hookEvCh, outCh, timeProvider)

	// HTTP event 先到
	httpEvent := HookEvent{
		Type:      HookEventSubagentStart,
		AgentID:   "agent-1",
		AgentType: "rosemary",
		SessionID: "sess-dedup-1",
		Timestamp: mockTime.Format(time.RFC3339),
	}
	dispatcher.processHookEvent(httpEvent)

	// 消費第一個事件
	<-outCh

	// JSONL event 後到，相同的 dedup key（基於 MessageID/AgentID + Type + 時間窗口）
	sessionEvent := SessionEvent{
		SessionID:    "sess-dedup-1",
		ProjectPath:  "/path",
		Type:         HookEventSubagentStart, // 使用相同的 type
		Timestamp:    mockTime,
		MessageID:    "agent-1", // 相同 agentID
		ContentIndex: 0,
		Content: EventContent{
			Text: "some text",
		},
	}
	dispatcher.processSessionEvent(sessionEvent)

	// 應該沒有新事件推送（JSONL 被忽略）
	select {
	case <-outCh:
		t.Error("expected no event (should be deduplicated)")
	case <-time.After(100 * time.Millisecond):
		// 預期：無事件
	}
}

func TestEventDispatcher_Dedup_OutsideWindow(t *testing.T) {
	mockTime := time.Date(2024, 1, 1, 12, 0, 0, 0, time.UTC)
	currentTime := mockTime

	timeProvider := func() time.Time { return currentTime }

	registry := NewSessionRegistry(timeProvider)
	sessionEvCh := make(chan SessionEvent, 10)
	hookEvCh := make(chan HookEvent, 10)
	outCh := make(chan DispatchedEvent, 10)

	dispatcher := NewEventDispatcher(registry, sessionEvCh, hookEvCh, outCh, timeProvider)

	// HTTP event 先到
	httpEvent := HookEvent{
		Type:      HookEventSubagentStart,
		AgentID:   "agent-1",
		AgentType: "rosemary",
		SessionID: "sess-window-1",
		Timestamp: currentTime.Format(time.RFC3339),
	}
	dispatcher.processHookEvent(httpEvent)
	<-outCh

	// 推進時間超過 DedupWindowDuration (5 秒)
	currentTime = mockTime.Add(6 * time.Second)

	// 相同的 JSONL event 應該被接受（因為超出窗口）
	sessionEvent := SessionEvent{
		SessionID:    "sess-window-1",
		ProjectPath:  "/path",
		Type:         HookEventSubagentStart,
		Timestamp:    currentTime,
		MessageID:    "agent-1",
		ContentIndex: 0,
		Content: EventContent{
			Text: "text outside window",
		},
	}
	dispatcher.processSessionEvent(sessionEvent)

	// 應該有新事件推送（不被去重）
	select {
	case dispatched := <-outCh:
		if dispatched.Session.EventCount != 1 {
			t.Errorf("expected event count 1, got %d", dispatched.Session.EventCount)
		}
	case <-time.After(100 * time.Millisecond):
		t.Error("expected event on output channel (outside dedup window)")
	}
}

func TestEventDispatcher_OutChFull_DropsEvent(t *testing.T) {
	mockTime := time.Now()
	registry := NewSessionRegistry(func() time.Time { return mockTime })
	sessionEvCh := make(chan SessionEvent, 10)
	hookEvCh := make(chan HookEvent, 10)
	outCh := make(chan DispatchedEvent, 1) // 僅 1 個位置

	dispatcher := NewEventDispatcher(registry, sessionEvCh, hookEvCh, outCh, func() time.Time { return mockTime })

	// 填滿輸出通道
	outCh <- DispatchedEvent{
		ChangeType: ChangeTypeNew,
		Session:    &SessionInfo{ID: "pre-filled"},
		Timestamp:  mockTime,
	}

	// 嘗試推送下一個事件（應該丟棄，但 registry 仍更新）
	sessionEvent := SessionEvent{
		SessionID:    "sess-full-1",
		ProjectPath:  "/path",
		Type:         EventTypeUser,
		Timestamp:    mockTime,
		MessageID:    "msg-1",
		ContentIndex: 0,
		Content: EventContent{
			Text: "test",
		},
	}
	dispatcher.processSessionEvent(sessionEvent)

	// 驗證 registry 被更新（即使 outCh 滿）
	session, ok := registry.Get("sess-full-1")
	if !ok || session == nil {
		t.Error("expected session to be in registry")
	}
}

func TestEventDispatcher_Run_ContextCancel(t *testing.T) {
	registry := NewSessionRegistry(time.Now)
	sessionEvCh := make(chan SessionEvent, 10)
	hookEvCh := make(chan HookEvent, 10)
	outCh := make(chan DispatchedEvent, 10)

	dispatcher := NewEventDispatcher(registry, sessionEvCh, hookEvCh, outCh, time.Now)

	ctx, cancel := context.WithCancel(context.Background())

	// 在 goroutine 中啟動 dispatcher
	done := make(chan struct{})
	go func() {
		dispatcher.Run(ctx)
		close(done)
	}()

	// 短暫延遲，確保 dispatcher 啟動
	time.Sleep(50 * time.Millisecond)

	// 取消 context
	cancel()

	// 等待 dispatcher 停止
	select {
	case <-done:
		// 預期：正常停止
	case <-time.After(1 * time.Second):
		t.Error("expected dispatcher to stop after context cancel")
	}
}

func TestEventDispatcher_StatusScan(t *testing.T) {
	mockTime := time.Date(2024, 1, 1, 12, 0, 0, 0, time.UTC)
	currentTime := mockTime

	timeProvider := func() time.Time { return currentTime }

	registry := NewSessionRegistry(timeProvider)
	sessionEvCh := make(chan SessionEvent, 10)
	hookEvCh := make(chan HookEvent, 10)
	outCh := make(chan DispatchedEvent, 100)

	dispatcher := NewEventDispatcher(registry, sessionEvCh, hookEvCh, outCh, timeProvider)

	// 建立新 session
	sessionEvent := SessionEvent{
		SessionID:    "sess-scan-1",
		ProjectPath:  "/path",
		Type:         EventTypeUser,
		Timestamp:    currentTime,
		MessageID:    "msg-1",
		ContentIndex: 0,
		Content: EventContent{
			Text: "test",
		},
	}
	dispatcher.processSessionEvent(sessionEvent)
	<-outCh // 消費初始事件

	// 驗證狀態為 active
	session, _ := registry.Get("sess-scan-1")
	if session.Status != SessionStatusActive {
		t.Errorf("expected initial status active, got %s", session.Status)
	}

	// 推進時間超過 ActiveThreshold (2 分鐘)
	currentTime = mockTime.Add(3 * time.Minute)

	// 執行狀態掃描
	dispatcher.performStatusScan()

	// 應該收到狀態變更事件
	select {
	case dispatched := <-outCh:
		if dispatched.ChangeType != ChangeTypeStatusChanged {
			t.Errorf("expected ChangeTypeStatusChanged, got %v", dispatched.ChangeType)
		}
		if dispatched.Session.Status != SessionStatusIdle {
			t.Errorf("expected status idle, got %s", dispatched.Session.Status)
		}
	case <-time.After(100 * time.Millisecond):
		t.Error("expected status change event")
	}
}
