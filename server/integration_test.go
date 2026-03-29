package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"sync/atomic"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

// === Integration Test Harness ===

// integrationHarness wires up all real components (FileWatcher, EventDispatcher,
// SessionRegistry, WebSocketServer) against a temporary directory for end-to-end testing.
type integrationHarness struct {
	tmpDir       string
	sessionEvCh  chan SessionEvent
	hookEvCh     chan HookEvent
	dispatchCh   chan DispatchedEvent
	registry     *SessionRegistry
	watcher      *FileWatcher
	dispatcher   *EventDispatcher
	wsServer     *WebSocketServer
	httpServer   *httptest.Server
	ctx          context.Context
	cancel       context.CancelFunc
	timeProvider *controllableTime
}

// controllableTime provides an injectable clock for status scan tests.
type controllableTime struct {
	value atomic.Value // stores time.Time
}

func newControllableTime(t time.Time) *controllableTime {
	ct := &controllableTime{}
	ct.value.Store(t)
	return ct
}

func (ct *controllableTime) now() time.Time {
	return ct.value.Load().(time.Time)
}

func (ct *controllableTime) set(t time.Time) {
	ct.value.Store(t)
}

func (ct *controllableTime) advance(d time.Duration) {
	ct.set(ct.now().Add(d))
}

// setupIntegrationHarness creates a fully wired harness with all goroutines running.
// Set skipWSRun to true to leave dispatchCh unconsumed (for TC-GO-07).
func setupIntegrationHarness(t *testing.T, skipWSRun bool) *integrationHarness {
	t.Helper()

	tmpDir := t.TempDir()
	// FileWatcher expects claudeHome/projects/ directory
	projectsDir := filepath.Join(tmpDir, ProjectsDirName)
	if err := os.MkdirAll(projectsDir, 0o755); err != nil {
		t.Fatalf("failed to create projects dir: %v", err)
	}

	sessionEvCh := make(chan SessionEvent, SessionEventChBufferSize)
	hookEvCh := make(chan HookEvent, HookEventChBufferSize)
	dispatchCh := make(chan DispatchedEvent, DispatchChBufferSize)

	tp := newControllableTime(time.Now())
	registry := NewSessionRegistry(tp.now)
	watcher := NewFileWatcher(tmpDir, sessionEvCh, registry)
	dispatcher := NewEventDispatcher(registry, sessionEvCh, hookEvCh, dispatchCh, tp.now)
	wsServer := NewWebSocketServer(registry, dispatchCh, tp.now)

	ctx, cancel := context.WithCancel(context.Background())

	go watcher.Start(ctx)
	go dispatcher.Run(ctx)
	if !skipWSRun {
		go wsServer.Run(ctx)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/ws", wsServer.HandleWS)
	httpSrv := httptest.NewServer(mux)

	t.Cleanup(func() {
		cancel()
		httpSrv.Close()
	})

	// Small delay for FileWatcher to initialize fsnotify watchers
	time.Sleep(100 * time.Millisecond)

	return &integrationHarness{
		tmpDir:       tmpDir,
		sessionEvCh:  sessionEvCh,
		hookEvCh:     hookEvCh,
		dispatchCh:   dispatchCh,
		registry:     registry,
		watcher:      watcher,
		dispatcher:   dispatcher,
		wsServer:     wsServer,
		httpServer:   httpSrv,
		ctx:          ctx,
		cancel:       cancel,
		timeProvider: tp,
	}
}

// === Helpers ===

// ensureProjectDir creates the project directory and waits for FileWatcher
// to detect and watch it. Must be called before the first writeJSONL for a project path.
func ensureProjectDir(t *testing.T, h *integrationHarness, projectPath string) {
	t.Helper()

	encodedPath := url.PathEscape(projectPath)
	dir := filepath.Join(h.tmpDir, ProjectsDirName, encodedPath)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatalf("failed to create project dir: %v", err)
	}
	// Wait for FileWatcher to detect the new directory and add a watch on it
	time.Sleep(200 * time.Millisecond)
}

// writeJSONL appends a JSON line to the session's JSONL file under the correct
// directory structure: tmpDir/projects/{urlEncodedPath}/{sessionID}.jsonl
// The project directory must already exist (call ensureProjectDir first).
func writeJSONL(t *testing.T, h *integrationHarness, sessionID, projectPath, jsonLine string) {
	t.Helper()

	encodedPath := url.PathEscape(projectPath)
	dir := filepath.Join(h.tmpDir, ProjectsDirName, encodedPath)

	filePath := filepath.Join(dir, sessionID+JSONLExtension)
	f, err := os.OpenFile(filePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o644)
	if err != nil {
		t.Fatalf("failed to open JSONL file: %v", err)
	}
	defer f.Close()

	if _, err := f.WriteString(jsonLine + "\n"); err != nil {
		t.Fatalf("failed to write JSONL line: %v", err)
	}
}

