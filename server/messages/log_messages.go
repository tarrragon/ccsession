package messages

// File Watcher layer log messages
const (
	LogNewSessionFile    = "new session file detected"
	LogSessionFileRead   = "reading new appended lines"
	LogSessionFileGone   = "session file deleted"
	LogIncompleteJSON    = "incomplete JSON line, will retry"
	LogFileReadError     = "file read error"
	LogFileScanStart     = "scanning existing JSONL files"
	LogFileScanComplete  = "file scan completed"
	LogAddFileToWatcher  = "adding file to watcher"
	LogRemoveFileWatcher = "removing file from watcher"
	LogFilePermissionDenied = "permission denied reading file"
	LogFileTruncated     = "file truncated, resetting offset"
)

// JSONL Parser layer log messages
const (
	LogUnknownField       = "unknown JSONL field detected"
	LogUnknownEventType   = "unknown event type detected"
	LogUnknownContentType = "unknown content element type detected"
	LogParseSuccess       = "JSONL line parsed successfully"
	LogParseError         = "JSON parse failed"
	LogFormatChangeHint   = "Claude format may have changed"
	LogEmptyLine          = "empty line encountered"
	LogMissingField       = "missing required field in JSONL"
	LogInvalidTimestamp   = "invalid timestamp format"
)

// WebSocket layer log messages (placeholder for future)
const (
	LogClientConnected    = "WebSocket client connected"
	LogClientDisconnected = "WebSocket client disconnected"
	LogBroadcastFailed    = "broadcast to client failed"
	LogUnknownAction      = "unknown client action"
)

// Shared utility messages
const (
	LogContextError = "context cancelled or cancelled with error"
)
