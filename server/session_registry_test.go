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
	t.Run("with TranscriptPath registers subagent session", func(t *testing.T) {
		baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
		registry := NewSessionRegistry(func() time.Time { return baseTime })

		// 先建立主 session
		registry.UpsertFromSessionEvent(SessionEvent{
			SessionID: "main-sess",
			Type:      EventTypeUser,
			Timestamp: baseTime,
		})

		// 收到 SubagentStop Hook（含 TranscriptPath）
		registry.UpsertFromHookEvent(HookEvent{
			Type:           HookEventSubagentStop,
			SessionID:      "main-sess",
			AgentID:        "agent-1",
			AgentType:      "rosemary",
			LastMessage:    "Task completed",
			TranscriptPath: "/home/user/.claude/projects/test/sub-uuid-abc.jsonl",
		})

		// 主 session 不應被標記為 completed
		mainSession, _ := registry.Get("main-sess")
		if mainSession.Status == SessionStatusCompleted {
			t.Error("main session should NOT be completed by SubagentStop")
		}

		// subagent session 應被建立且為 completed
		subSession, ok := registry.Get("sub-uuid-abc")
		if !ok {
			t.Fatal("subagent session not found in registry")
		}
		if subSession.Status != SessionStatusCompleted {
			t.Errorf("expected subagent Status=%q, got %q", SessionStatusCompleted, subSession.Status)
		}
		if subSession.LastMessage != "Task completed" {
			t.Errorf("expected LastMessage=%q, got %q", "Task completed", subSession.LastMessage)
		}
		if subSession.AgentID != "agent-1" {
			t.Errorf("expected AgentID=%q, got %q", "agent-1", subSession.AgentID)
		}
	})

	t.Run("without TranscriptPath updates main session only", func(t *testing.T) {
		baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
		registry := NewSessionRegistry(func() time.Time { return baseTime })

		registry.UpsertFromSessionEvent(SessionEvent{
			SessionID: "main-sess-2",
			Type:      EventTypeUser,
			Timestamp: baseTime,
		})

		registry.UpsertFromHookEvent(HookEvent{
			Type:        HookEventSubagentStop,
			SessionID:   "main-sess-2",
			LastMessage: "done",
		})

		// 主 session 不應被標記為 completed
		session, _ := registry.Get("main-sess-2")
		if session.Status == SessionStatusCompleted {
			t.Error("main session should NOT be completed without TranscriptPath")
		}
	})
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

// TestSessionRegistry_SummaryOverwriteOnSecondUser 驗證第二個 user 事件覆蓋 Summary (A-1)
func TestSessionRegistry_SummaryOverwriteOnSecondUser(t *testing.T) {
	baseTime := time.Date(2026, 3, 27, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: "overwrite-1",
		Type:      EventTypeUser,
		Timestamp: baseTime,
		Content:   EventContent{Text: "First message"},
	})

	session, _ := registry.Get("overwrite-1")
	if session.Summary != "First message" {
		t.Errorf("expected Summary=%q, got %q", "First message", session.Summary)
	}
	if session.EventCount != 1 {
		t.Errorf("expected EventCount=1, got %d", session.EventCount)
	}

	baseTime = baseTime.Add(time.Second)
	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: "overwrite-1",
		Type:      EventTypeUser,
		Timestamp: baseTime,
		Content:   EventContent{Text: "Second message"},
	})

	session, _ = registry.Get("overwrite-1")
	if session.Summary != "Second message" {
		t.Errorf("expected Summary=%q, got %q", "Second message", session.Summary)
	}
	if session.EventCount != 2 {
		t.Errorf("expected EventCount=2, got %d", session.EventCount)
	}
}

