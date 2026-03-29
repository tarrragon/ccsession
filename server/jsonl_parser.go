package main

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"time"
)

// Parser log messages
const (
	LogParseLineCalled   = "parsing JSONL line"
	LogContentBlock      = "processing content block"
	LogUnknownRoleType   = "unknown role type in JSONL line"
	LogUnknownContentType = "unknown content type in assistant block"
	LogInvalidTimestamp   = "invalid timestamp format"
)

// Parser hint messages
const (
	HintUnknownRole    = "expected user, assistant, or tool_result"
	HintUnknownContent = "expected text, tool_use, thinking, or tool_result"
)

// conversationLineTypes defines top-level JSONL type values that contain
// a message field worth parsing. Other types (progress, system, etc.)
// are silently skipped.
var conversationLineTypes = map[string]bool{
	EventTypeUser:       true, // "user" — spec.md 定義的正式 type
	"human":             true, // 向後相容（舊版 JSONL）
	"ai":                true, // 向後相容（舊版 JSONL）
	EventTypeAssistant:  true, // "assistant"
	EventTypeToolResult: true, // "tool_result"
}

// JSONL raw field keys
const (
	fieldUUID      = "uuid"
	fieldType      = "type"
	fieldTimestamp  = "timestamp"
	fieldMessage   = "message"
	fieldContent   = "content"
	fieldRole      = "role"
	fieldText      = "text"
	fieldName      = "name"
	fieldInput     = "input"
	fieldID        = "id"
	fieldToolUseID = "tool_use_id"
	fieldIsError   = "is_error"
)

// ParseLine parses a single JSONL line into one or more SessionEvents.
// Assistant messages with multiple content blocks produce multiple events.
// Non-assistant messages (user, tool_result) produce a single event.
func ParseLine(line []byte, sessionID string, projectPath string) ([]SessionEvent, error) {
	var raw map[string]any
	if err := json.Unmarshal(line, &raw); err != nil {
		return nil, fmt.Errorf("invalid JSON: %w", err)
	}

	lineType, _ := raw[fieldType].(string)
	if !conversationLineTypes[lineType] {
		return nil, nil
	}

	messageID, _ := raw[fieldUUID].(string)
	ts := parseTimestamp(raw[fieldTimestamp])

	msg, ok := raw[fieldMessage].(map[string]any)
	if !ok {
		return nil, fmt.Errorf("missing or invalid 'message' field: %w",
			fmt.Errorf("expected object"))
	}

	role, _ := msg[fieldRole].(string)

	switch role {
	case EventTypeAssistant:
		return parseAssistantMessage(msg, sessionID, projectPath, messageID, ts)
	case EventTypeUser:
		return parseSingleEvent(sessionID, projectPath, EventTypeUser, messageID, ts, msg)
	case EventTypeToolResult:
		return parseToolResultMessage(msg, sessionID, projectPath, messageID, ts)
	default:
		slog.Warn(LogUnknownRoleType,
			"layer", "jsonl_parser",
			"role", role,
			"hint", HintUnknownRole)
		return nil, nil
	}
}

// parseTimestamp attempts to parse an ISO 8601 timestamp string.
func parseTimestamp(v any) time.Time {
	s, ok := v.(string)
	if !ok {
		return time.Time{}
	}
	t, err := time.Parse(time.RFC3339Nano, s)
	if err != nil {
		slog.Warn(LogInvalidTimestamp,
			"layer", "jsonl_parser",
			"value", s)
		return time.Time{}
	}
	return t
}

