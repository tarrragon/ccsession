package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

// WebSocketServer manages WebSocket client connections and message routing.
type WebSocketServer struct {
	querier    SessionQuerier
	dispatchCh <-chan DispatchedEvent
	clients    map[*Client]struct{}
	mu         sync.RWMutex
	upgrader   websocket.Upgrader
	now        func() time.Time
}

// NewWebSocketServer creates a new WebSocketServer.
// querier provides session data access.
// dispatchCh receives events from EventDispatcher.
// timeProvider injects the clock for testing; nil defaults to time.Now.
func NewWebSocketServer(
	querier SessionQuerier,
	dispatchCh <-chan DispatchedEvent,
	timeProvider func() time.Time,
) *WebSocketServer {
	if timeProvider == nil {
		timeProvider = time.Now
	}
	return &WebSocketServer{
		querier:    querier,
		dispatchCh: dispatchCh,
		clients:    make(map[*Client]struct{}),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool { return true },
		},
		now: timeProvider,
	}
}

// HandleWS is the HTTP handler that upgrades connections to WebSocket.
func (s *WebSocketServer) HandleWS(w http.ResponseWriter, r *http.Request) {
	logger := slog.Default()

	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		logger.Error(LogWSUpgradeFailed, "layer", "ws_server", "error", err)
		return
	}

	client := &Client{
		conn:          conn,
		send:          make(chan []byte, ClientSendBufferSize),
		subscriptions: make(map[string]struct{}),
	}

	s.registerClient(client)
	logger.Info(LogWSClientConnected, "layer", "ws_server", "clientAddr", conn.RemoteAddr().String(), "totalClients", s.clientCount())

	s.sendInitialSessionList(client)

	go s.readPump(client)
	go s.writePump(client)
}

// Run starts the main event consumption loop.
// It blocks until ctx is cancelled or dispatchCh is closed.
func (s *WebSocketServer) Run(ctx context.Context) {
	logger := slog.Default()
	logger.Info(LogWSServerStarted, "layer", "ws_server")

	for {
		select {
		case <-ctx.Done():
			s.closeAllClients()
			logger.Info(LogWSServerStopped, "layer", "ws_server")
			return
		case event, ok := <-s.dispatchCh:
			if !ok {
				logger.Info(LogWSDispatchChClosed, "layer", "ws_server")
				s.closeAllClients()
				return
			}
			s.processDispatchedEvent(event)
		}
	}
}

// clientCount returns the number of connected clients.
func (s *WebSocketServer) clientCount() int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return len(s.clients)
}

func (s *WebSocketServer) registerClient(client *Client) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.clients[client] = struct{}{}
}

func (s *WebSocketServer) unregisterClient(client *Client) {
	logger := slog.Default()

	s.mu.Lock()
	if _, ok := s.clients[client]; ok {
		delete(s.clients, client)
		close(client.send)
	}
	s.mu.Unlock()

	logger.Info(LogWSClientDisconnected, "layer", "ws_server", "totalClients", s.clientCount())
}

func (s *WebSocketServer) closeAllClients() {
	s.mu.Lock()
	defer s.mu.Unlock()
	for client := range s.clients {
		close(client.send)
		delete(s.clients, client)
	}
}

func (s *WebSocketServer) readPump(client *Client) {
	logger := slog.Default()
	defer s.unregisterClient(client)
	defer client.conn.Close()

	client.conn.SetReadLimit(MaxMessageSize)
	client.conn.SetReadDeadline(s.now().Add(PongWaitTimeout))
	client.conn.SetPongHandler(func(string) error {
		client.conn.SetReadDeadline(s.now().Add(PongWaitTimeout))
		return nil
	})

	for {
		_, data, err := client.conn.ReadMessage()
		if err != nil {
			if !websocket.IsCloseError(err, websocket.CloseNormalClosure, websocket.CloseGoingAway) {
				logger.Debug(LogWSReadError, "layer", "ws_server", "error", err)
			}
			return
		}

		var msg ClientMessage
		if err := json.Unmarshal(data, &msg); err != nil {
			logger.Debug(LogWSInvalidJSON, "layer", "ws_server", "error", err)
			s.sendToClient(client, ServerMessage{Type: MsgTypeError, Data: ErrorData{Code: ErrCodeInvalidJSON}})
			continue
		}

		s.routeClientMessage(client, msg)
	}
}

