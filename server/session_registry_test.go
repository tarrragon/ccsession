package main

import (
	"testing"
	"time"
)

// TestSessionRegistry_UpsertFromSessionEvent_NewSession 測試新 session 的建立
func TestSessionRegistry_UpsertFromSessionEvent_NewSession(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	event := SessionEvent{
		SessionID:   "test-session-1",
		ProjectPath: "/path/to/project",
		Type:        EventTypeUser,
		Timestamp:   baseTime,
		Content: EventContent{
			Text: "Hello, Claude",
		},
	}

	registry.UpsertFromSessionEvent(event)

	session, ok := registry.Get("test-session-1")
	if !ok {
		t.Errorf("expected session to exist, but got nil")
		return
	}

	if session.ID != "test-session-1" {
		t.Errorf("expected ID=%q, got %q", "test-session-1", session.ID)
	}
	if session.Status != SessionStatusActive {
		t.Errorf("expected Status=%q, got %q", SessionStatusActive, session.Status)
	}
	if session.EventCount != 1 {
		t.Errorf("expected EventCount=1, got %d", session.EventCount)
	}
	if session.FirstEventAt != baseTime {
		t.Errorf("expected FirstEventAt=%v, got %v", baseTime, session.FirstEventAt)
	}
	if session.LastEventAt != baseTime {
		t.Errorf("expected LastEventAt=%v, got %v", baseTime, session.LastEventAt)
	}
	if session.FirstUserMessageAt != baseTime {
		t.Errorf("expected FirstUserMessageAt=%v, got %v", baseTime, session.FirstUserMessageAt)
	}
}

// TestSessionRegistry_UpsertFromSessionEvent_UpdateExisting 測試現有 session 的更新
func TestSessionRegistry_UpsertFromSessionEvent_UpdateExisting(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	laterTime := baseTime.Add(5 * time.Second)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	// 建立第一個事件
	event1 := SessionEvent{
		SessionID:   "test-session-2",
		ProjectPath: "/path/to/project",
		Type:        EventTypeUser,
		Timestamp:   baseTime,
		Content: EventContent{
			Text: "First message",
		},
	}
	registry.UpsertFromSessionEvent(event1)

	// 模擬時間推進
	registry.now = func() time.Time { return laterTime }

	// 建立第二個事件
	event2 := SessionEvent{
		SessionID: "test-session-2",
		Type:      EventTypeAssistant,
		Timestamp: laterTime,
		Content: EventContent{
			Text: "Assistant response",
		},
	}
	registry.UpsertFromSessionEvent(event2)

	session, _ := registry.Get("test-session-2")

	if session.EventCount != 2 {
		t.Errorf("expected EventCount=2, got %d", session.EventCount)
	}
	if session.LastEventAt != laterTime {
		t.Errorf("expected LastEventAt=%v, got %v", laterTime, session.LastEventAt)
	}
	if session.FirstEventAt != baseTime {
		t.Errorf("expected FirstEventAt unchanged=%v, got %v", baseTime, session.FirstEventAt)
	}
	if session.Status != SessionStatusActive {
		t.Errorf("expected Status=%q, got %q", SessionStatusActive, session.Status)
	}
}

// TestSessionRegistry_UpsertFromSessionEvent_FirstUserMessage 測試首個 user 訊息時戳
func TestSessionRegistry_UpsertFromSessionEvent_FirstUserMessage(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registryTime := baseTime
	registry := NewSessionRegistry(func() time.Time { return registryTime })

	// 事件序列：tool_use, tool_result, 然後 user
	events := []SessionEvent{
		{
			SessionID: "test-session-3",
			Type:      "tool_use",
			Timestamp: baseTime,
		},
		{
			SessionID: "test-session-3",
			Type:      "tool_result",
			Timestamp: baseTime.Add(1 * time.Second),
		},
		{
			SessionID: "test-session-3",
			Type:      EventTypeUser,
			Timestamp: baseTime.Add(5 * time.Second),
			Content: EventContent{
				Text: "User question",
			},
		},
	}

	for i, event := range events {
		registryTime = event.Timestamp
		registry.now = func() time.Time { return registryTime }
		registry.UpsertFromSessionEvent(event)

		session, _ := registry.Get("test-session-3")
		if session.EventCount != i+1 {
			t.Errorf("step %d: expected EventCount=%d, got %d", i, i+1, session.EventCount)
		}
	}

	session, _ := registry.Get("test-session-3")
	if session.FirstEventAt != baseTime {
		t.Errorf("expected FirstEventAt=%v, got %v", baseTime, session.FirstEventAt)
	}
	if session.FirstUserMessageAt != baseTime.Add(5*time.Second) {
		t.Errorf("expected FirstUserMessageAt=%v, got %v", baseTime.Add(5*time.Second), session.FirstUserMessageAt)
	}
}