// TestSessionRegistry_SummaryOverwriteMultipleUsers 驗證連續多次 user 事件覆蓋 (A-2)
func TestSessionRegistry_SummaryOverwriteMultipleUsers(t *testing.T) {
	baseTime := time.Date(2026, 3, 27, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	messages := []string{"msg-1", "msg-2", "msg-3"}
	for _, msg := range messages {
		baseTime = baseTime.Add(time.Second)
		registry.UpsertFromSessionEvent(SessionEvent{
			SessionID: "multi-1",
			Type:      EventTypeUser,
			Timestamp: baseTime,
			Content:   EventContent{Text: msg},
		})
		session, _ := registry.Get("multi-1")
		if session.Summary != msg {
			t.Errorf("after sending %q, expected Summary=%q, got %q", msg, msg, session.Summary)
		}
	}

	session, _ := registry.Get("multi-1")
	if session.Summary != "msg-3" {
		t.Errorf("expected final Summary=%q, got %q", "msg-3", session.Summary)
	}
}

// TestSessionRegistry_AssistantDoesNotUpdateSummary 驗證 assistant 事件不更新 Summary (A-3)
func TestSessionRegistry_AssistantDoesNotUpdateSummary(t *testing.T) {
	baseTime := time.Date(2026, 3, 27, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: "assist-1",
		Type:      EventTypeUser,
		Timestamp: baseTime,
		Content:   EventContent{Text: "使用者提問"},
	})

	session, _ := registry.Get("assist-1")
	if session.Summary != "使用者提問" {
		t.Errorf("expected Summary=%q, got %q", "使用者提問", session.Summary)
	}

	baseTime = baseTime.Add(time.Second)
	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: "assist-1",
		Type:      EventTypeAssistant,
		Timestamp: baseTime,
		Content:   EventContent{Text: "AI 回覆"},
	})

	session, _ = registry.Get("assist-1")
	if session.Summary != "使用者提問" {
		t.Errorf("expected Summary unchanged=%q, got %q", "使用者提問", session.Summary)
	}
}

// TestSessionRegistry_SummaryTracksOnlyUserInMixedEvents 驗證交錯事件只追蹤 user (A-4)
func TestSessionRegistry_SummaryTracksOnlyUserInMixedEvents(t *testing.T) {
	baseTime := time.Date(2026, 3, 27, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	events := []struct {
		eventType string
		text      string
	}{
		{EventTypeUser, "Q1"},
		{EventTypeAssistant, "A1"},
		{EventTypeUser, "Q2"},
		{EventTypeAssistant, "A2"},
	}

	for _, e := range events {
		baseTime = baseTime.Add(time.Second)
		registry.UpsertFromSessionEvent(SessionEvent{
			SessionID: "mixed-1",
			Type:      e.eventType,
			Timestamp: baseTime,
			Content:   EventContent{Text: e.text},
		})
	}

	session, _ := registry.Get("mixed-1")
	if session.Summary != "Q2" {
		t.Errorf("expected Summary=%q, got %q", "Q2", session.Summary)
	}
}

// TestSessionRegistry_EmptyUserTextOverwritesSummary 驗證空 Content.Text 覆蓋 Summary (A-5)
func TestSessionRegistry_EmptyUserTextOverwritesSummary(t *testing.T) {
	baseTime := time.Date(2026, 3, 27, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: "empty-1",
		Type:      EventTypeUser,
		Timestamp: baseTime,
		Content:   EventContent{Text: "有內容的訊息"},
	})

	baseTime = baseTime.Add(time.Second)
	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: "empty-1",
		Type:      EventTypeUser,
		Timestamp: baseTime,
		Content:   EventContent{Text: ""},
	})

	session, _ := registry.Get("empty-1")
	if session.Summary != "" {
		t.Errorf("expected empty Summary, got %q", session.Summary)
	}
}

// TestSessionRegistry_LongSummaryTruncated 驗證長 Summary 截斷 (A-6)
func TestSessionRegistry_LongSummaryTruncated(t *testing.T) {
	baseTime := time.Date(2026, 3, 27, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	// 建立超過 MaxSummaryLength 的文本
	longText := ""
	for i := 0; i < MaxSummaryLength+20; i++ {
		longText += "a"
	}

	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: "long-1",
		Type:      EventTypeUser,
		Timestamp: baseTime,
		Content:   EventContent{Text: longText},
	})

	session, _ := registry.Get("long-1")
	if len([]rune(session.Summary)) > MaxSummaryLength {
		t.Errorf("expected Summary rune length <= %d, got %d", MaxSummaryLength, len([]rune(session.Summary)))
	}
}

