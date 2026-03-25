package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

// === Mock SessionQuerier ===

type mockSessionQuerier struct {
	sessions map[string]*SessionInfo
	history  map[string][]*SessionEvent
}

func (m *mockSessionQuerier) List() []*SessionInfo {
	result := make([]*SessionInfo, 0, len(m.sessions))
	for _, s := range m.sessions {
		copied := *s
		result = append(result, &copied)
	}
	return result
}

func (m *mockSessionQuerier) Get(sessionID string) (*SessionInfo, bool) {
	s, ok := m.sessions[sessionID]
	if !ok {
		return nil, false
	}
	copied := *s
	return &copied, true
}

func (m *mockSessionQuerier) GetHistory(sessionID string, limit int, before time.Time) ([]*SessionEvent, bool, error) {
	if _, ok := m.sessions[sessionID]; !ok {
		return nil, false, errSessionNotFound
	}

	events := m.history[sessionID]
	if len(events) == 0 {
		return []*SessionEvent{}, false, nil
	}

	// Filter by before
	filtered := events
	if !before.IsZero() {
		filtered = make([]*SessionEvent, 0)
		for _, e := range events {
			if e.Timestamp.Before(before) {
				filtered = append(filtered, e)
			}
		}
	}

	hasMore := len(filtered) > limit
	if len(filtered) > limit {
		filtered = filtered[len(filtered)-limit:]
	}

	result := make([]*SessionEvent, len(filtered))
	for i, e := range filtered {
		copied := *e
		result[i] = &copied
	}

	return result, hasMore, nil
}

// === Test Helpers ===

type testEnv struct {
	server     *WebSocketServer
	httpServer *httptest.Server
	dispatchCh chan DispatchedEvent
	querier    *mockSessionQuerier
}

func setupTestServer(t *testing.T, querier *mockSessionQuerier) *testEnv {
	t.Helper()

	dispatchCh := make(chan DispatchedEvent, DefaultEventChannelSize)
	ws := NewWebSocketServer(querier, dispatchCh, time.Now)

	mux := http.NewServeMux()
	mux.HandleFunc("/ws", ws.HandleWS)
	httpSrv := httptest.NewServer(mux)
	t.Cleanup(func() { httpSrv.Close() })

	return &testEnv{
		server:     ws,
		httpServer: httpSrv,
		dispatchCh: dispatchCh,
		querier:    querier,
	}
}

func dialWS(t *testing.T, httpURL string) *websocket.Conn {
	t.Helper()
	wsURL := "ws" + strings.TrimPrefix(httpURL, "http") + "/ws"
	conn, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatalf("failed to dial websocket: %v", err)
	}
	t.Cleanup(func() { conn.Close() })
	return conn
}

func readServerMessage(t *testing.T, conn *websocket.Conn) ServerMessage {
	t.Helper()
	conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	_, data, err := conn.ReadMessage()
	if err != nil {
		t.Fatalf("failed to read server message: %v", err)
	}
	var msg ServerMessage
	// Use json.RawMessage for Data to allow re-parsing
	var raw struct {
		Type string          `json:"type"`
		Data json.RawMessage `json:"data"`
	}
	if err := json.Unmarshal(data, &raw); err != nil {
		t.Fatalf("failed to unmarshal server message: %v", err)
	}
	msg.Type = raw.Type
	msg.Data = raw.Data
	return msg
}

func readServerMessageTyped[T any](t *testing.T, conn *websocket.Conn) (string, T) {
	t.Helper()
	conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	_, data, err := conn.ReadMessage()
	if err != nil {
		var zero T
		t.Fatalf("failed to read server message: %v", err)
		return "", zero
	}
	var raw struct {
		Type string          `json:"type"`
		Data json.RawMessage `json:"data"`
	}
	if err := json.Unmarshal(data, &raw); err != nil {
		var zero T
		t.Fatalf("failed to unmarshal server message: %v", err)
		return "", zero
	}
	var result T
	if err := json.Unmarshal(raw.Data, &result); err != nil {
		var zero T
		t.Fatalf("failed to unmarshal data: %v", err)
		return "", zero
	}
	return raw.Type, result
}