// TestSessionRegistry_ListAndCount 測試 List 和 Count 操作
func TestSessionRegistry_ListAndCount(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	// 建立 3 個 session
	for i := 1; i <= 3; i++ {
		event := SessionEvent{
			SessionID: "session-" + string(rune('0'+i)),
			Type:      EventTypeUser,
			Timestamp: baseTime,
		}
		registry.UpsertFromSessionEvent(event)
	}

	if registry.Count() != 3 {
		t.Errorf("expected Count()=3, got %d", registry.Count())
	}

	list := registry.List()
	if len(list) != 3 {
		t.Errorf("expected List() length=3, got %d", len(list))
	}

	// 驗證深度複製：修改返回的 session 不影響內部狀態
	if len(list) > 0 {
		list[0].Status = SessionStatusCompleted
		session, _ := registry.Get(list[0].ID)
		if session.Status == SessionStatusCompleted {
			t.Errorf("expected deep copy, but modification affected internal state")
		}
	}
}

// TestSessionRegistry_UpsertFromHookEvent_SubagentStart 測試 SubagentStart Hook 事件
func TestSessionRegistry_UpsertFromHookEvent_SubagentStart(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	// 先建立 session（來自 JSONL）
	jsonlEvent := SessionEvent{
		SessionID: "hook-test-1",
		Type:      EventTypeUser,
		Timestamp: baseTime,
	}
	registry.UpsertFromSessionEvent(jsonlEvent)

	// 然後收到 SubagentStart Hook
	hookEvent := HookEvent{
		Type:      HookEventSubagentStart,
		SessionID: "hook-test-1",
		AgentID:   "agent-xyz",
		AgentType: "parsley",
	}
	registry.UpsertFromHookEvent(hookEvent)

	session, _ := registry.Get("hook-test-1")
	if session.AgentID != "agent-xyz" {
		t.Errorf("expected AgentID=%q, got %q", "agent-xyz", session.AgentID)
	}
	if session.AgentType != "parsley" {
		t.Errorf("expected AgentType=%q, got %q", "parsley", session.AgentType)
	}
	if session.Status != SessionStatusActive {
		t.Errorf("expected Status=%q, got %q", SessionStatusActive, session.Status)
	}
}

// TestSessionRegistry_UpsertFromHookEvent_SubagentStop 測試 SubagentStop Hook 事件
func TestSessionRegistry_UpsertFromHookEvent_SubagentStop(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	// 先建立 session
	jsonlEvent := SessionEvent{
		SessionID: "hook-test-2",
		Type:      EventTypeUser,
		Timestamp: baseTime,
	}
	registry.UpsertFromSessionEvent(jsonlEvent)

	session, _ := registry.Get("hook-test-2")
	if session.Status != SessionStatusActive {
		t.Fatalf("expected initial Status=%q", SessionStatusActive)
	}

	// 收到 SubagentStop Hook
	hookEvent := HookEvent{
		Type:        HookEventSubagentStop,
		SessionID:   "hook-test-2",
		LastMessage: "Task completed",
	}
	registry.UpsertFromHookEvent(hookEvent)

	session, _ = registry.Get("hook-test-2")
	if session.Status != SessionStatusCompleted {
		t.Errorf("expected Status=%q, got %q", SessionStatusCompleted, session.Status)
	}
	if session.LastMessage != "Task completed" {
		t.Errorf("expected LastMessage=%q, got %q", "Task completed", session.LastMessage)
	}
}

// TestSessionRegistry_UpsertFromHookEvent_TeammateIdle 測試 TeammateIdle Hook 事件
func TestSessionRegistry_UpsertFromHookEvent_TeammateIdle(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	// 先建立 session
	jsonlEvent := SessionEvent{
		SessionID: "hook-test-3",
		Type:      EventTypeUser,
		Timestamp: baseTime,
	}
	registry.UpsertFromSessionEvent(jsonlEvent)

	// 立即收到 TeammateIdle Hook（無等待超時）
	hookEvent := HookEvent{
		Type:      HookEventTeammateIdle,
		SessionID: "hook-test-3",
	}
	registry.UpsertFromHookEvent(hookEvent)

	session, _ := registry.Get("hook-test-3")
	if session.Status != SessionStatusIdle {
		t.Errorf("expected Status=%q, got %q", SessionStatusIdle, session.Status)
	}
}