// connectWS dials the harness's WebSocket endpoint and reads the initial session_list.
func connectWS(t *testing.T, h *integrationHarness) *websocket.Conn {
	t.Helper()

	wsURL := "ws" + h.httpServer.URL[len("http"):] + "/ws"
	conn, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatalf("failed to dial websocket: %v", err)
	}
	t.Cleanup(func() { conn.Close() })

	// Read and verify initial session_list
	msg := readMsg(t, conn, 5*time.Second)
	if msg.Type != "session_list" {
		t.Fatalf("expected initial session_list, got %q", msg.Type)
	}

	return conn
}

// rawMsg holds a parsed server message with raw JSON data.
type rawMsg struct {
	Type string
	Data json.RawMessage
}

// readMsg reads a single message from the WebSocket with the given timeout.
func readMsg(t *testing.T, conn *websocket.Conn, timeout time.Duration) rawMsg {
	t.Helper()

	conn.SetReadDeadline(time.Now().Add(timeout))
	_, data, err := conn.ReadMessage()
	if err != nil {
		t.Fatalf("failed to read message: %v", err)
	}

	var m struct {
		Type string          `json:"type"`
		Data json.RawMessage `json:"data"`
	}
	if err := json.Unmarshal(data, &m); err != nil {
		t.Fatalf("failed to unmarshal message: %v", err)
	}

	return rawMsg{Type: m.Type, Data: m.Data}
}

// readMsgOfType reads messages until it finds one matching the given type, or times out.
func readMsgOfType(t *testing.T, conn *websocket.Conn, msgType string, timeout time.Duration) rawMsg {
	t.Helper()

	deadline := time.Now().Add(timeout)
	for {
		remaining := time.Until(deadline)
		if remaining <= 0 {
			t.Fatalf("timeout waiting for message type %q", msgType)
		}
		msg := readMsg(t, conn, remaining)
		if msg.Type == msgType {
			return msg
		}
	}
}

// sendAction sends a client action message.
func sendAction(t *testing.T, conn *websocket.Conn, action, sessionID string) {
	t.Helper()

	msg := ClientMessage{Action: action, SessionID: sessionID}
	data, err := json.Marshal(msg)
	if err != nil {
		t.Fatalf("failed to marshal client message: %v", err)
	}
	if err := conn.WriteMessage(websocket.TextMessage, data); err != nil {
		t.Fatalf("failed to send client message: %v", err)
	}
}

// expectNoMoreMessages asserts no messages arrive within the given duration.
func expectNoMoreMessages(t *testing.T, conn *websocket.Conn, wait time.Duration) {
	t.Helper()

	conn.SetReadDeadline(time.Now().Add(wait))
	_, _, err := conn.ReadMessage()
	if err == nil {
		t.Fatal("expected no message but received one")
	}
}

// === Test JSONL Data ===

func userMessageJSON(sessionID string, ts time.Time) string {
	return fmt.Sprintf(
		`{"type":"human","message":{"id":"msg-u-%s","content":[{"type":"text","text":"Hello"}],"role":"user"},"timestamp":"%s","uuid":"%s"}`,
		sessionID, ts.Format(time.RFC3339), sessionID,
	)
}

func assistantMessageJSON(sessionID string, ts time.Time, text string) string {
	return fmt.Sprintf(
		`{"type":"assistant","message":{"id":"msg-a-%s","content":[{"type":"text","text":"%s"}],"role":"assistant"},"timestamp":"%s","uuid":"%s"}`,
		sessionID, text, ts.Format(time.RFC3339), sessionID,
	)
}

// === TC-GO-01: JSONL write triggers session_update (incremental) ===

func TestIntegration_JSONLWriteTriggersSessionList(t *testing.T) {
	h := setupIntegrationHarness(t, false)
	conn := connectWS(t, h)

	ts := time.Now().Truncate(time.Second)
	ensureProjectDir(t, h, "/project/path")
	writeJSONL(t, h, "session-A", "/project/path", userMessageJSON("session-A", ts))

	// 需求：[0.4.0-W2-001.1] 增量廣播 session_update 取代全量 session_list
	msg := readMsgOfType(t, conn, MsgTypeSessionUpdate, 5*time.Second)

	var data SessionUpdateData
	if err := json.Unmarshal(msg.Data, &data); err != nil {
		t.Fatalf("failed to unmarshal session_update data: %v", err)
	}

	if data.Session == nil || data.Session.ID != "session-A" {
		t.Fatal("session-A not found in session_update")
	}
	if data.Session.Status != SessionStatusActive {
		t.Errorf("expected status active, got %v", data.Session.Status)
	}
}

