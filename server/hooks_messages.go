package main

// Log messages for hooks handler
const (
	LogHookEventReceived    = "hook event received"
	LogUnknownEventType     = "unknown hook event type"
	LogChannelFull          = "hook event channel full, dropping event"
	LogFailedToParseEvent   = "failed to parse hook event"
	LogMissingRequiredField = "missing required field"
	LogFailedToReadBody     = "failed to read request body"
)

// Hint messages for warnings
const (
	HintUnknownEventType = "may be a new event type from newer Claude Code version"
)

// Error response messages
const (
	ErrMissingField = "missing required field"
)
