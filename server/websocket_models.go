package main

import (
	"sync"
	"sync/atomic"
	"time"

	"github.com/gorilla/websocket"
)

// ClientMessage represents a message sent from Client to Server.
type ClientMessage struct {
	Action    string `json:"action"`
	SessionID string `json:"sessionId,omitempty"`
	Limit     int    `json:"limit,omitempty"`
	Before    string `json:"before,omitempty"`
}

// ServerMessage represents a message sent from Server to Client.
type ServerMessage struct {
	Type string      `json:"type"`
	Data any `json:"data"`
}

// SessionListData is the payload for session_list messages.
type SessionListData struct {
	Sessions []*SessionInfo `json:"sessions"`
}

// SessionEventData is the payload for session_event messages.
type SessionEventData struct {
	SessionID string `json:"sessionId"`
	AgentID   string `json:"agentId,omitempty"`
}

// SessionStatusChangeData is the payload for session_status_change messages.
type SessionStatusChangeData struct {
	SessionID   string        `json:"sessionId"`
	Status      SessionStatus `json:"status"`
	LastEventAt time.Time     `json:"lastEventAt"`
}

// SessionHistoryData is the payload for session_history messages.
type SessionHistoryData struct {
	SessionID string          `json:"sessionId"`
	Events    []*SessionEvent `json:"events"`
	HasMore   bool            `json:"hasMore"`
}

// SessionUpdateData is the payload for session_update messages (incremental).
// 需求：[0.4.0-W2-001.1] 增量廣播變更的 session，取代全量 session_list。
type SessionUpdateData struct {
	Session *SessionInfo `json:"session"`
}

// SessionRemoveData is the payload for session_remove messages (incremental).
type SessionRemoveData struct {
	SessionID string `json:"sessionId"`
}

// ErrorData is the payload for error messages.
type ErrorData struct {
	Code string `json:"code"`
}

// Client represents a connected WebSocket client.
type Client struct {
	conn          *websocket.Conn
	send          chan []byte
	done          chan struct{} // closed when readPump exits, signals writePump to stop
	subscriptions map[string]struct{}
	mu            sync.RWMutex
	closeOnce     sync.Once
	// sendBytes tracks the approximate total bytes queued in the send channel.
	// 需求：[0.4.0-W2-001.1] 基於記憶體大小的 send buffer 限制。
	sendBytes atomic.Int64
}