func sendClientMessage(t *testing.T, conn *websocket.Conn, msg ClientMessage) {
	t.Helper()
	data, err := json.Marshal(msg)
	if err != nil {
		t.Fatalf("failed to marshal client message: %v", err)
	}
	if err := conn.WriteMessage(websocket.TextMessage, data); err != nil {
		t.Fatalf("failed to write client message: %v", err)
	}
}

func newMockQuerier(sessions ...*SessionInfo) *mockSessionQuerier {
	m := &mockSessionQuerier{
		sessions: make(map[string]*SessionInfo),
		history:  make(map[string][]*SessionEvent),
	}
	for _, s := range sessions {
		m.sessions[s.ID] = s
	}
	return m
}

func expectNoMessage(t *testing.T, conn *websocket.Conn) {
	t.Helper()
	conn.SetReadDeadline(time.Now().Add(200 * time.Millisecond))
	_, _, err := conn.ReadMessage()
	if err == nil {
		t.Fatal("expected no message but got one")
	}
}

// === TC-01: Connection established, receives session_list ===

func TestHandleWS_NewConnection_ReceivesSessionList(t *testing.T) {
	q := newMockQuerier(
		&SessionInfo{ID: "s1", Status: SessionStatusActive},
		&SessionInfo{ID: "s2", Status: SessionStatusIdle},
		&SessionInfo{ID: "s3", Status: SessionStatusCompleted},
	)
	env := setupTestServer(t, q)
	conn := dialWS(t, env.httpServer.URL)

	msgType, data := readServerMessageTyped[SessionListData](t, conn)
	if msgType != MsgTypeSessionList {
		t.Fatalf("expected type %s, got %s", MsgTypeSessionList, msgType)
	}
	if len(data.Sessions) != 3 {
		t.Fatalf("expected 3 sessions, got %d", len(data.Sessions))
	}
}

// === TC-02: Multiple clients each receive session_list ===

func TestHandleWS_MultipleClients_EachReceivesSessionList(t *testing.T) {
	q := newMockQuerier(
		&SessionInfo{ID: "s1", Status: SessionStatusActive},
		&SessionInfo{ID: "s2", Status: SessionStatusIdle},
	)
	env := setupTestServer(t, q)

	connA := dialWS(t, env.httpServer.URL)
	_, dataA := readServerMessageTyped[SessionListData](t, connA)
	if len(dataA.Sessions) != 2 {
		t.Fatalf("client A: expected 2 sessions, got %d", len(dataA.Sessions))
	}

	connB := dialWS(t, env.httpServer.URL)
	_, dataB := readServerMessageTyped[SessionListData](t, connB)
	if len(dataB.Sessions) != 2 {
		t.Fatalf("client B: expected 2 sessions, got %d", len(dataB.Sessions))
	}

	// Wait briefly for registration to complete
	time.Sleep(50 * time.Millisecond)
	if count := env.server.clientCount(); count != 2 {
		t.Fatalf("expected 2 clients, got %d", count)
	}
}

// === TC-03: subscribe_session valid session ===

func TestSubscribeSession_ValidSession_Success(t *testing.T) {
	q := newMockQuerier(&SessionInfo{ID: "abc-123", Status: SessionStatusActive})
	env := setupTestServer(t, q)
	conn := dialWS(t, env.httpServer.URL)
	_ = readServerMessage(t, conn) // consume initial session_list

	sendClientMessage(t, conn, ClientMessage{Action: ActionSubscribeSession, SessionID: "abc-123"})

	// No error response expected; verify by sending another request
	sendClientMessage(t, conn, ClientMessage{Action: ActionGetSessionList})
	msgType, _ := readServerMessageTyped[SessionListData](t, conn)
	if msgType != MsgTypeSessionList {
		t.Fatalf("expected session_list after subscribe, got %s", msgType)
	}
}

// === TC-04: subscribe_session empty sessionId ===

func TestSubscribeSession_EmptySessionId_ReturnsError(t *testing.T) {
	q := newMockQuerier()
	env := setupTestServer(t, q)
	conn := dialWS(t, env.httpServer.URL)
	_ = readServerMessage(t, conn)

	sendClientMessage(t, conn, ClientMessage{Action: ActionSubscribeSession, SessionID: ""})
	msgType, data := readServerMessageTyped[ErrorData](t, conn)
	if msgType != MsgTypeError {
		t.Fatalf("expected error, got %s", msgType)
	}
	if data.Code != ErrCodeInvalidParams {
		t.Fatalf("expected code %s, got %s", ErrCodeInvalidParams, data.Code)
	}
}