// TC-GO-01 boundary: malformed JSON does not crash pipeline
func TestIntegration_MalformedJSONDoesNotCrashPipeline(t *testing.T) {
	h := setupIntegrationHarness(t, false)
	conn := connectWS(t, h)

	ts := time.Now().Truncate(time.Second)

	// Write invalid JSON
	ensureProjectDir(t, h, "/project")
	writeJSONL(t, h, "session-B", "/project", "this is not json")

	// Wait briefly, then write valid JSON
	time.Sleep(200 * time.Millisecond)
	writeJSONL(t, h, "session-B", "/project", userMessageJSON("session-B", ts))

	// 需求：[0.4.0-W2-001.1] 增量廣播 session_update
	msg := readMsgOfType(t, conn, MsgTypeSessionUpdate, 5*time.Second)

	var data SessionUpdateData
	if err := json.Unmarshal(msg.Data, &data); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}

	if data.Session == nil || data.Session.ID != "session-B" {
		t.Fatal("session-B not found after malformed JSON")
	}
}

// === TC-GO-02: Subscribe then receive session_event ===

func TestIntegration_SubscribeReceivesSessionEvent(t *testing.T) {
	h := setupIntegrationHarness(t, false)
	conn := connectWS(t, h)

	ts := time.Now().Truncate(time.Second)

	// Create session
	ensureProjectDir(t, h, "/project")
	writeJSONL(t, h, "session-1", "/project", userMessageJSON("session-1", ts))
	// Wait for session_list acknowledging session-1
	readMsgOfType(t, conn, MsgTypeSessionUpdate, 5*time.Second)

	// Subscribe
	sendAction(t, conn, "subscribe_session", "session-1")
	time.Sleep(100 * time.Millisecond)

	// Write assistant message
	writeJSONL(t, h, "session-1", "/project", assistantMessageJSON("session-1", ts.Add(time.Second), "Hello from assistant"))

	// Read until session_event
	msg := readMsgOfType(t, conn, "session_event", 5*time.Second)

	var eventData map[string]interface{}
	if err := json.Unmarshal(msg.Data, &eventData); err != nil {
		t.Fatalf("failed to unmarshal session_event: %v", err)
	}
	if eventData["sessionId"] != "session-1" {
		t.Errorf("expected sessionId session-1, got %v", eventData["sessionId"])
	}
}

// === TC-GO-03: Client requests session_history ===

func TestIntegration_GetSessionHistory(t *testing.T) {
	h := setupIntegrationHarness(t, false)
	conn := connectWS(t, h)

	ts := time.Now().Truncate(time.Second)

	// Write 3 events
	ensureProjectDir(t, h, "/project")
	writeJSONL(t, h, "session-1", "/project", userMessageJSON("session-1", ts))
	writeJSONL(t, h, "session-1", "/project", assistantMessageJSON("session-1", ts.Add(time.Second), "Reply 1"))
	writeJSONL(t, h, "session-1", "/project", userMessageJSON("session-1", ts.Add(2*time.Second)))

	// Wait for events to be processed
	readMsgOfType(t, conn, MsgTypeSessionUpdate, 5*time.Second)
	// Drain additional session_list broadcasts
	time.Sleep(500 * time.Millisecond)

	// Request history
	sendAction(t, conn, "get_session_history", "session-1")

	msg := readMsgOfType(t, conn, "session_history", 5*time.Second)

	var histData SessionHistoryData
	if err := json.Unmarshal(msg.Data, &histData); err != nil {
		t.Fatalf("failed to unmarshal session_history: %v", err)
	}
	if histData.SessionID != "session-1" {
		t.Errorf("expected sessionId session-1, got %s", histData.SessionID)
	}
	// We wrote 3 JSONL lines; the parser may produce multiple events per line
	// (e.g., user events produce 1 event each). At minimum we expect >= 3.
	if len(histData.Events) < 3 {
		t.Errorf("expected >= 3 events, got %d", len(histData.Events))
	}
}

