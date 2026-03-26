package main

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/anthropics/ccsession-monitor/messages"
)

// NewJSONLParser creates a new JSONL parser instance.
func NewJSONLParser() *JSONLParser {
	return &JSONLParser{}
}

// ParseLine parses a single JSONL line and returns zero or more SessionEvent.
// filePath is used to extract ProjectPath (directory name with - -> /).
// Returns nil (no error) for auxiliary event types (progress, queue-operation, etc).
// Returns error only for JSON format errors or missing required fields.
func (p *JSONLParser) ParseLine(line string, filePath string) ([]SessionEvent, error) {
	logger := slog.Default()

	// Step 1: Deserialize raw line
	var row jsonlRow
	if err := json.Unmarshal([]byte(line), &row); err != nil {
		logger.Warn(messages.LogParseError,
			"layer", "jsonl_parser",
			"error", err,
		)
		return nil, fmt.Errorf("parse JSONL line: %w", err)
	}

	// Step 2: Initial validation - check for auxiliary types
	if KnownAuxiliaryTypes[row.Type] {
		return nil, nil // Silently ignore auxiliary types
	}

	// Step 3: Extract common fields
	timestamp, err := parseISO8601(row.Timestamp)
	if err != nil {
		logger.Warn(messages.LogInvalidTimestamp,
			"layer", "jsonl_parser",
			"timestamp", row.Timestamp,
			"error", err,
		)
		timestamp = time.Time{} // Use zero value
	}

	projectPath := extractProjectPathFromFile(filePath)

	// Step 4: Parse message field
	var msg rawMessage
	if err := json.Unmarshal(row.Message, &msg); err != nil {
		logger.Warn(messages.LogParseError,
			"layer", "jsonl_parser",
			"error", err,
		)
		return nil, fmt.Errorf("parse message field: %w", err)
	}

	// Step 5: Branch by type
	switch row.Type {
	case string(EventTypeAssistant):
		return p.expandAssistantContent(row, msg, row.SessionID, projectPath, timestamp)

	case string(EventTypeUser):
		var content string
		if err := json.Unmarshal(msg.Content, &content); err != nil {
			logger.Warn(messages.LogParseError,
				"layer", "jsonl_parser",
				"error", err,
			)
			return nil, fmt.Errorf("parse user content: %w", err)
		}

		event := SessionEvent{
			SessionID:    row.SessionID,
			ProjectPath:  projectPath,
			Type:         string(EventTypeUser),
			Timestamp:    timestamp,
			MessageID:    row.UUID,
			ContentIndex: NoContentIndex,
			IsLastContent: false,
			Content: EventContent{
				Text: content,
			},
		}
		return []SessionEvent{event}, nil

	case string(EventTypeToolResult):
		// Extract tool_result specific fields
		var toolResultData struct {
			ToolUseID string          `json:"tool_use_id"`
			Content   json.RawMessage `json:"content"`
			IsError   bool            `json:"is_error"`
		}
		if err := json.Unmarshal(msg.Content, &toolResultData); err != nil {
			logger.Warn(messages.LogParseError,
				"layer", "jsonl_parser",
				"error", err,
			)
			return nil, fmt.Errorf("parse tool_result content: %w", err)
		}

		var output string
		if err := json.Unmarshal(toolResultData.Content, &output); err != nil {
			// Content might not be plain string, try unmarshaling as raw
			output = string(toolResultData.Content)
		}

		event := SessionEvent{
			SessionID:    row.SessionID,
			ProjectPath:  projectPath,
			Type:         string(EventTypeToolResult),
			Timestamp:    timestamp,
			MessageID:    row.UUID,
			ContentIndex: NoContentIndex,
			IsLastContent: false,
			Content: EventContent{
				ToolUseID: toolResultData.ToolUseID,
				Output:    output,
				IsError:   toolResultData.IsError,
			},
		}
		return []SessionEvent{event}, nil

	default:
		// Unknown type
		logger.Debug(messages.LogUnknownEventType,
			"layer", "jsonl_parser",
			"type", row.Type,
		)
		return nil, nil
	}
}

