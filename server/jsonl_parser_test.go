package main

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

// Table-driven tests for ParseLine

type parseLineTestCase struct {
	name              string
	line              string
	filePath          string
	expectError       bool
	expectEventCount  int
	expectType        string
	expectContentIdx  int
	expectIsLastCont  bool
	expectText        string
	expectToolName    string
	expectMessageID   string
}

func TestParseLineUserMessage(t *testing.T) {
	parser := NewJSONLParser()

	line := `{"type":"user","uuid":"msg-001","timestamp":"2026-03-25T10:00:00.000Z","sessionId":"session-abc","message":{"role":"user","content":"Hello, Claude"},"cwd":"/Users/test/project"}`
	filePath := "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl"

	events, err := parser.ParseLine(line, filePath)

	assert.NoError(t, err)
	assert.Len(t, events, 1)
	assert.Equal(t, string(EventTypeUser), events[0].Type)
	assert.Equal(t, NoContentIndex, events[0].ContentIndex)
	assert.False(t, events[0].IsLastContent)
	assert.Equal(t, "Hello, Claude", events[0].Content.Text)
	assert.Equal(t, "session-abc", events[0].SessionID)
	assert.Equal(t, "msg-001", events[0].MessageID)
}

func TestParseLineAssistantSingleText(t *testing.T) {
	parser := NewJSONLParser()

	line := `{"type":"assistant","uuid":"msg-002","timestamp":"2026-03-25T10:00:01.000Z","sessionId":"session-abc","message":{"role":"assistant","content":[{"type":"text","text":"Sure, I can help."}]},"cwd":"/Users/test/project"}`
	filePath := "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl"

	events, err := parser.ParseLine(line, filePath)

	assert.NoError(t, err)
	assert.Len(t, events, 1)
	assert.Equal(t, string(EventTypeAssistant), events[0].Type)
	assert.Equal(t, 0, events[0].ContentIndex)
	assert.True(t, events[0].IsLastContent)
	assert.Equal(t, "Sure, I can help.", events[0].Content.Text)
}

func TestParseLineAssistantContentArrayExpansion(t *testing.T) {
	parser := NewJSONLParser()

	line := `{"type":"assistant","uuid":"msg-003","timestamp":"2026-03-25T10:00:02.000Z","sessionId":"session-abc","message":{"role":"assistant","content":[{"type":"text","text":"Sure, I can help."},{"type":"tool_use","id":"tool-001","name":"web_search","input":{"query":"test"}},{"type":"text","text":"Let me search."}]},"cwd":"/Users/test/project"}`
	filePath := "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl"

	events, err := parser.ParseLine(line, filePath)

	assert.NoError(t, err)
	assert.Len(t, events, 3)

	// First event: text
	assert.Equal(t, string(EventTypeAssistant), events[0].Type)
	assert.Equal(t, 0, events[0].ContentIndex)
	assert.False(t, events[0].IsLastContent)
	assert.Equal(t, "Sure, I can help.", events[0].Content.Text)

	// Second event: tool_use
	assert.Equal(t, string(EventTypeToolUse), events[1].Type)
	assert.Equal(t, 1, events[1].ContentIndex)
	assert.False(t, events[1].IsLastContent)
	assert.Equal(t, "web_search", events[1].Content.ToolName)
	assert.Equal(t, "tool-001", events[1].Content.ToolUseID)

	// Third event: text
	assert.Equal(t, string(EventTypeAssistant), events[2].Type)
	assert.Equal(t, 2, events[2].ContentIndex)
	assert.True(t, events[2].IsLastContent)
	assert.Equal(t, "Let me search.", events[2].Content.Text)

	// All events share same MessageID
	assert.Equal(t, "msg-003", events[0].MessageID)
	assert.Equal(t, "msg-003", events[1].MessageID)
	assert.Equal(t, "msg-003", events[2].MessageID)
}

