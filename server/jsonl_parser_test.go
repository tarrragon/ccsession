package main

import (
	"testing"
	"time"
)

func TestParseLineUserMessage(t *testing.T) {
	line := []byte(`{
		"uuid": "msg-001",
		"type": "human",
		"timestamp": "2026-03-25T10:00:00Z",
		"message": {
			"role": "user",
			"content": "Hello, Claude"
		}
	}`)

	events, err := ParseLine(line, "sess-1", "/project")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(events) != 1 {
		t.Fatalf("expected 1 event, got %d", len(events))
	}

	evt := events[0]
	assertEqual(t, "SessionID", evt.SessionID, "sess-1")
	assertEqual(t, "ProjectPath", evt.ProjectPath, "/project")
	assertEqual(t, "Type", evt.Type, EventTypeUser)
	assertEqual(t, "MessageID", evt.MessageID, "msg-001")
	assertEqual(t, "Content.Text", evt.Content.Text, "Hello, Claude")
	assertEqualInt(t, "ContentIndex", evt.ContentIndex, ContentIndexNone)
	assertEqualBool(t, "IsLastContent", evt.IsLastContent, true)
}

func TestParseLineAssistantSingleText(t *testing.T) {
	line := []byte(`{
		"uuid": "msg-002",
		"type": "assistant",
		"timestamp": "2026-03-25T10:00:01Z",
		"message": {
			"role": "assistant",
			"content": [
				{"type": "text", "text": "Hi there!"}
			]
		}
	}`)

	events, err := ParseLine(line, "sess-1", "/project")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(events) != 1 {
		t.Fatalf("expected 1 event, got %d", len(events))
	}

	evt := events[0]
	assertEqual(t, "Type", evt.Type, EventTypeAssistant)
	assertEqual(t, "Content.Text", evt.Content.Text, "Hi there!")
	assertEqualInt(t, "ContentIndex", evt.ContentIndex, 0)
	assertEqualBool(t, "IsLastContent", evt.IsLastContent, true)
}

func TestParseLineAssistantMultipleContent(t *testing.T) {
	line := []byte(`{
		"uuid": "msg-003",
		"type": "assistant",
		"timestamp": "2026-03-25T10:00:02Z",
		"message": {
			"role": "assistant",
			"content": [
				{"type": "text", "text": "Let me check that."},
				{"type": "tool_use", "name": "Read", "id": "tu-1", "input": {"path": "/foo"}}
			]
		}
	}`)

	events, err := ParseLine(line, "sess-1", "/project")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(events) != 2 {
		t.Fatalf("expected 2 events, got %d", len(events))
	}

	// First block: text
	assertEqualInt(t, "events[0].ContentIndex", events[0].ContentIndex, 0)
	assertEqualBool(t, "events[0].IsLastContent", events[0].IsLastContent, false)
	assertEqual(t, "events[0].Type", events[0].Type, EventTypeAssistant)
	assertEqual(t, "events[0].Content.Text", events[0].Content.Text, "Let me check that.")

	// Second block: tool_use
	assertEqualInt(t, "events[1].ContentIndex", events[1].ContentIndex, 1)
	assertEqualBool(t, "events[1].IsLastContent", events[1].IsLastContent, true)
	assertEqual(t, "events[1].Type", events[1].Type, EventTypeToolUse)
	assertEqual(t, "events[1].Content.ToolName", events[1].Content.ToolName, "Read")
	assertEqual(t, "events[1].Content.ToolUseID", events[1].Content.ToolUseID, "tu-1")
	assertEqual(t, "events[1].ToolName", events[1].ToolName, "Read")
}

func TestParseLineToolResult(t *testing.T) {
	line := []byte(`{
		"uuid": "msg-004",
		"type": "tool_result",
		"timestamp": "2026-03-25T10:00:03Z",
		"message": {
			"role": "tool_result",
			"tool_use_id": "tu-1",
			"content": "file content here",
			"is_error": false
		}
	}`)

	events, err := ParseLine(line, "sess-1", "/project")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(events) != 1 {
		t.Fatalf("expected 1 event, got %d", len(events))
	}

	evt := events[0]
	assertEqual(t, "Type", evt.Type, EventTypeToolResult)
	assertEqual(t, "Content.ToolUseID", evt.Content.ToolUseID, "tu-1")
	assertEqual(t, "Content.Output", evt.Content.Output, "file content here")
	assertEqualBool(t, "Content.IsError", evt.Content.IsError, false)
	assertEqualInt(t, "ContentIndex", evt.ContentIndex, ContentIndexNone)
}

func TestParseLineToolResultWithError(t *testing.T) {
	line := []byte(`{
		"uuid": "msg-005",
		"type": "tool_result",
		"timestamp": "2026-03-25T10:00:04Z",
		"message": {
			"role": "tool_result",
			"tool_use_id": "tu-2",
			"content": "permission denied",
			"is_error": true
		}
	}`)

	events, err := ParseLine(line, "sess-1", "/project")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(events) != 1 {
		t.Fatalf("expected 1 event, got %d", len(events))
	}

	assertEqualBool(t, "Content.IsError", events[0].Content.IsError, true)
	assertEqual(t, "Content.Output", events[0].Content.Output, "permission denied")
}