// TestSessionRegistry_SecondUserLongTextAlsoTruncated 驗證第二次 user 長文本也截斷 (A-7)
func TestSessionRegistry_SecondUserLongTextAlsoTruncated(t *testing.T) {
	baseTime := time.Date(2026, 3, 27, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: "long2-1",
		Type:      EventTypeUser,
		Timestamp: baseTime,
		Content:   EventContent{Text: "Short first"},
	})

	session, _ := registry.Get("long2-1")
	if session.Summary != "Short first" {
		t.Errorf("expected Summary=%q, got %q", "Short first", session.Summary)
	}

	// 第二次 user 事件送長文本
	longText := ""
	for i := 0; i < MaxSummaryLength+30; i++ {
		longText += "b"
	}

	baseTime = baseTime.Add(time.Second)
	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: "long2-1",
		Type:      EventTypeUser,
		Timestamp: baseTime,
		Content:   EventContent{Text: longText},
	})

	session, _ = registry.Get("long2-1")
	summaryRunes := []rune(session.Summary)
	if len(summaryRunes) > MaxSummaryLength {
		t.Errorf("expected Summary rune length <= %d, got %d", MaxSummaryLength, len(summaryRunes))
	}
	// 確認是新長文本的前 MaxSummaryLength 字元
	expectedPrefix := string([]rune(longText)[:MaxSummaryLength])
	if session.Summary != expectedPrefix {
		t.Errorf("expected Summary to be first %d chars of long text, got %q", MaxSummaryLength, session.Summary)
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

	// 透過 session_completed 事件設為 completed
	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: "completed-guard-1",
		Type:      EventTypeSessionCompleted,
		Timestamp: baseTime,
	})

	session, _ := registry.Get("completed-guard-1")
	if session.Status != SessionStatusCompleted {
		t.Fatalf("expected completed after session_completed, got %q", session.Status)
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

	// 透過 session_completed 事件設為 completed
	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: "completed-guard-2",
		Type:      EventTypeSessionCompleted,
		Timestamp: baseTime,
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

// TestAppendEvent_EvictsOldestWhenExceedsMax 驗證 AppendEvent 超過上限時淘汰最早事件
func TestAppendEvent_EvictsOldestWhenExceedsMax(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	registry := NewSessionRegistry(func() time.Time { return baseTime })

	sessionID := "eviction-test"
	// 先建立 session
	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: sessionID,
		Type:      EventTypeUser,
		Timestamp: baseTime,
	})

	// 填入 MaxEventsPerSession + 10 個事件
	totalEvents := MaxEventsPerSession + 10
	for i := 0; i < totalEvents; i++ {
		registry.AppendEvent(sessionID, SessionEvent{
			SessionID: sessionID,
			Type:      EventTypeUser,
			Timestamp: baseTime.Add(time.Duration(i) * time.Second),
			Content:   EventContent{Text: "msg"},
		})
	}

	// 驗證歷史長度不超過上限
	events, _, err := registry.GetHistory(sessionID, MaxEventsPerSession+100, time.Time{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(events) != MaxEventsPerSession {
		t.Errorf("expected %d events, got %d", MaxEventsPerSession, len(events))
	}

	// 驗證保留的是最新的事件（最早被淘汰的是 index 0~9）
	firstKept := events[0]
	expectedFirstTimestamp := baseTime.Add(time.Duration(totalEvents-MaxEventsPerSession) * time.Second)
	if !firstKept.Timestamp.Equal(expectedFirstTimestamp) {
		t.Errorf("expected oldest kept event timestamp=%v, got %v", expectedFirstTimestamp, firstKept.Timestamp)
	}
}

// TestScanAndUpdateStatus_TrimsCompletedSessionHistory 驗證 completed session 歷史裁剪
func TestScanAndUpdateStatus_TrimsCompletedSessionHistory(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	currentTime := baseTime
	registry := NewSessionRegistry(func() time.Time { return currentTime })

	sessionID := "trim-test"
	// 建立 active session
	registry.UpsertFromSessionEvent(SessionEvent{
		SessionID: sessionID,
		Type:      EventTypeUser,
		Timestamp: baseTime,
	})

	// 填入 200 個事件（遠超 CompletedSessionMaxEvents）
	for i := 0; i < 200; i++ {
		registry.AppendEvent(sessionID, SessionEvent{
			SessionID: sessionID,
			Type:      EventTypeUser,
			Timestamp: baseTime.Add(time.Duration(i) * time.Second),
			Content:   EventContent{Text: "msg"},
		})
	}

	// 推進時間超過 IdleThreshold，觸發 completed 轉換
	currentTime = baseTime.Add(IdleThreshold + time.Minute)
	updated := registry.ScanAndUpdateStatus()

	// 驗證狀態已轉為 completed
	if len(updated) != 1 || updated[0].Status != SessionStatusCompleted {
		t.Fatalf("expected session to become completed, got %v", updated)
	}

	// 驗證歷史已裁剪至 CompletedSessionMaxEvents
	events, _, err := registry.GetHistory(sessionID, 1000, time.Time{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(events) != CompletedSessionMaxEvents {
		t.Errorf("expected %d events after trim, got %d", CompletedSessionMaxEvents, len(events))
	}
}