// expandAssistantContent expands assistant message content array into multiple SessionEvents.
// Sets correct ContentIndex (0-based) and IsLastContent (true for last element only).
func (p *JSONLParser) expandAssistantContent(
	row jsonlRow,
	msg rawMessage,
	sessionID string,
	projectPath string,
	timestamp time.Time,
) []SessionEvent {
	logger := slog.Default()

	// Check content type
	// First, try to unmarshal as string
	var contentString string
	if err := json.Unmarshal(msg.Content, &contentString); err == nil {
		// Content is a string, not an array
		event := SessionEvent{
			SessionID:    sessionID,
			ProjectPath:  projectPath,
			Type:         string(EventTypeAssistant),
			Timestamp:    timestamp,
			MessageID:    row.UUID,
			ContentIndex: NoContentIndex,
			IsLastContent: false,
			Content: EventContent{
				Text: contentString,
			},
		}
		return []SessionEvent{event}
	}

	// Try to unmarshal as array
	var contentArray []contentItem
	if err := json.Unmarshal(msg.Content, &contentArray); err != nil {
		logger.Warn(messages.LogParseError,
			"layer", "jsonl_parser",
			"error", err,
		)
		return nil
	}

	// Empty array
	if len(contentArray) == 0 {
		return []SessionEvent{}
	}

	// Expand array into multiple events
	events := make([]SessionEvent, 0, len(contentArray))

	for i, item := range contentArray {
		// Determine event type based on item type
		eventType := item.Type
		if eventType == ContentTypeThinking {
			eventType = string(EventTypeAssistant)
		} else if !KnownContentTypes[item.Type] {
			logger.Warn(messages.LogUnknownContentType,
				"layer", "jsonl_parser",
				"type", item.Type,
			)
			eventType = string(EventTypeAssistant)
		}

		event := SessionEvent{
			SessionID:    sessionID,
			ProjectPath:  projectPath,
			Type:         eventType,
			Timestamp:    timestamp,
			MessageID:    row.UUID,
			ContentIndex: i,
			IsLastContent: (i == len(contentArray)-1),
			Content:       buildEventContent(item),
		}

		events = append(events, event)
	}

	return events
}

// buildEventContent creates EventContent from a contentItem.
func buildEventContent(item contentItem) EventContent {
	content := EventContent{}

	switch item.Type {
	case ContentTypeText:
		content.Text = item.Text

	case ContentTypeThinking:
		content.Text = item.Thinking

	case ContentTypeToolUse:
		content.ToolName = item.Name
		content.ToolInput = item.Input
		content.ToolUseID = item.ID
	}

	return content
}

// Helper functions

// parseISO8601 parses ISO 8601 formatted timestamp string to time.Time.
func parseISO8601(ts string) (time.Time, error) {
	// Expected format: 2026-03-25T10:00:00.000Z
	return time.Parse(time.RFC3339Nano, ts)
}

// extractProjectPathFromFile extracts project path from JSONL file path.
// Expected path: ~/.claude/projects/{encoded-path}/session-{id}.jsonl
// Converts encoded-path (- -> /) to original directory path.
func extractProjectPathFromFile(filePath string) string {
	// Get the directory name (parent of the JSONL file)
	dirName := filepath.Base(filepath.Dir(filePath))

	// Unescape: - -> /
	projectPath := strings.ReplaceAll(dirName, "-", "/")

	return projectPath
}

// extractSessionIDFromPath extracts session ID from JSONL file path.
// Expected format: session-{uuid}.jsonl
func extractSessionIDFromPath(filePath string) string {
	filename := filepath.Base(filePath)

	// Remove .jsonl extension
	name := strings.TrimSuffix(filename, JSONLFileExt)

	// Remove "session-" prefix if present
	sessionID := strings.TrimPrefix(name, "session-")

	return sessionID
}