// TestSessionRegistry_UpsertFromHookEvent_ParentAgentID 測試 ParentAgentID 欄位（v0.3 預留）
func TestSessionRegistry_UpsertFromHookEvent_ParentAgentID(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	// SubagentStart Hook 含 ParentAgentID
	hookEvent := HookEvent{
		Type:          HookEventSubagentStart,
		SessionID:     "hook-test-4",
		AgentID:       "child-agent",
		ParentAgentID: "parent-agent",
	}
	registry.UpsertFromHookEvent(hookEvent)

	session, ok := registry.Get("hook-test-4")
	if !ok {
		t.Fatalf("expected session to be created from SubagentStart")
	}
	if session.ParentAgentID != "parent-agent" {
		t.Errorf("expected ParentAgentID=%q, got %q", "parent-agent", session.ParentAgentID)
	}
}

// TestSessionRegistry_UpsertFromHookEvent_OrphanSubagentStop 測試孤立的 SubagentStop 事件
func TestSessionRegistry_UpsertFromHookEvent_OrphanSubagentStop(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	// 嘗試對不存在的 session 呼叫 SubagentStop
	hookEvent := HookEvent{
		Type:      HookEventSubagentStop,
		SessionID: "non-existent",
	}
	registry.UpsertFromHookEvent(hookEvent)

	// 驗證會話未被建立
	_, ok := registry.Get("non-existent")
	if ok {
		t.Errorf("expected session to NOT be created from orphan SubagentStop")
	}
	if registry.Count() != 0 {
		t.Errorf("expected Count()=0, got %d", registry.Count())
	}
}

// TestSessionRegistry_StatusTransition_ActiveToIdle 測試 active 轉 idle 狀態轉換
func TestSessionRegistry_StatusTransition_ActiveToIdle(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	// 建立 session
	event := SessionEvent{
		SessionID: "transition-test-1",
		Type:      EventTypeUser,
		Timestamp: baseTime,
	}
	registry.UpsertFromSessionEvent(event)

	session, _ := registry.Get("transition-test-1")
	if session.Status != SessionStatusActive {
		t.Fatalf("expected initial Status=%q", SessionStatusActive)
	}

	// 模擬時間推進超過 ActiveThreshold
	laterTime := baseTime.Add(3 * time.Minute)
	registry.now = func() time.Time { return laterTime }

	updated := registry.ScanAndUpdateStatus()

	// 驗證狀態已轉換
	session, _ = registry.Get("transition-test-1")
	if session.Status != SessionStatusIdle {
		t.Errorf("expected Status=%q after idle threshold, got %q", SessionStatusIdle, session.Status)
	}

	// 驗證返回的更新列表
	if len(updated) != 1 {
		t.Errorf("expected 1 updated session, got %d", len(updated))
	}
}

// TestSessionRegistry_StatusTransition_IdleToCompleted 測試 idle 轉 completed 狀態轉換
func TestSessionRegistry_StatusTransition_IdleToCompleted(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	// 建立 session
	event := SessionEvent{
		SessionID: "transition-test-2",
		Type:      EventTypeUser,
		Timestamp: baseTime,
	}
	registry.UpsertFromSessionEvent(event)

	// 模擬時間推進超過 IdleThreshold
	laterTime := baseTime.Add(31 * time.Minute)
	registry.now = func() time.Time { return laterTime }

	updated := registry.ScanAndUpdateStatus()

	// 驗證狀態已轉換為 completed
	session, _ := registry.Get("transition-test-2")
	if session.Status != SessionStatusCompleted {
		t.Errorf("expected Status=%q after idle threshold, got %q", SessionStatusCompleted, session.Status)
	}

	// 驗證返回的更新列表
	if len(updated) != 1 {
		t.Errorf("expected 1 updated session, got %d", len(updated))
	}
}

// TestSessionRegistry_ScanAndUpdateStatus_NoChange 測試 ScanAndUpdateStatus 在無狀態轉換時的行為
func TestSessionRegistry_ScanAndUpdateStatus_NoChange(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	// 建立 session
	event := SessionEvent{
		SessionID: "scan-test-1",
		Type:      EventTypeUser,
		Timestamp: baseTime,
	}
	registry.UpsertFromSessionEvent(event)

	// 只推進 1 分鐘（未超 ActiveThreshold）
	laterTime := baseTime.Add(1 * time.Minute)
	registry.now = func() time.Time { return laterTime }

	updated := registry.ScanAndUpdateStatus()

	// 驗證無狀態轉換
	if len(updated) != 0 {
		t.Errorf("expected no updates (status unchanged), got %d", len(updated))
	}

	session, _ := registry.Get("scan-test-1")
	if session.Status != SessionStatusActive {
		t.Errorf("expected Status unchanged=%q", SessionStatusActive)
	}
}

