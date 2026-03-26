package main

import "time"

// SessionQuerier defines the read-only interface for querying session data.
// WebSocketServer depends on this interface to decouple from SessionRegistry.
type SessionQuerier interface {
	// List returns a copy of all sessions.
	List() []*SessionInfo

	// Get returns a copy of the session with the given ID.
	// Returns nil and false if the session does not exist.
	Get(sessionID string) (*SessionInfo, bool)

	// GetHistory returns paginated history events for the given session.
	// limit controls the maximum number of events returned.
	// before filters events with timestamp strictly before the given time.
	// If before is zero, all events are considered.
	// Returns the events, whether there are more events, and an error if session not found.
	GetHistory(sessionID string, limit int, before time.Time) ([]*SessionEvent, bool, error)
}
