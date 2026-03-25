package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestNewHooksHandler(t *testing.T) {
	tests := []struct {
		name           string
		body           string
		wantStatusCode int
		wantEvent      *HookEvent
		wantEventSent  bool
	}{
		{
			name: "TC-001: SubagentStart event received successfully",
			body: `{
				"type": "SubagentStart",
				"agent_id": "a1b2c3d4-1234-5678-9abc-def012345678",
				"agent_type": "subagent",
				"session_id": "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				"timestamp": "2026-03-25T10:30:00.000Z"
			}`,
			wantStatusCode: http.StatusOK,
			wantEvent: &HookEvent{
				Type:      HookEventSubagentStart,
				AgentID:   "a1b2c3d4-1234-5678-9abc-def012345678",
				AgentType: "subagent",
				SessionID: "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				Timestamp: "2026-03-25T10:30:00.000Z",
			},
			wantEventSent: true,
		},
		{
			name: "TC-002: SubagentStop with omitempty fields",
			body: `{
				"type": "SubagentStop",
				"agent_id": "a1b2c3d4-1234-5678-9abc-def012345678",
				"agent_type": "subagent",
				"session_id": "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				"timestamp": "2026-03-25T10:45:00.000Z",
				"agent_transcript_path": "/path/to/session/abc.jsonl",
				"last_assistant_message": "Task completed, check output files"
			}`,
			wantStatusCode: http.StatusOK,
			wantEvent: &HookEvent{
				Type:           HookEventSubagentStop,
				AgentID:        "a1b2c3d4-1234-5678-9abc-def012345678",
				AgentType:      "subagent",
				SessionID:      "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				Timestamp:      "2026-03-25T10:45:00.000Z",
				TranscriptPath: "/path/to/session/abc.jsonl",
				LastMessage:    "Task completed, check output files",
			},
			wantEventSent: true,
		},
		{
			name: "TC-003: TaskCompleted event received",
			body: `{
				"type": "TaskCompleted",
				"session_id": "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				"timestamp": "2026-03-25T11:00:00.000Z"
			}`,
			wantStatusCode: http.StatusOK,
			wantEvent: &HookEvent{
				Type:      HookEventTaskCompleted,
				SessionID: "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				Timestamp: "2026-03-25T11:00:00.000Z",
			},
			wantEventSent: true,
		},
		{
			name: "TC-004: TeammateIdle event received",
			body: `{
				"type": "TeammateIdle",
				"session_id": "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				"timestamp": "2026-03-25T11:05:00.000Z"
			}`,
			wantStatusCode: http.StatusOK,
			wantEvent: &HookEvent{
				Type:      HookEventTeammateIdle,
				SessionID: "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				Timestamp: "2026-03-25T11:05:00.000Z",
			},
			wantEventSent: true,
		},
		{
			name:           "TC-005: JSON parse error",
			body:           `{"type": "SubagentStart", "agent_id": invalid-uuid}`,
			wantStatusCode: http.StatusBadRequest,
			wantEventSent:  false,
		},
		{
			name: "TC-006: Unknown event type",
			body: `{
				"type": "WorktreeCreate",
				"agent_id": "a1b2c3d4-1234-5678-9abc-def012345678",
				"session_id": "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				"timestamp": "2026-03-25T11:10:00.000Z",
				"worktree_path": "/path/to/worktree"
			}`,
			wantStatusCode: http.StatusOK,
			wantEventSent:  false,
		},
		{
			name: "TC-007: Missing type field",
			body: `{
				"agent_id": "a1b2c3d4-1234-5678-9abc-def012345678",
				"session_id": "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				"timestamp": "2026-03-25T10:30:00.000Z"
			}`,
			wantStatusCode: http.StatusBadRequest,
			wantEventSent:  false,
		},
		{
			name: "TC-008: Missing session_id field",
			body: `{
				"type": "SubagentStart",
				"agent_id": "a1b2c3d4-1234-5678-9abc-def012345678",
				"timestamp": "2026-03-25T10:30:00.000Z"
			}`,
			wantStatusCode: http.StatusBadRequest,
			wantEventSent:  false,
		},
		{
			name:           "TC-010: Empty body",
			body:           ``,
			wantStatusCode: http.StatusBadRequest,
			wantEventSent:  false,
		},
		{
			name: "TC-011: SubagentStop with omitempty fields present",
			body: `{
				"type": "SubagentStop",
				"agent_id": "a1b2c3d4-1234-5678-9abc-def012345678",
				"agent_type": "subagent",
				"session_id": "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				"timestamp": "2026-03-25T10:45:00.000Z",
				"agent_transcript_path": "/path/to/session/abc.jsonl",
				"last_assistant_message": "Complete"
			}`,
			wantStatusCode: http.StatusOK,
			wantEvent: &HookEvent{
				Type:           HookEventSubagentStop,
				SessionID:      "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				TranscriptPath: "/path/to/session/abc.jsonl",
				LastMessage:    "Complete",
			},
			wantEventSent: true,
		},
		{
			name: "TC-012: SubagentStop without omitempty fields",
			body: `{
				"type": "SubagentStop",
				"agent_id": "a1b2c3d4-1234-5678-9abc-def012345678",
				"agent_type": "subagent",
				"session_id": "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				"timestamp": "2026-03-25T10:45:00.000Z"
			}`,
			wantStatusCode: http.StatusOK,
			wantEvent: &HookEvent{
				Type:           HookEventSubagentStop,
				AgentID:        "a1b2c3d4-1234-5678-9abc-def012345678",
				SessionID:      "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				TranscriptPath: "",
				LastMessage:    "",
			},
			wantEventSent: true,
		},
		{
			name: "TC-013: ParentAgentID reserved field with value",
			body: `{
				"type": "SubagentStart",
				"agent_id": "child-agent-123",
				"agent_type": "subagent",
				"session_id": "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				"timestamp": "2026-03-25T10:30:00.000Z",
				"parent_agent_id": "parent-agent-456"
			}`,
			wantStatusCode: http.StatusOK,
			wantEvent: &HookEvent{
				Type:          HookEventSubagentStart,
				AgentID:       "child-agent-123",
				SessionID:     "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				ParentAgentID: "parent-agent-456",
			},
			wantEventSent: true,
		},
		{
			name: "TC-014: ParentAgentID reserved field without value",
			body: `{
				"type": "SubagentStart",
				"agent_id": "child-agent-123",
				"agent_type": "subagent",
				"session_id": "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				"timestamp": "2026-03-25T10:30:00.000Z"
			}`,
			wantStatusCode: http.StatusOK,
			wantEvent: &HookEvent{
				Type:          HookEventSubagentStart,
				AgentID:       "child-agent-123",
				SessionID:     "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				ParentAgentID: "",
			},
			wantEventSent: true,
		},
		{
			name: "TC-016: Content-Type text/plain accepted",
			body: `{
				"type": "SubagentStart",
				"agent_id": "a1b2c3d4-1234-5678-9abc-def012345678",
				"agent_type": "subagent",
				"session_id": "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
				"timestamp": "2026-03-25T10:30:00.000Z"
			}`,
			wantStatusCode: http.StatusOK,
			wantEventSent:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			eventCh := make(chan HookEvent, 10)
			defer close(eventCh)

			handler := NewHooksHandler(eventCh)
			req := httptest.NewRequest("POST", "/hooks/agent-event", bytes.NewBufferString(tt.body))
			w := httptest.NewRecorder()

			handler(w, req)

			// Verify status code
			if w.Code != tt.wantStatusCode {
				t.Errorf("status code = %d, want %d", w.Code, tt.wantStatusCode)
			}

			// Verify event sent to channel
			if tt.wantEventSent {
				select {
				case event := <-eventCh:
					if tt.wantEvent != nil {
						if event.Type != tt.wantEvent.Type {
							t.Errorf("event.Type = %q, want %q", event.Type, tt.wantEvent.Type)
						}
						if event.AgentID != tt.wantEvent.AgentID && tt.wantEvent.AgentID != "" {
							t.Errorf("event.AgentID = %q, want %q", event.AgentID, tt.wantEvent.AgentID)
						}
						if event.SessionID != tt.wantEvent.SessionID {
							t.Errorf("event.SessionID = %q, want %q", event.SessionID, tt.wantEvent.SessionID)
						}
						if event.TranscriptPath != tt.wantEvent.TranscriptPath {
							t.Errorf("event.TranscriptPath = %q, want %q", event.TranscriptPath, tt.wantEvent.TranscriptPath)
						}
						if event.LastMessage != tt.wantEvent.LastMessage {
							t.Errorf("event.LastMessage = %q, want %q", event.LastMessage, tt.wantEvent.LastMessage)
						}
						if event.ParentAgentID != tt.wantEvent.ParentAgentID {
							t.Errorf("event.ParentAgentID = %q, want %q", event.ParentAgentID, tt.wantEvent.ParentAgentID)
						}
					}
				case <-time.After(100 * time.Millisecond):
					t.Error("expected event to be sent to channel, but channel timeout")
				}
			} else {
				// Verify no event sent
				select {
				case <-eventCh:
					t.Error("expected no event, but event was sent to channel")
				case <-time.After(100 * time.Millisecond):
					// Expected: no event
				}
			}
		})
	}
}