// TestSessionRegistry_SummaryTruncation 測試 Summary 截斷功能
func TestSessionRegistry_SummaryTruncation(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	// 建立長文本的首個 user 訊息
	longText := "This is a very long message that exceeds the maximum summary length of one hundred characters and should be truncated"
	event := SessionEvent{
		SessionID: "summary-test-1",
		Type:      EventTypeUser,
		Timestamp: baseTime,
		Content: EventContent{
			Text: longText,
		},
	}
	registry.UpsertFromSessionEvent(event)

	session, _ := registry.Get("summary-test-1")
	if len(session.Summary) > MaxSummaryLength {
		t.Errorf("expected Summary length <= %d, got %d", MaxSummaryLength, len(session.Summary))
	}

	// 驗證短文本不被截斷
	shortText := "Short message"
	event2 := SessionEvent{
		SessionID: "summary-test-2",
		Type:      EventTypeUser,
		Timestamp: baseTime,
		Content: EventContent{
			Text: shortText,
		},
	}
	registry.UpsertFromSessionEvent(event2)

	session2, _ := registry.Get("summary-test-2")
	if session2.Summary != shortText {
		t.Errorf("expected Summary=%q, got %q", shortText, session2.Summary)
	}
}

// TestScanAndUpdateStatus_DoesNotRevertCompleted 驗證 completed 是終態，
// ScanAndUpdateStatus 的時間計算不可將其覆蓋回 active。
func TestScanAndUpdateStatus_DoesNotRevertCompleted(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	// 建立 session
	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: "completed-guard-1",
		Type:      EventTypeUser,
		Timestamp: baseTime,
	})

	// 透過 SubagentStop 設為 completed
	registry.UpsertFromHookEvent(HookEvent{
		Type:      HookEventSubagentStop,
		SessionID: "completed-guard-1",
	})

	session, _ := registry.Get("completed-guard-1")
	if session.Status != SessionStatusCompleted {
		t.Fatalf("expected completed after SubagentStop, got %q", session.Status)
	}

	// 不推進時間（elapsed < ActiveThreshold），觸發掃描
	updated := registry.ScanAndUpdateStatus()

	session, _ = registry.Get("completed-guard-1")
	if session.Status != SessionStatusCompleted {
		t.Errorf("expected completed to be preserved, got %q", session.Status)
	}
	if len(updated) != 0 {
		t.Errorf("expected no updates for terminal completed session, got %d", len(updated))
	}
}

// TestUpsertFromSessionEvent_DoesNotRevertCompleted 驗證 completed 是終態，
// 後續非 session_completed 的 SessionEvent 不可將其覆蓋。
func TestUpsertFromSessionEvent_DoesNotRevertCompleted(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	// 建立 session
	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: "completed-guard-2",
		Type:      EventTypeUser,
		Timestamp: baseTime,
	})

	// 透過 SubagentStop 設為 completed
	registry.UpsertFromHookEvent(HookEvent{
		Type:      HookEventSubagentStop,
		SessionID: "completed-guard-2",
	})

	// 送入非 session_completed 的事件
	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: "completed-guard-2",
		Type:      EventTypeAssistant,
		Timestamp: baseTime,
	})

	session, _ := registry.Get("completed-guard-2")
	if session.Status != SessionStatusCompleted {
		t.Errorf("expected completed to be preserved after assistant event, got %q", session.Status)
	}
}

// TestSessionRegistry_ComputeStatus 測試狀態計算邏輯
func TestSessionRegistry_ComputeStatus(t *testing.T) {
	tests := []struct {
		name       string
		elapsed    time.Duration
		expected   SessionStatus
	}{
		{
			name:     "Less than ActiveThreshold",
			elapsed:  1 * time.Minute,
			expected: SessionStatusActive,
		},
		{
			name:     "Equal to ActiveThreshold",
			elapsed:  2 * time.Minute,
			expected: SessionStatusIdle,
		},
		{
			name:     "Between ActiveThreshold and IdleThreshold",
			elapsed:  15 * time.Minute,
			expected: SessionStatusIdle,
		},
		{
			name:     "Equal to IdleThreshold",
			elapsed:  30 * time.Minute,
			expected: SessionStatusCompleted,
		},
		{
			name:     "Greater than IdleThreshold",
			elapsed:  60 * time.Minute,
			expected: SessionStatusCompleted,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
			registry := NewSessionRegistry(func() time.Time { return baseTime })

			session := &SessionInfo{
				ID:           "test",
				LastEventAt:  baseTime,
				Status:       SessionStatusActive,
			}

			now := baseTime.Add(tc.elapsed)
			status := registry.computeStatus(session, now)

			if status != tc.expected {
				t.Errorf("expected %q, got %q", tc.expected, status)
			}
		})
	}
}