// === TC-05: subscribe_session nonexistent session ===

func TestSubscribeSession_NonexistentSession_ReturnsError(t *testing.T) {
	q := newMockQuerier()
	env := setupTestServer(t, q)
	conn := dialWS(t, env.httpServer.URL)
	_ = readServerMessage(t, conn)

	sendClientMessage(t, conn, ClientMessage{Action: ActionSubscribeSession, SessionID: "nonexistent"})
	msgType, data := readServerMessageTyped[ErrorData](t, conn)
	if msgType != MsgTypeError {
		t.Fatalf("expected error, got %s", msgType)
	}
	if data.Code != ErrCodeSessionNotFound {
		t.Fatalf("expected code %s, got %s", ErrCodeSessionNotFound, data.Code)
	}
}

// === TC-06: unsubscribe_session success ===

func TestUnsubscribeSession_Subscribed_Success(t *testing.T) {
	q := newMockQuerier(&SessionInfo{ID: "abc-123", Status: SessionStatusActive})
	env := setupTestServer(t, q)
	conn := dialWS(t, env.httpServer.URL)
	_ = readServerMessage(t, conn)

	// Subscribe first
	sendClientMessage(t, conn, ClientMessage{Action: ActionSubscribeSession, SessionID: "abc-123"})
	// Unsubscribe
	sendClientMessage(t, conn, ClientMessage{Action: ActionUnsubscribeSession, SessionID: "abc-123"})

	// Verify by requesting session list (no error expected)
	sendClientMessage(t, conn, ClientMessage{Action: ActionGetSessionList})
	msgType, _ := readServerMessageTyped[SessionListData](t, conn)
	if msgType != MsgTypeSessionList {
		t.Fatalf("expected session_list, got %s", msgType)
	}
}

// === TC-07: unsubscribe_session not subscribed (idempotent) ===

func TestUnsubscribeSession_NotSubscribed_Idempotent(t *testing.T) {
	q := newMockQuerier()
	env := setupTestServer(t, q)
	conn := dialWS(t, env.httpServer.URL)
	_ = readServerMessage(t, conn)

	sendClientMessage(t, conn, ClientMessage{Action: ActionUnsubscribeSession, SessionID: "abc-123"})

	// No error response; verify by requesting session list
	sendClientMessage(t, conn, ClientMessage{Action: ActionGetSessionList})
	msgType, _ := readServerMessageTyped[SessionListData](t, conn)
	if msgType != MsgTypeSessionList {
		t.Fatalf("expected session_list, got %s", msgType)
	}
}

// === TC-08: get_session_list returns current sessions ===

func TestGetSessionList_ReturnsCurrentSessions(t *testing.T) {
	q := newMockQuerier(
		&SessionInfo{ID: "s1", Status: SessionStatusActive},
		&SessionInfo{ID: "s2", Status: SessionStatusIdle},
		&SessionInfo{ID: "s3", Status: SessionStatusCompleted},
	)
	env := setupTestServer(t, q)
	conn := dialWS(t, env.httpServer.URL)
	_ = readServerMessage(t, conn) // initial session_list

	sendClientMessage(t, conn, ClientMessage{Action: ActionGetSessionList})
	msgType, data := readServerMessageTyped[SessionListData](t, conn)
	if msgType != MsgTypeSessionList {
		t.Fatalf("expected session_list, got %s", msgType)
	}
	if len(data.Sessions) != 3 {
		t.Fatalf("expected 3 sessions, got %d", len(data.Sessions))
	}
}

// === TC-09: get_session_list empty ===

func TestHandleWS_EmptyRegistry_ReceivesEmptySessionList(t *testing.T) {
	q := newMockQuerier()
	env := setupTestServer(t, q)
	conn := dialWS(t, env.httpServer.URL)

	msgType, data := readServerMessageTyped[SessionListData](t, conn)
	if msgType != MsgTypeSessionList {
		t.Fatalf("expected session_list, got %s", msgType)
	}
	if len(data.Sessions) != 0 {
		t.Fatalf("expected 0 sessions, got %d", len(data.Sessions))
	}
}

