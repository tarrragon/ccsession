package main

import "time"

// Session event types from JSONL records
const (
	EventTypeUser             = "user"
	EventTypeAssistant        = "assistant"
	EventTypeToolUse          = "tool_use"
	EventTypeToolResult       = "tool_result"
	EventTypeThinking         = "thinking"
	EventTypeSessionCompleted  = "session_completed"
	EventTypeSessionDiscovered = "session_discovered"
)

// ContentIndex sentinel value for non-assistant events
const ContentIndexNone = -1

// File watcher configuration
const (
	DefaultEventChannelSize = 100
	ProjectsDirName         = "projects"
	JSONLExtension          = ".jsonl"
	SubagentsDirName        = "subagents"
	AddFileRetryDelay       = 50 * time.Millisecond
)

// Parser limits
const (
	// MaxToolInputLength is the truncation point (in bytes) for serialized tool input.
	// Inputs exceeding this limit are truncated and TruncationSuffix is appended.
	// Final length may be up to MaxToolInputLength + len(TruncationSuffix).
	MaxToolInputLength = 2000

	// MaxToolOutputLength is the truncation point (in bytes) for tool result output.
	// Outputs exceeding this limit are truncated and TruncationSuffix is appended.
	// Final length may be up to MaxToolOutputLength + len(TruncationSuffix).
	MaxToolOutputLength = 10000
)

// TruncationSuffix is appended when content exceeds length limits.
const TruncationSuffix = "...[truncated]"

// Runtime configuration
const (
	// MemoryLimitBytes is the soft memory limit for the Go runtime GC.
	// 需求：[0.4.0-W2-003] 限制記憶體使用，防止長時間運行時記憶體無限增長。
	MemoryLimitBytes = 512 * 1024 * 1024 // 512MB
)

// Main server configuration
const (
	DefaultPort              = "8765"
	DefaultClaudeHomeSubdir  = ".claude"
	SessionEventChBufferSize = 256
	HookEventChBufferSize    = 64
	DispatchChBufferSize     = 256
)
