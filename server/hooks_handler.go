package main

import (
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
)

// NewHooksHandler returns an HTTP handler for POST /hooks/agent-event.
// It parses incoming JSON hook events and sends them to the eventCh channel.
// The handler uses non-blocking send to avoid blocking Claude Code requests.
func NewHooksHandler(eventCh chan<- HookEvent) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		logger := slog.Default()

		// Step 1: Read request body
		bodyBytes, err := io.ReadAll(r.Body)
		if err != nil {
			writeErrorResponse(w, http.StatusBadRequest, "failed to read body")
			logger.Error(LogFailedToReadBody, "layer", "hooks_handler", "error", err)
			return
		}

		// Step 2: Parse JSON into HookEvent
		event := HookEvent{}
		err = json.Unmarshal(bodyBytes, &event)
		if err != nil {
			writeErrorResponse(w, http.StatusBadRequest, "invalid JSON: "+err.Error())
			logger.Error(LogFailedToParseEvent, "layer", "hooks_handler", "error", err)
			return
		}

		// Step 3: Validate required fields
		if event.Type == "" {
			writeErrorResponse(w, http.StatusBadRequest, ErrMissingField+": type")
			logger.Error(LogMissingRequiredField, "layer", "hooks_handler", "field", "type")
			return
		}

		if event.SessionID == "" {
			writeErrorResponse(w, http.StatusBadRequest, ErrMissingField+": session_id")
			logger.Error(LogMissingRequiredField, "layer", "hooks_handler", "field", "session_id")
			return
		}

		// Step 4: Check if event type is known
		if !isKnownEventType(event.Type) {
			writeJSONResponse(w, http.StatusOK, nil)
			logger.Warn(LogUnknownEventType,
				"layer", "hooks_handler",
				"type", event.Type,
				"hint", HintUnknownEventType)
			return
		}

		// Step 5: Non-blocking send to channel
		select {
		case eventCh <- event:
			// Successfully sent
			logger.Info(LogHookEventReceived,
				"layer", "hooks_handler",
				"type", event.Type,
				"agent_id", event.AgentID,
				"session_id", event.SessionID)

		default:
			// Channel full, drop event
			logger.Warn(LogChannelFull,
				"layer", "hooks_handler",
				"type", event.Type)
		}

		// Step 6: Return 200 OK
		writeJSONResponse(w, http.StatusOK, nil)
	}
}

// isKnownEventType checks if the event type is recognized in v0.2.
// 使用集中定義的 KnownHookEventTypes，新增事件類型只需在 hooks_constants.go 中添加。
func isKnownEventType(eventType string) bool {
	return KnownHookEventTypes[eventType]
}

// writeErrorResponse writes a JSON error response
func writeErrorResponse(w http.ResponseWriter, statusCode int, errorMessage string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	resp := errorResponse{Error: errorMessage}
	json.NewEncoder(w).Encode(resp)
}

// writeJSONResponse writes a JSON response
func writeJSONResponse(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	if data != nil {
		json.NewEncoder(w).Encode(data)
	}
}