// === TC-10: get_session_history success ===

func TestGetSessionHistory_Success(t *testing.T) {
	baseTime := time.Date(2026, 3, 25, 10, 0, 0, 0, time.UTC)
	q := newMockQuerier(&SessionInfo{ID: "abc-123", Status: SessionStatusActive})
	for i := 0; i < 50; i++ {
		q.history["abc-123"] = append(q.history["abc-123"], &SessionEvent{
			SessionID: "abc-123",
			Timestamp: baseTime.Add(time.Duration(i) * time.Minute),
			Type:      EventTypeAssistant,
		})
	}

	env := setupTestServer(t, q)
	conn := dialWS(t, env.httpServer.URL)
	_ = readServerMessage(t, conn)

	sendClientMessage(t, conn, ClientMessage{
		Action:    ActionGetSessionHistory,
		SessionID: "abc-123",
	})
	msgType, data := readServerMessageTyped[SessionHistoryData](t, conn)
	if msgType != MsgTypeSessionHistory {
		t.Fatalf("expected session_history, got %s", msgType)
	}
	if len(data.Events) != 50 {
		t.Fatalf("expected 50 events, got %d", len(data.Events))
	}
	if data.HasMore {
		t.Fatal("expected hasMore=false")
	}
}

// === TC-11: get_session_history invalid (empty) sessionId ===

func TestGetSessionHistory_EmptySessionId_ReturnsError(t *testing.T) {
	q := newMockQuerier()
	env := setupTestServer(t, q)
	conn := dialWS(t, env.httpServer.URL)
	_ = readServerMessage(t, conn)

	sendClientMessage(t, conn, ClientMessage{
		Action:    ActionGetSessionHistory,
		SessionID: "",
	})
	msgType, data := readServerMessageTyped[ErrorData](t, conn)
	if msgType != MsgTypeError {
		t.Fatalf("expected error, got %s", msgType)
	}
	if data.Code != ErrCodeInvalidParams {
		t.Fatalf("expected code %s, got %s", ErrCodeInvalidParams, data.Code)
	}
}

// === TC-12: get_session_history nonexistent session ===

func TestGetSessionHistory_NonexistentSession_ReturnsError(t *testing.T) {
	q := newMockQuerier()
	env := setupTestServer(t, q)
	conn := dialWS(t, env.httpServer.URL)
	_ = readServerMessage(t, conn)

	sendClientMessage(t, conn, ClientMessage{
		Action:    ActionGetSessionHistory,
		SessionID: "nonexistent",
	})
	msgType, data := readServerMessageTyped[ErrorData](t, conn)
	if msgType != MsgTypeError {
		t.Fatalf("expected error, got %s", msgType)
	}
	if data.Code != ErrCodeSessionNotFound {
		t.Fatalf("expected code %s, got %s", ErrCodeSessionNotFound, data.Code)
	}
}

// === TC-13: invalid action ===

func TestInvalidAction_ReturnsError(t *testing.T) {
	q := newMockQuerier()
	env := setupTestServer(t, q)
	conn := dialWS(t, env.httpServer.URL)
	_ = readServerMessage(t, conn)

	sendClientMessage(t, conn, ClientMessage{Action: "unknown_action"})
	msgType, data := readServerMessageTyped[ErrorData](t, conn)
	if msgType != MsgTypeError {
		t.Fatalf("expected error, got %s", msgType)
	}
	if data.Code != ErrCodeInvalidAction {
		t.Fatalf("expected code %s, got %s", ErrCodeInvalidAction, data.Code)
	}
}

// === TC-14: invalid JSON ===

func TestInvalidJSON_ReturnsError(t *testing.T) {
	q := newMockQuerier()
	env := setupTestServer(t, q)
	conn := dialWS(t, env.httpServer.URL)
	_ = readServerMessage(t, conn)

	// Send raw non-JSON text
	if err := conn.WriteMessage(websocket.TextMessage, []byte("not json at all")); err != nil {
		t.Fatalf("failed to write: %v", err)
	}

	msgType, data := readServerMessageTyped[ErrorData](t, conn)
	if msgType != MsgTypeError {
		t.Fatalf("expected error, got %s", msgType)
	}
	if data.Code != ErrCodeInvalidJSON {
		t.Fatalf("expected code %s, got %s", ErrCodeInvalidJSON, data.Code)
	}
}