func (s *WebSocketServer) writePump(client *Client) {
	ticker := time.NewTicker(HeartbeatInterval)
	defer ticker.Stop()
	defer client.conn.Close()

	for {
		select {
		case msg, ok := <-client.send:
			if !ok {
				return
			}
			client.conn.SetWriteDeadline(s.now().Add(WriteWaitTimeout))
			if err := client.conn.WriteMessage(websocket.TextMessage, msg); err != nil {
				slog.Default().Debug(LogWSWriteError, "layer", "ws_server", "error", err)
				return
			}
		case <-ticker.C:
			client.conn.SetWriteDeadline(s.now().Add(WriteWaitTimeout))
			if err := client.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				slog.Default().Debug(LogWSWriteError, "layer", "ws_server", "error", err)
				return
			}
		}
	}
}

func (s *WebSocketServer) routeClientMessage(client *Client, msg ClientMessage) {
	switch msg.Action {
	case ActionSubscribeSession:
		s.handleSubscribeSession(client, msg)
	case ActionUnsubscribeSession:
		s.handleUnsubscribeSession(client, msg)
	case ActionGetSessionList:
		s.handleGetSessionList(client)
	case ActionGetSessionHistory:
		s.handleGetSessionHistory(client, msg)
	default:
		slog.Default().Debug(LogWSInvalidAction, "layer", "ws_server", "action", msg.Action)
		s.sendToClient(client, ServerMessage{Type: MsgTypeError, Data: ErrorData{Code: ErrCodeInvalidAction}})
	}
}

func (s *WebSocketServer) handleSubscribeSession(client *Client, msg ClientMessage) {
	logger := slog.Default()

	if msg.SessionID == "" {
		logger.Debug(LogWSInvalidParams, "layer", "ws_server", "reason", "empty sessionId")
		s.sendToClient(client, ServerMessage{Type: MsgTypeError, Data: ErrorData{Code: ErrCodeInvalidParams}})
		return
	}

	if _, ok := s.querier.Get(msg.SessionID); !ok {
		logger.Debug(LogWSSessionNotFound, "layer", "ws_server", "sessionID", msg.SessionID)
		s.sendToClient(client, ServerMessage{Type: MsgTypeError, Data: ErrorData{Code: ErrCodeSessionNotFound}})
		return
	}

	client.mu.Lock()
	client.subscriptions[msg.SessionID] = struct{}{}
	client.mu.Unlock()

	logger.Info(LogWSSubscribed, "layer", "ws_server", "sessionID", msg.SessionID)
}

func (s *WebSocketServer) handleUnsubscribeSession(client *Client, msg ClientMessage) {
	logger := slog.Default()

	client.mu.Lock()
	delete(client.subscriptions, msg.SessionID)
	client.mu.Unlock()

	logger.Info(LogWSUnsubscribed, "layer", "ws_server", "sessionID", msg.SessionID)
}

func (s *WebSocketServer) handleGetSessionList(client *Client) {
	sessions := s.querier.List()
	if sessions == nil {
		sessions = []*SessionInfo{}
	}
	s.sendToClient(client, ServerMessage{
		Type: MsgTypeSessionList,
		Data: SessionListData{Sessions: sessions},
	})
}

func (s *WebSocketServer) handleGetSessionHistory(client *Client, msg ClientMessage) {
	logger := slog.Default()

	if msg.SessionID == "" {
		logger.Debug(LogWSInvalidParams, "layer", "ws_server", "reason", "empty sessionId")
		s.sendToClient(client, ServerMessage{Type: MsgTypeError, Data: ErrorData{Code: ErrCodeInvalidParams}})
		return
	}

	if _, ok := s.querier.Get(msg.SessionID); !ok {
		logger.Debug(LogWSSessionNotFound, "layer", "ws_server", "sessionID", msg.SessionID)
		s.sendToClient(client, ServerMessage{Type: MsgTypeError, Data: ErrorData{Code: ErrCodeSessionNotFound}})
		return
	}

	limit := msg.Limit
	if limit <= 0 {
		limit = DefaultHistoryLimit
	}
	if limit > MaxHistoryLimit {
		limit = MaxHistoryLimit
	}

	var before time.Time
	if msg.Before != "" {
		if t, err := time.Parse(time.RFC3339, msg.Before); err == nil {
			before = t
		}
		// Invalid format: ignore, treat as zero (no filter)
	}

	events, hasMore, err := s.querier.GetHistory(msg.SessionID, limit, before)
	if err != nil {
		s.sendToClient(client, ServerMessage{Type: MsgTypeError, Data: ErrorData{Code: ErrCodeSessionNotFound}})
		return
	}

	if events == nil {
		events = []*SessionEvent{}
	}

	s.sendToClient(client, ServerMessage{
		Type: MsgTypeSessionHistory,
		Data: SessionHistoryData{
			SessionID: msg.SessionID,
			Events:    events,
			HasMore:   hasMore,
		},
	})
	logger.Info(LogWSSessionHistorySent, "layer", "ws_server", "sessionID", msg.SessionID, "count", len(events))
}