func TestParseLineToolResult(t *testing.T) {
	parser := NewJSONLParser()

	line := `{"type":"tool_result","uuid":"msg-004","timestamp":"2026-03-25T10:00:03.000Z","sessionId":"session-abc","message":{"role":"tool","content":{"tool_use_id":"tool-001","content":"Search results...","is_error":false}},"cwd":"/Users/test/project"}`
	filePath := "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl"

	events, err := parser.ParseLine(line, filePath)

	assert.NoError(t, err)
	assert.Len(t, events, 1)
	assert.Equal(t, string(EventTypeToolResult), events[0].Type)
	assert.Equal(t, NoContentIndex, events[0].ContentIndex)
	assert.False(t, events[0].IsLastContent)
	assert.Equal(t, "Search results...", events[0].Content.Output)
	assert.Equal(t, "tool-001", events[0].Content.ToolUseID)
	assert.False(t, events[0].Content.IsError)
}

func TestParseLineThinkingInContent(t *testing.T) {
	parser := NewJSONLParser()

	line := `{"type":"assistant","uuid":"msg-005","timestamp":"2026-03-25T10:00:04.000Z","sessionId":"session-abc","message":{"role":"assistant","content":[{"type":"thinking","thinking":"Let me analyze..."},{"type":"text","text":"Analysis complete."}]},"cwd":"/Users/test/project"}`
	filePath := "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl"

	events, err := parser.ParseLine(line, filePath)

	assert.NoError(t, err)
	assert.Len(t, events, 2)

	// First event: thinking (type is assistant because thinking is a subtype)
	assert.Equal(t, string(EventTypeAssistant), events[0].Type)
	assert.Equal(t, 0, events[0].ContentIndex)
	assert.False(t, events[0].IsLastContent)
	assert.Equal(t, "Let me analyze...", events[0].Content.Text) // Thinking text

	// Second event: text
	assert.Equal(t, string(EventTypeAssistant), events[1].Type)
	assert.Equal(t, 1, events[1].ContentIndex)
	assert.True(t, events[1].IsLastContent)
	assert.Equal(t, "Analysis complete.", events[1].Content.Text)
}

func TestParseLineIgnoreProgress(t *testing.T) {
	parser := NewJSONLParser()

	line := `{"type":"progress","uuid":"msg-006","timestamp":"2026-03-25T10:00:05.000Z","sessionId":"session-abc","data":{"status":"pending"}}`
	filePath := "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl"

	events, err := parser.ParseLine(line, filePath)

	// Auxiliary types return nil (no error)
	assert.NoError(t, err)
	assert.Nil(t, events)
}

func TestParseLineMalformedJSON(t *testing.T) {
	parser := NewJSONLParser()

	// Missing closing brace
	line := `{"type":"user","uuid":"msg-007","timestamp":"2026-03-25T10:00:06.000Z"...`
	filePath := "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl"

	events, err := parser.ParseLine(line, filePath)

	assert.Error(t, err)
	assert.Nil(t, events)
}

func TestParseLineEmptyLine(t *testing.T) {
	parser := NewJSONLParser()

	line := ""
	filePath := "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl"

	events, err := parser.ParseLine(line, filePath)

	// Empty line should return error (invalid JSON)
	assert.Error(t, err)
	assert.Nil(t, events)
}

func TestParseLineMissingUUID(t *testing.T) {
	parser := NewJSONLParser()

	// No uuid field
	line := `{"type":"user","timestamp":"2026-03-25T10:00:07.000Z","sessionId":"session-abc","message":{"role":"user","content":"Hello"},"cwd":"/Users/test/project"}`
	filePath := "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl"

	events, err := parser.ParseLine(line, filePath)

	// Should still parse, MessageID will be empty
	assert.NoError(t, err)
	assert.Len(t, events, 1)
	assert.Equal(t, "", events[0].MessageID)
}

func TestParseLineLargeContent(t *testing.T) {
	parser := NewJSONLParser()

	// Create 1MB of content
	largeText := string(make([]byte, 1024*1024))
	for i := 0; i < 1024*1024; i++ {
		largeText = largeText[:i] + "a" + largeText[i+1:]
	}

	line := `{"type":"tool_result","uuid":"msg-008","timestamp":"2026-03-25T10:00:08.000Z","sessionId":"session-abc","message":{"role":"tool","content":{"tool_use_id":"tool-001","content":"` + largeText + `","is_error":false}}}`
	filePath := "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl"

	events, err := parser.ParseLine(line, filePath)

	// Should handle large content without truncation
	assert.NoError(t, err)
	assert.Len(t, events, 1)
	assert.Equal(t, 1024*1024, len(events[0].Content.Output))
}

