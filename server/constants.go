package main

// Session event types from JSONL records
const (
	EventTypeUser             = "user"
	EventTypeAssistant        = "assistant"
	EventTypeToolUse          = "tool_use"
	EventTypeToolResult       = "tool_result"
	EventTypeThinking         = "thinking"
	EventTypeSessionCompleted = "session_completed"
)

// ContentIndex sentinel value for non-assistant events
const ContentIndexNone = -1

// File watcher configuration
const (
	DefaultEventChannelSize = 100
	ProjectsDirName         = "projects"
	JSONLExtension          = ".jsonl"
)

// Main server configuration
const (
	DefaultPort              = "8765"
	DefaultClaudeHomeSubdir  = ".claude"
	SessionEventChBufferSize = 256
	HookEventChBufferSize    = 64
	DispatchChBufferSize     = 256
)