func TestParseLineThinkingContent(t *testing.T) {
	line := []byte(`{
		"uuid": "msg-006",
		"type": "assistant",
		"timestamp": "2026-03-25T10:00:05Z",
		"message": {
			"role": "assistant",
			"content": [
				{"type": "thinking", "text": "Let me reason about this..."},
				{"type": "text", "text": "Here is my answer."}
			]
		}
	}`)

	events, err := ParseLine(line, "sess-1", "/project")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(events) != 2 {
		t.Fatalf("expected 2 events, got %d", len(events))
	}

	assertEqual(t, "events[0].Type", events[0].Type, EventTypeThinking)
	assertEqual(t, "events[0].Content.Text", events[0].Content.Text, "Let me reason about this...")
	assertEqualBool(t, "events[0].IsLastContent", events[0].IsLastContent, false)

	assertEqual(t, "events[1].Type", events[1].Type, EventTypeAssistant)
	assertEqualBool(t, "events[1].IsLastContent", events[1].IsLastContent, true)
}

func TestParseLineContentIndexCorrectness(t *testing.T) {
	line := []byte(`{
		"uuid": "msg-007",
		"type": "assistant",
		"timestamp": "2026-03-25T10:00:06Z",
		"message": {
			"role": "assistant",
			"content": [
				{"type": "text", "text": "first"},
				{"type": "tool_use", "name": "Bash", "id": "tu-3", "input": {"cmd": "ls"}},
				{"type": "text", "text": "last"}
			]
		}
	}`)

	events, err := ParseLine(line, "sess-1", "/project")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(events) != 3 {
		t.Fatalf("expected 3 events, got %d", len(events))
	}

	for i, evt := range events {
		assertEqualInt(t, "ContentIndex", evt.ContentIndex, i)
		expectedLast := i == len(events)-1
		assertEqualBool(t, "IsLastContent", evt.IsLastContent, expectedLast)
	}
}

func TestParseLineInvalidJSON(t *testing.T) {
	line := []byte(`{invalid json`)
	_, err := ParseLine(line, "sess-1", "/project")
	if err == nil {
		t.Fatal("expected error for invalid JSON, got nil")
	}
}

func TestParseLineUnknownEventType(t *testing.T) {
	line := []byte(`{
		"uuid": "msg-008",
		"type": "unknown",
		"timestamp": "2026-03-25T10:00:07Z",
		"message": {
			"role": "system_prompt",
			"content": "You are a helpful assistant."
		}
	}`)

	events, err := ParseLine(line, "sess-1", "/project")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if events != nil {
		t.Fatalf("expected nil events for unknown type, got %d", len(events))
	}
}

func TestParseLineTimestampParsing(t *testing.T) {
	line := []byte(`{
		"uuid": "msg-009",
		"type": "human",
		"timestamp": "2026-03-25T10:30:00.123456789Z",
		"message": {
			"role": "user",
			"content": "test"
		}
	}`)

	events, err := ParseLine(line, "sess-1", "/project")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expected := time.Date(2026, 3, 25, 10, 30, 0, 123456789, time.UTC)
	if !events[0].Timestamp.Equal(expected) {
		t.Errorf("timestamp mismatch: got %v, want %v", events[0].Timestamp, expected)
	}
}

func TestParseLineAssistantToolResultInContent(t *testing.T) {
	line := []byte(`{
		"uuid": "msg-010",
		"type": "assistant",
		"timestamp": "2026-03-25T10:00:08Z",
		"message": {
			"role": "assistant",
			"content": [
				{"type": "tool_result", "tool_use_id": "tu-5", "content": "output data", "is_error": true}
			]
		}
	}`)

	events, err := ParseLine(line, "sess-1", "/project")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(events) != 1 {
		t.Fatalf("expected 1 event, got %d", len(events))
	}

	evt := events[0]
	assertEqual(t, "Type", evt.Type, EventTypeToolResult)
	assertEqual(t, "Content.ToolUseID", evt.Content.ToolUseID, "tu-5")
	assertEqual(t, "Content.Output", evt.Content.Output, "output data")
	assertEqualBool(t, "Content.IsError", evt.Content.IsError, true)
}

func TestParseLineNonConversationTypes(t *testing.T) {
	// Non-conversation JSONL line types should be silently skipped (nil, nil).
	cases := []struct {
		name string
		line string
	}{
		{
			name: "progress",
			line: `{"type":"progress","data":{"percentage":50}}`,
		},
		{
			name: "system",
			line: `{"type":"system","content":"session started"}`,
		},
		{
			name: "file-history-snapshot",
			line: `{"type":"file-history-snapshot","snapshot":{"files":[]}}`,
		},
		{
			name: "queue-operation",
			line: `{"type":"queue-operation","operation":"enqueue"}`,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			events, err := ParseLine([]byte(tc.line), "sess-1", "/project")
			if err != nil {
				t.Fatalf("unexpected error for type %s: %v", tc.name, err)
			}
			if events != nil {
				t.Fatalf("expected nil events for type %s, got %d", tc.name, len(events))
			}
		})
	}
}

// --- Test helpers ---

func assertEqual(t *testing.T, field, got, want string) {
	t.Helper()
	if got != want {
		t.Errorf("%s: got %q, want %q", field, got, want)
	}
}

func assertEqualInt(t *testing.T, field string, got, want int) {
	t.Helper()
	if got != want {
		t.Errorf("%s: got %d, want %d", field, got, want)
	}
}

func assertEqualBool(t *testing.T, field string, got, want bool) {
	t.Helper()
	if got != want {
		t.Errorf("%s: got %v, want %v", field, got, want)
	}
}
