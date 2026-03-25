package main

// HookEvent represents an agent lifecycle event from Claude Code HTTP Hooks.
// Fields correspond to the JSON format pushed by Claude Code.
type HookEvent struct {
	// Core identification fields (v2.1.30+)
	Type      string `json:"type"`
	AgentID   string `json:"agent_id"`
	AgentType string `json:"agent_type"`
	SessionID string `json:"session_id"`
	Timestamp string `json:"timestamp"`

	// SubagentStop specific fields (omitempty)
	TranscriptPath string `json:"agent_transcript_path,omitempty"`
	LastMessage    string `json:"last_assistant_message,omitempty"`

	// [v0.3 reserved] Agent parent-child relationship tracking
	ParentAgentID string `json:"parent_agent_id,omitempty"`
}

// errorResponse is the HTTP error response body format
type errorResponse struct {
	Error string `json:"error"`
}