func TestParseLineTimestampParsing(t *testing.T) {
	parser := NewJSONLParser()

	line := `{"type":"user","uuid":"msg-009","timestamp":"2026-03-25T10:00:00.000Z","sessionId":"session-abc","message":{"role":"user","content":"Hello"},"cwd":"/Users/test/project"}`
	filePath := "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl"

	events, err := parser.ParseLine(line, filePath)

	assert.NoError(t, err)
	assert.Len(t, events, 1)

	// Verify timestamp parsing
	expectedTime := time.Date(2026, 3, 25, 10, 0, 0, 0, time.UTC)
	assert.Equal(t, expectedTime, events[0].Timestamp)
}

func TestParseLineEmptyContentArray(t *testing.T) {
	parser := NewJSONLParser()

	line := `{"type":"assistant","uuid":"msg-010","timestamp":"2026-03-25T10:00:09.000Z","sessionId":"session-abc","message":{"role":"assistant","content":[]},"cwd":"/Users/test/project"}`
	filePath := "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl"

	events, err := parser.ParseLine(line, filePath)

	// Empty array should produce no events
	assert.NoError(t, err)
	assert.Len(t, events, 0)
}

func TestParseLineAssistantAsString(t *testing.T) {
	parser := NewJSONLParser()

	// Assistant message with content as string (not array)
	line := `{"type":"assistant","uuid":"msg-011","timestamp":"2026-03-25T10:00:10.000Z","sessionId":"session-abc","message":{"role":"assistant","content":"This is a string response"},"cwd":"/Users/test/project"}`
	filePath := "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl"

	events, err := parser.ParseLine(line, filePath)

	assert.NoError(t, err)
	assert.Len(t, events, 1)
	assert.Equal(t, string(EventTypeAssistant), events[0].Type)
	assert.Equal(t, NoContentIndex, events[0].ContentIndex)
	assert.False(t, events[0].IsLastContent)
	assert.Equal(t, "This is a string response", events[0].Content.Text)
}

func TestParseLineUnknownType(t *testing.T) {
	parser := NewJSONLParser()

	line := `{"type":"unknown_future_type","uuid":"msg-012","timestamp":"2026-03-25T10:00:11.000Z","sessionId":"session-abc","message":{"role":"assistant","content":"Something"},"cwd":"/Users/test/project"}`
	filePath := "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl"

	events, err := parser.ParseLine(line, filePath)

	// Unknown non-auxiliary types return nil (no error)
	assert.NoError(t, err)
	assert.Nil(t, events)
}

func TestExtractProjectPathFromFile(t *testing.T) {
	tests := []struct {
		filePath     string
		expectedPath string
	}{
		{
			filePath:     "/Users/test/.claude/projects/-Users-test-project/session-abc.jsonl",
			expectedPath: "/Users/test/project",
		},
		{
			filePath:     "/home/user/.claude/projects/-home-user-my-project/session-xyz.jsonl",
			expectedPath: "/home/user/my-project",
		},
		{
			filePath:     "/root/.claude/projects/single-project/session-id.jsonl",
			expectedPath: "single/project",
		},
	}

	for _, tt := range tests {
		t.Run(tt.filePath, func(t *testing.T) {
			result := extractProjectPathFromFile(tt.filePath)
			assert.Equal(t, tt.expectedPath, result)
		})
	}
}

func TestExtractSessionIDFromPath(t *testing.T) {
	tests := []struct {
		filePath   string
		expectedID string
	}{
		{
			filePath:   "/Users/test/.claude/projects/-Users-test-project/session-abc123.jsonl",
			expectedID: "abc123",
		},
		{
			filePath:   "/Users/test/.claude/projects/-Users-test/session-f635f2ad-9e19-4fca-ba65-4f836ab7b737.jsonl",
			expectedID: "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
		},
		{
			filePath:   "/root/.claude/projects/test/summary-xyz.jsonl",
			expectedID: "xyz",
		},
	}

	for _, tt := range tests {
		t.Run(tt.filePath, func(t *testing.T) {
			result := extractSessionIDFromPath(tt.filePath)
			assert.Equal(t, tt.expectedID, result)
		})
	}
}
