package main

import "time"

// SessionEvent represents a parsed JSONL conversation event.
// For assistant messages with multiple content blocks, each block
// becomes a separate SessionEvent with its own ContentIndex.
type SessionEvent struct {
	SessionID     string       `json:"sessionId"`
	ProjectPath   string       `json:"projectPath"`
	Type          string       `json:"type"`
	Timestamp     time.Time    `json:"timestamp"`
	MessageID     string       `json:"messageId"`
	ContentIndex  int          `json:"contentIndex"`
	IsLastContent bool         `json:"isLastContent"`
	Content       EventContent `json:"content"`
	ToolName      string       `json:"toolName,omitempty"`
}

// EventContent holds the payload for each content block type.
// Only the fields relevant to the block type will be populated.
type EventContent struct {
	Text      string `json:"text,omitempty"`
	ToolName  string `json:"toolName,omitempty"`
	ToolInput any    `json:"toolInput,omitempty"`
	ToolUseID string `json:"toolUseId,omitempty"`
	Output    string `json:"output,omitempty"`
	IsError   bool   `json:"isError,omitempty"`
}
