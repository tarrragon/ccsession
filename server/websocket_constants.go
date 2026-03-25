package main

import "time"

// Client action names (Client → Server)
const (
	ActionSubscribeSession   = "subscribe_session"
	ActionUnsubscribeSession = "unsubscribe_session"
	ActionGetSessionList     = "get_session_list"
	ActionGetSessionHistory  = "get_session_history"
)

// Server message type names (Server → Client)
const (
	MsgTypeSessionList         = "session_list"
	MsgTypeSessionEvent        = "session_event"
	MsgTypeSessionStatusChange = "session_status_change"
	MsgTypeSessionHistory      = "session_history"
	MsgTypeError               = "error"
)

// Error codes (Client-visible, i18n by client)
const (
	ErrCodeInvalidJSON      = "INVALID_JSON"
	ErrCodeInvalidAction    = "INVALID_ACTION"
	ErrCodeInvalidParams    = "INVALID_PARAMS"
	ErrCodeSessionNotFound  = "SESSION_NOT_FOUND"
	ErrCodeInternalError    = "INTERNAL_ERROR"
)

// WebSocket server configuration
const (
	// ClientSendBufferSize is the buffered channel size for each client's outgoing messages.
	ClientSendBufferSize = 256

	// MaxMessageSize is the maximum allowed size (bytes) for incoming WebSocket messages.
	MaxMessageSize = 4096

	// WriteWaitTimeout is the deadline for writing a message to the WebSocket connection.
	WriteWaitTimeout = 10 * time.Second

	// PongWaitTimeout is the deadline for receiving a pong from the client.
	PongWaitTimeout = 35 * time.Second

	// HeartbeatInterval is the interval between ping messages sent to the client.
	HeartbeatInterval = 30 * time.Second

	// DefaultHistoryLimit is the default number of history events returned.
	DefaultHistoryLimit = 100

	// MaxHistoryLimit is the maximum number of history events returned.
	MaxHistoryLimit = 1000
)
