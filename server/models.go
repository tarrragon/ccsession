package main

import (
	"encoding/json"
	"sync"
	"time"

	"github.com/fsnotify/fsnotify"
)

// SessionEvent is the unified event format for the backend.
// It represents a single minimal visible unit in a conversation.
type SessionEvent struct {
	SessionID     string       `json:"sessionId"`
	ProjectPath   string       `json:"projectPath"`
	Type          string       `json:"type"` // user, assistant, tool_use, tool_result, thinking, session_completed
	Timestamp     time.Time    `json:"timestamp"`
	MessageID     string       `json:"messageId"` // UUID from JSONL line
	ContentIndex  int          `json:"contentIndex"` // 0-based index in content array; -1 for non-assistant types
	IsLastContent bool         `json:"isLastContent"` // true for last sub-event in a message
	Content       EventContent `json:"content"`
	ToolName      string       `json:"toolName,omitempty"`
}

// EventContent contains event data, with fields varying by Type.
type EventContent struct {
	// For "user" or "assistant":
	Text string `json:"text,omitempty"`

	// For "tool_use":
	ToolName  string          `json:"toolName,omitempty"`
	ToolInput json.RawMessage `json:"toolInput,omitempty"`
	ToolUseID string          `json:"toolUseId,omitempty"`

	// For "tool_result":
	Output  string `json:"output,omitempty"`
	IsError bool   `json:"isError,omitempty"`

	// For "thinking":
	// Text field is used above
}

// FileWatcher monitors Claude Code's JSONL conversation files,
// detects new lines, and sends parsed events through eventCh.
type FileWatcher struct {
	claudeHome string
	watchers   map[string]*SessionFileReader // file path -> reader
	parser     *JSONLParser
	eventCh    chan SessionEvent
	watcher    *fsnotify.Watcher
	mu         sync.RWMutex // protects watchers map
}

// SessionFileReader tracks the read position of a single JSONL file,
// supporting offset-based incremental reading.
type SessionFileReader struct {
	filePath  string // absolute path
	offset    int64  // bytes read so far
	sessionID string // extracted from file path
}

// JSONLParser parses a line of JSONL text into zero or more SessionEvent.
type JSONLParser struct{}

// Internal JSONL structures for unmarshaling

// jsonlRow represents the raw structure of a JSONL line.
type jsonlRow struct {
	Type      string          `json:"type"`
	Message   json.RawMessage `json:"message"`
	UUID      string          `json:"uuid"`
	SessionID string          `json:"sessionId"`
	Timestamp string          `json:"timestamp"` // ISO 8601 UTC
	CWD       string          `json:"cwd"`
}

// rawMessage represents the message field structure.
type rawMessage struct {
	Role    string          `json:"role"`
	Content json.RawMessage `json:"content"` // string or array
}

// contentItem represents a single element in assistant content array.
type contentItem struct {
	Type      string          `json:"type"` // text, tool_use, thinking
	Text      string          `json:"text,omitempty"`
	Thinking  string          `json:"thinking,omitempty"`
	ID        string          `json:"id,omitempty"` // tool_use id
	Name      string          `json:"name,omitempty"` // tool_use name
	Input     json.RawMessage `json:"input,omitempty"` // tool_use input
	ToolUseID string          `json:"tool_use_id,omitempty"` // tool_result use id
	Content   json.RawMessage `json:"content,omitempty"` // tool_result output
	IsError   bool            `json:"is_error,omitempty"`
}