// parseAssistantMessage handles assistant role messages, producing one
// SessionEvent per content block in the content array.
func parseAssistantMessage(msg map[string]any, sessionID, projectPath, messageID string, ts time.Time) ([]SessionEvent, error) {
	contentArr, ok := msg[fieldContent].([]any)
	if !ok {
		// Single text content fallback
		text, _ := msg[fieldContent].(string)
		evt := SessionEvent{
			SessionID:     sessionID,
			ProjectPath:   projectPath,
			Type:          EventTypeAssistant,
			Timestamp:     ts,
			MessageID:     messageID,
			ContentIndex:  0,
			IsLastContent: true,
			Content:       EventContent{Text: text},
		}
		return []SessionEvent{evt}, nil
	}

	var events []SessionEvent
	total := len(contentArr)
	for i, item := range contentArr {
		block, ok := item.(map[string]any)
		if !ok {
			continue
		}
		blockType, _ := block[fieldType].(string)
		isLast := i == total-1

		evt := SessionEvent{
			SessionID:     sessionID,
			ProjectPath:   projectPath,
			Timestamp:     ts,
			MessageID:     messageID,
			ContentIndex:  i,
			IsLastContent: isLast,
		}

		switch blockType {
		case fieldText:
			evt.Type = EventTypeAssistant
			evt.Content.Text, _ = block[fieldText].(string)

		case EventTypeToolUse:
			evt.Type = EventTypeToolUse
			evt.Content.ToolName, _ = block[fieldName].(string)
			evt.Content.ToolInput = serializeToolInput(block[fieldInput])
			evt.Content.ToolUseID, _ = block[fieldID].(string)
			evt.ToolName = evt.Content.ToolName

		case EventTypeThinking:
			evt.Type = EventTypeThinking
			evt.Content.Text, _ = block[fieldText].(string)

		case EventTypeToolResult:
			evt.Type = EventTypeToolResult
			evt.Content.ToolUseID, _ = block[fieldToolUseID].(string)
			evt.Content.Output = extractToolResultOutput(block)
			if isErr, ok := block[fieldIsError].(bool); ok {
				evt.Content.IsError = isErr
			}

		default:
			slog.Warn(LogUnknownContentType,
				"layer", "jsonl_parser",
				"contentType", blockType,
				"hint", HintUnknownContent)
			continue
		}

		slog.Debug(LogContentBlock,
			"layer", "jsonl_parser",
			"type", evt.Type,
			"index", i)
		events = append(events, evt)
	}
	return events, nil
}

// parseSingleEvent creates a single SessionEvent for user messages.
func parseSingleEvent(sessionID, projectPath, eventType, messageID string, ts time.Time, msg map[string]any) ([]SessionEvent, error) {
	text := extractMessageText(msg)
	evt := SessionEvent{
		SessionID:     sessionID,
		ProjectPath:   projectPath,
		Type:          eventType,
		Timestamp:     ts,
		MessageID:     messageID,
		ContentIndex:  ContentIndexNone,
		IsLastContent: true,
		Content:       EventContent{Text: text},
	}
	return []SessionEvent{evt}, nil
}

// parseToolResultMessage handles top-level tool_result role messages.
func parseToolResultMessage(msg map[string]any, sessionID, projectPath, messageID string, ts time.Time) ([]SessionEvent, error) {
	evt := SessionEvent{
		SessionID:     sessionID,
		ProjectPath:   projectPath,
		Type:          EventTypeToolResult,
		Timestamp:     ts,
		MessageID:     messageID,
		ContentIndex:  ContentIndexNone,
		IsLastContent: true,
	}
	evt.Content.ToolUseID, _ = msg[fieldToolUseID].(string)
	evt.Content.Output = extractToolResultOutput(msg)
	if isErr, ok := msg[fieldIsError].(bool); ok {
		evt.Content.IsError = isErr
	}
	return []SessionEvent{evt}, nil
}

// extractMessageText pulls text from the message content field.
// Handles both string content and array-of-blocks content.
func extractMessageText(msg map[string]any) string {
	if s, ok := msg[fieldContent].(string); ok {
		return s
	}
	if arr, ok := msg[fieldContent].([]any); ok && len(arr) > 0 {
		if block, ok := arr[0].(map[string]any); ok {
			if text, ok := block[fieldText].(string); ok {
				return text
			}
		}
	}
	return ""
}

// serializeToolInput converts a raw tool input value to a JSON string,
// truncating to MaxToolInputLength to prevent memory bloat from large inputs.
func serializeToolInput(v any) string {
	if v == nil {
		return ""
	}
	b, err := json.Marshal(v)
	if err != nil {
		return ""
	}
	s := string(b)
	if len(s) > MaxToolInputLength {
		s = s[:MaxToolInputLength]
	}
	return s
}

// extractToolResultOutput extracts the output string from a tool_result block.
// The content field may be a string or an array of content blocks.
func extractToolResultOutput(block map[string]any) string {
	if s, ok := block[fieldContent].(string); ok {
		return truncateToolOutput(s)
	}
	if arr, ok := block[fieldContent].([]any); ok && len(arr) > 0 {
		if inner, ok := arr[0].(map[string]any); ok {
			if text, ok := inner[fieldText].(string); ok {
				return truncateToolOutput(text)
			}
		}
	}
	return ""
}

// truncateToolOutput truncates tool result output to MaxToolOutputLength.
func truncateToolOutput(output string) string {
	if len(output) > MaxToolOutputLength {
		return output[:MaxToolOutputLength] + TruncationSuffix
	}
	return output
}