func (s *WebSocketServer) sendInitialSessionList(client *Client) {
	sessions := s.querier.List()
	if sessions == nil {
		sessions = []*SessionInfo{}
	}
	s.sendToClient(client, ServerMessage{
		Type: MsgTypeSessionList,
		Data: SessionListData{Sessions: sessions},
	})
}

func (s *WebSocketServer) sendToClient(client *Client, msg ServerMessage) {
	data, err := json.Marshal(msg)
	if err != nil {
		slog.Default().Error("failed to marshal server message", "layer", "ws_server", "error", err)
		return
	}

	select {
	case client.send <- data:
		// success
	default:
		// buffer full - slow consumer
		slog.Default().Warn(LogWSSendBufferFull, "layer", "ws_server")
		s.mu.Lock()
		if _, ok := s.clients[client]; ok {
			delete(s.clients, client)
			close(client.send)
		}
		s.mu.Unlock()
	}
}

// processDispatchedEvent routes a DispatchedEvent to connected clients.
// This is the skeleton for sub-task A; full routing logic is in sub-task B.
func (s *WebSocketServer) processDispatchedEvent(event DispatchedEvent) {
	slog.Default().Debug(LogWSEventDispatched,
		"layer", "ws_server",
		"changeType", event.ChangeType,
		"sessionID", event.Session.ID)

	switch event.ChangeType {
	case ChangeTypeNew:
		s.broadcastSessionList()
		s.pushToSubscribers(event.Session.ID, ServerMessage{
			Type: MsgTypeSessionEvent,
			Data: SessionEventData{
				SessionID: event.Session.ID,
				AgentID:   event.Session.AgentID,
			},
		})
	case ChangeTypeUpdated:
		s.pushToSubscribers(event.Session.ID, ServerMessage{
			Type: MsgTypeSessionEvent,
			Data: SessionEventData{
				SessionID: event.Session.ID,
				AgentID:   event.Session.AgentID,
			},
		})
	case ChangeTypeStatusChanged:
		s.broadcastStatusChange(event.Session.ID, event.Session.Status)
	}
}

func (s *WebSocketServer) broadcastSessionList() {
	sessions := s.querier.List()
	if sessions == nil {
		sessions = []*SessionInfo{}
	}
	msg := ServerMessage{
		Type: MsgTypeSessionList,
		Data: SessionListData{Sessions: sessions},
	}

	s.mu.RLock()
	defer s.mu.RUnlock()
	for client := range s.clients {
		s.sendToClientUnsafe(client, msg)
	}
}

func (s *WebSocketServer) pushToSubscribers(sessionID string, msg ServerMessage) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	for client := range s.clients {
		client.mu.RLock()
		_, subscribed := client.subscriptions[sessionID]
		client.mu.RUnlock()
		if subscribed {
			s.sendToClientUnsafe(client, msg)
		}
	}
}

func (s *WebSocketServer) broadcastStatusChange(sessionID string, status SessionStatus) {
	msg := ServerMessage{
		Type: MsgTypeSessionStatusChange,
		Data: SessionStatusChangeData{
			SessionID: sessionID,
			Status:    status,
		},
	}

	s.mu.RLock()
	defer s.mu.RUnlock()
	for client := range s.clients {
		s.sendToClientUnsafe(client, msg)
	}
}

// sendToClientUnsafe sends a message without acquiring s.mu (caller must hold at least RLock).
func (s *WebSocketServer) sendToClientUnsafe(client *Client, msg ServerMessage) {
	data, err := json.Marshal(msg)
	if err != nil {
		return
	}

	select {
	case client.send <- data:
	default:
		// buffer full - handled by writePump draining
		slog.Default().Warn(LogWSSendBufferFull, "layer", "ws_server")
	}
}