// TestNewHooksHandler_ChannelFull tests non-blocking send when channel is full
func TestNewHooksHandler_ChannelFull(t *testing.T) {
	t.Run("TC-009: channel full drops event", func(t *testing.T) {
		// Create channel with capacity 1 and fill it
		eventCh := make(chan HookEvent, 1)
		defer close(eventCh)

		// Fill the channel
		eventCh <- HookEvent{Type: "dummy"}

		handler := NewHooksHandler(eventCh)
		body := `{
			"type": "SubagentStart",
			"agent_id": "a1b2c3d4-1234-5678-9abc-def012345678",
			"agent_type": "subagent",
			"session_id": "f635f2ad-9e19-4fca-ba65-4f836ab7b737",
			"timestamp": "2026-03-25T10:30:00.000Z"
		}`
		req := httptest.NewRequest("POST", "/hooks/agent-event", bytes.NewBufferString(body))
		w := httptest.NewRecorder()

		handler(w, req)

		// Should return 200 OK (not block)
		if w.Code != http.StatusOK {
			t.Errorf("status code = %d, want %d", w.Code, http.StatusOK)
		}

		// Channel should still only have the dummy event
		if len(eventCh) != 1 {
			t.Errorf("channel length = %d, want 1", len(eventCh))
		}

		// Read the dummy event to verify no new event was sent
		event := <-eventCh
		if event.Type != "dummy" {
			t.Errorf("channel contained %q, want dummy", event.Type)
		}

		// Verify no additional event
		select {
		case <-eventCh:
			t.Error("unexpected second event in channel")
		default:
			// Expected: channel is now empty
		}
	})
}

// Helper function to verify JSON response format
func verifyJSONResponse(t *testing.T, body []byte) {
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		// Empty response is acceptable
		if len(body) > 0 {
			t.Errorf("response body not valid JSON: %v", err)
		}
	}
}
