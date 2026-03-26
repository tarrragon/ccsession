package main

import "time"

// Session event types
type EventType string

const (
	EventTypeUser             EventType = "user"
	EventTypeAssistant        EventType = "assistant"
	EventTypeToolResult       EventType = "tool_result"
	EventTypeThinking         EventType = "thinking"
	EventTypeSessionCompleted EventType = "session_completed"
)

// Content item types (within assistant content array)
const (
	ContentTypeText     = "text"
	ContentTypeToolUse  = "tool_use"
	ContentTypeThinking = "thinking"
)

// File watching constants
const (
	SessionProjectsDir = "projects"
	JSONLFileExt       = ".jsonl"
)

// Channel and event configuration
const (
	DefaultEventChannelBuffer = 100
)

// Timeout and retry configuration
const (
	FileReadTimeout = 5 * time.Second
	MaxRetries      = 3
)

// Special marker values
const (
	NoContentIndex = -1
)

// Known auxiliary event types (should be ignored)
var KnownAuxiliaryTypes = map[string]bool{
	"progress":               true,
	"queue-operation":        true,
	"file-history-snapshot": true,
}

// Known content element types
var KnownContentTypes = map[string]bool{
	ContentTypeText:     true,
	ContentTypeToolUse:  true,
	ContentTypeThinking: true,
}