// === TC-17: No clients, dispatch event does not panic ===

func TestDispatchEvent_NoClients_NoError(t *testing.T) {
	q := newMockQuerier(&SessionInfo{ID: "abc-123", Status: SessionStatusActive})
	dispatchCh := make(chan DispatchedEvent, DefaultEventChannelSize)
	ws := NewWebSocketServer(q, dispatchCh, time.Now)

	ctx, cancel := context.WithCancel(context.Background())
	go ws.Run(ctx)
	t.Cleanup(cancel)

	// Send event with no clients connected - should not panic
	dispatchCh <- DispatchedEvent{
		ChangeType: ChangeTypeUpdated,
		Session:    &SessionInfo{ID: "abc-123", Status: SessionStatusActive},
		Timestamp:  time.Now(),
	}

	// Give time for processing
	time.Sleep(100 * time.Millisecond)
	// No panic = success
}

// === TC-35: Run starts and stops via context cancel ===

func TestRun_ContextCancelled_StopsConsuming(t *testing.T) {
	q := newMockQuerier()
	dispatchCh := make(chan DispatchedEvent, DefaultEventChannelSize)
	ws := NewWebSocketServer(q, dispatchCh, time.Now)

	ctx, cancel := context.WithCancel(context.Background())

	done := make(chan struct{})
	go func() {
		ws.Run(ctx)
		close(done)
	}()

	// Let it start
	time.Sleep(50 * time.Millisecond)

	cancel()

	select {
	case <-done:
		// Run returned
	case <-time.After(2 * time.Second):
		t.Fatal("Run did not stop after context cancel")
	}
}

// === TC-36: Run stops when dispatchCh is closed ===

func TestRun_DispatchChClosed_StopsConsuming(t *testing.T) {
	q := newMockQuerier()
	dispatchCh := make(chan DispatchedEvent, DefaultEventChannelSize)
	ws := NewWebSocketServer(q, dispatchCh, time.Now)

	ctx := context.Background()

	done := make(chan struct{})
	go func() {
		ws.Run(ctx)
		close(done)
	}()

	time.Sleep(50 * time.Millisecond)
	close(dispatchCh)

	select {
	case <-done:
		// Run returned
	case <-time.After(2 * time.Second):
		t.Fatal("Run did not stop after dispatchCh close")
	}
}

// === TC-08 (Phase 2): Duplicate subscription is idempotent ===

func TestSubscribeSession_DuplicateSubscription_Idempotent(t *testing.T) {
	q := newMockQuerier(&SessionInfo{ID: "abc-123", Status: SessionStatusActive})
	env := setupTestServer(t, q)
	conn := dialWS(t, env.httpServer.URL)
	_ = readServerMessage(t, conn)

	// Subscribe twice
	sendClientMessage(t, conn, ClientMessage{Action: ActionSubscribeSession, SessionID: "abc-123"})
	sendClientMessage(t, conn, ClientMessage{Action: ActionSubscribeSession, SessionID: "abc-123"})

	// Verify no error by requesting session list
	sendClientMessage(t, conn, ClientMessage{Action: ActionGetSessionList})
	msgType, _ := readServerMessageTyped[SessionListData](t, conn)
	if msgType != MsgTypeSessionList {
		t.Fatalf("expected session_list, got %s", msgType)
	}
}

// === TC-03 (Phase 2): Client disconnect unregistered ===

func TestHandleWS_ClientDisconnect_Unregistered(t *testing.T) {
	q := newMockQuerier()
	env := setupTestServer(t, q)

	conn := dialWS(t, env.httpServer.URL)
	_ = readServerMessage(t, conn) // initial session_list

	time.Sleep(50 * time.Millisecond)
	if count := env.server.clientCount(); count != 1 {
		t.Fatalf("expected 1 client, got %d", count)
	}

	conn.Close()
	// Wait for goroutine cleanup
	time.Sleep(200 * time.Millisecond)
	if count := env.server.clientCount(); count != 0 {
		t.Fatalf("expected 0 clients after disconnect, got %d", count)
	}
}