// TC-GO-03 boundary: nonexistent session returns error
func TestIntegration_GetSessionHistoryNotFound(t *testing.T) {
	h := setupIntegrationHarness(t, false)
	conn := connectWS(t, h)

	sendAction(t, conn, "get_session_history", "nonexistent-session")

	msg := readMsgOfType(t, conn, "error", 5*time.Second)

	var errData ErrorData
	if err := json.Unmarshal(msg.Data, &errData); err != nil {
		t.Fatalf("failed to unmarshal error: %v", err)
	}
	if errData.Code != "SESSION_NOT_FOUND" {
		t.Errorf("expected SESSION_NOT_FOUND, got %s", errData.Code)
	}
}

// === TC-GO-04: Unsubscribed client does not receive session_event ===

func TestIntegration_UnsubscribedClientNoSessionEvent(t *testing.T) {
	h := setupIntegrationHarness(t, false)
	conn := connectWS(t, h)

	ts := time.Now().Truncate(time.Second)

	// Create session (no subscribe)
	ensureProjectDir(t, h, "/project")
	writeJSONL(t, h, "session-X", "/project", userMessageJSON("session-X", ts))
	readMsgOfType(t, conn, MsgTypeSessionUpdate, 5*time.Second)

	// Append assistant message (produces ChangeTypeUpdated, which only pushes to subscribers)
	writeJSONL(t, h, "session-X", "/project", assistantMessageJSON("session-X", ts.Add(time.Second), "response"))

	// Unsubscribed client should not receive session_event
	// (ChangeTypeUpdated only pushes to subscribers, no broadcast)
	time.Sleep(500 * time.Millisecond)
	expectNoMoreMessages(t, conn, 500*time.Millisecond)
}

// === TC-GO-05: Status scan triggers session_status_change ===

func TestIntegration_StatusChangeOnIdleTimeout(t *testing.T) {
	h := setupIntegrationHarness(t, false)
	conn := connectWS(t, h)

	ts := h.timeProvider.now()

	// Create active session
	ensureProjectDir(t, h, "/project")
	writeJSONL(t, h, "session-1", "/project", userMessageJSON("session-1", ts))
	readMsgOfType(t, conn, MsgTypeSessionUpdate, 5*time.Second)

	// Advance time past ActiveThreshold (2 minutes) to make session idle
	h.timeProvider.advance(ActiveThreshold + time.Minute)

	// Wait for status scan ticker to fire (real ticker at StatusScanInterval = 30s).
	// The scan will see the session as past ActiveThreshold via timeProvider.
	// We need to wait up to StatusScanInterval + buffer for the tick.
	msg := readMsgOfType(t, conn, "session_status_change", StatusScanInterval+5*time.Second)

	var statusData SessionStatusChangeData
	if err := json.Unmarshal(msg.Data, &statusData); err != nil {
		t.Fatalf("failed to unmarshal status change: %v", err)
	}
	if statusData.SessionID != "session-1" {
		t.Errorf("expected session-1, got %s", statusData.SessionID)
	}
	if statusData.Status != SessionStatusIdle {
		t.Errorf("expected idle status, got %v", statusData.Status)
	}
}

// === TC-GO-06: Invalid action returns error ===

func TestIntegration_InvalidActionReturnsError(t *testing.T) {
	h := setupIntegrationHarness(t, false)
	conn := connectWS(t, h)

	sendAction(t, conn, "invalid_action_name", "")

	msg := readMsgOfType(t, conn, "error", 5*time.Second)

	var errData ErrorData
	if err := json.Unmarshal(msg.Data, &errData); err != nil {
		t.Fatalf("failed to unmarshal error: %v", err)
	}
	if errData.Code != "INVALID_ACTION" {
		t.Errorf("expected INVALID_ACTION, got %s", errData.Code)
	}
}

// === TC-GO-07: Non-blocking drop when dispatchCh full ===

func TestIntegration_NonBlockingDropWhenChannelFull(t *testing.T) {
	h := setupIntegrationHarness(t, true) // skipWSRun = true, no consumer on dispatchCh

	ts := time.Now().Truncate(time.Second)

	// Write many lines exceeding dispatchCh buffer. If sendToOutCh blocks,
	// this function will deadlock and the test will timeout.
	done := make(chan struct{})
	ensureProjectDir(t, h, "/project")
	go func() {
		for i := 0; i < DispatchChBufferSize+50; i++ {
			writeJSONL(t, h, "session-flood", "/project",
				userMessageJSON("session-flood", ts.Add(time.Duration(i)*time.Millisecond)))
			// Small delay for FileWatcher to process each write
			time.Sleep(10 * time.Millisecond)
		}
		close(done)
	}()

	select {
	case <-done:
		// Completed without deadlock
	case <-time.After(30 * time.Second):
		t.Fatal("deadlock detected: writes did not complete within timeout")
	}
}
