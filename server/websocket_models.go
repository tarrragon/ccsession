package main

import (
	"sync"

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
	Data interface{} `json:"data"`
}

// SessionListData is the payload for session_list messages.
type SessionListData struct {
	Sessions []*SessionInfo `json:"sessions"`
}

// SessionEventData is the payload for session_event messages.
type SessionEventData struct {
	SessionID string        `json:"sessionId"`
	Event     *SessionEvent `json:"event,omitempty"`
	AgentID   string        `json:"agentId,omitempty"`
}

// SessionStatusChangeData is the payload for session_status_change messages.
type SessionStatusChangeData struct {
	SessionID string        `json:"sessionId"`
	Status    SessionStatus `json:"status"`
}

// SessionHistoryData is the payload for session_history messages.
type SessionHistoryData struct {
	SessionID string          `json:"sessionId"`
	Events    []*SessionEvent `json:"events"`
	HasMore   bool            `json:"hasMore"`
}

// ErrorData is the payload for error messages.
type ErrorData struct {
	Code string `json:"code"`
}

// Client represents a connected WebSocket client.
type Client struct {
	conn          *websocket.Conn
	send          chan []byte
	subscriptions map[string]struct{}
	mu            sync.RWMutex
}
