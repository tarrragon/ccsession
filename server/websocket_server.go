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
		done:          make(chan struct{}),
		subscriptions: make(map[string]struct{}),
	}

	s.registerClient(client)
	logger.Info(LogWSClientConnected, "layer", "ws_server", "clientAddr", conn.RemoteAddr().String(), "totalClients", s.clientCount())

	s.handleGetSessionList(client)

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
	var remaining int
	if _, ok := s.clients[client]; ok {
		delete(s.clients, client)
		client.closeOnce.Do(func() { close(client.send) })
	}
	remaining = len(s.clients)
	s.mu.Unlock()

	logger.Info(LogWSClientDisconnected, "layer", "ws_server", "totalClients", remaining)
}

func (s *WebSocketServer) closeAllClients() {
	s.mu.Lock()
	defer s.mu.Unlock()
	for client := range s.clients {
		client.closeOnce.Do(func() { close(client.send) })
		delete(s.clients, client)
	}
}

func (s *WebSocketServer) readPump(client *Client) {
	logger := slog.Default()
	defer s.unregisterClient(client)
	defer client.conn.Close()
	defer close(client.done)

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

	for {
		select {
		case msg, ok := <-client.send:
			if !ok {
				return
			}
			client.sendBytes.Add(-int64(len(msg)))
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
		case <-client.done:
			return
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
	if _, exists := client.subscriptions[msg.SessionID]; exists {
		client.mu.Unlock()
		logger.Debug(LogWSSubscribed, "layer", "ws_server", "sessionID", msg.SessionID, "note", "already subscribed")
		return
	}
	if len(client.subscriptions) >= MaxSubscriptionsPerClient {
		client.mu.Unlock()
		logger.Warn(LogWSSubscriptionLimitReached,
			"layer", "ws_server",
			"sessionID", msg.SessionID,
			"limit", MaxSubscriptionsPerClient)
		s.sendToClient(client, ServerMessage{Type: MsgTypeError, Data: ErrorData{Code: ErrCodeSubscriptionLimit}})
		return
	}
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
		} else {
			logger.Debug(LogWSInvalidBeforeFormat, "layer", "ws_server", "before", msg.Before, "error", err)
		}
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

// marshalMessage serialises a ServerMessage to JSON bytes.
func marshalMessage(msg ServerMessage) ([]byte, error) {
	return json.Marshal(msg)
}

// enqueueUnsafe attempts a non-blocking send on client.send.
// Caller must hold at least s.mu.RLock; it never closes the channel.
// Returns true if the message was enqueued, false if dropped (buffer full or memory limit exceeded).
// 需求：[0.4.0-W2-001.1] 基於記憶體大小的 send buffer 限制。
// 需求：[0.4.0-W4-009] 統一記憶體超限判定邏輯，sendToClient 委派至此函式。
func enqueueUnsafe(client *Client, data []byte) bool {
	msgSize := int64(len(data))

	// 需求：[0.4.0-W5-008] Load 結果存入區域變數，檢查和 log 共用同一值
	queuedBytes := client.sendBytes.Load()

	// 檢查記憶體上限：若當前已排隊的 bytes + 新訊息超過上限，丟棄新訊息
	if queuedBytes+msgSize > ClientSendBufferMaxBytes {
		slog.Default().Warn(LogWSSendBufferBytesExceeded,
			"layer", "ws_server",
			"queuedBytes", queuedBytes,
			"msgBytes", msgSize,
			"limit", ClientSendBufferMaxBytes)
		return false
	}

	select {
	case client.send <- data:
		client.sendBytes.Add(msgSize)
		return true
	default:
		slog.Default().Warn(LogWSSendBufferFull, "layer", "ws_server")
		return false
	}
}

// sendToClient marshals and enqueues a message for the client.
// On enqueue failure (memory limit or buffer full), the client is disconnected
// because missing incremental updates would leave the client in an inconsistent state.
// 需求：[0.4.0-W4-009] 委派至 enqueueUnsafe，統一超限判定邏輯。
func (s *WebSocketServer) sendToClient(client *Client, msg ServerMessage) {
	data, err := marshalMessage(msg)
	if err != nil {
		slog.Default().Error(LogWSMarshalFailed, "layer", "ws_server", "error", err)
		return
	}

	if !enqueueUnsafe(client, data) {
		s.disconnectClient(client)
	}
}

// disconnectClient removes a client from the server and closes its send channel.
func (s *WebSocketServer) disconnectClient(client *Client) {
	s.mu.Lock()
	if _, ok := s.clients[client]; ok {
		delete(s.clients, client)
		client.closeOnce.Do(func() { close(client.send) })
	}
	s.mu.Unlock()
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
		// 需求：[0.4.0-W2-001.1] 增量廣播新 session，取代全量 session_list。
		s.broadcastSessionUpdate(event.Session)
		s.pushToSubscribers(event.Session.ID, ServerMessage{
			Type: MsgTypeSessionEvent,
			Data: buildSessionEventPayload(event),
		})
	case ChangeTypeUpdated:
		s.pushToSubscribers(event.Session.ID, ServerMessage{
			Type: MsgTypeSessionEvent,
			Data: buildSessionEventPayload(event),
		})
	case ChangeTypeStatusChanged:
		// 需求：[0.2.1-W4-010] status 變更時同時推送完整 session_update，
		// 確保前端取得 summary 等可能同時變動的欄位。
		// session_status_change 保留向後相容，供輕量消費端使用。
		s.broadcastSessionUpdate(event.Session)
		s.broadcastStatusChange(event.Session.ID, event.Session.Status, event.Session.LastEventAt)
		if event.Event != nil {
			s.pushToSubscribers(event.Session.ID, ServerMessage{
				Type: MsgTypeSessionEvent,
				Data: buildSessionEventPayload(event),
			})
		}
	}
}

// buildSessionEventPayload 根據 DispatchedEvent 建構 session_event 的 data 欄位。
// 若 Event 不為 nil（JSONL 事件場景），回傳完整 SessionEvent 供前端解析。
// 若 Event 為 nil（Hook 場景），回傳 SessionEventData 作為 fallback。
func buildSessionEventPayload(event DispatchedEvent) any {
	if event.Event != nil {
		return event.Event
	}
	return SessionEventData{
		SessionID: event.Session.ID,
		AgentID:   event.Session.AgentID,
	}
}

// broadcastSessionUpdate sends an incremental session_update to all clients.
// 需求：[0.4.0-W2-001.1] 增量差異廣播，只推送變更的 session。
func (s *WebSocketServer) broadcastSessionUpdate(session *SessionInfo) {
	data, err := marshalMessage(ServerMessage{
		Type: MsgTypeSessionUpdate,
		Data: SessionUpdateData{Session: session},
	})
	if err != nil {
		return
	}

	s.mu.RLock()
	defer s.mu.RUnlock()
	for client := range s.clients {
		enqueueUnsafe(client, data)
	}
}

func (s *WebSocketServer) pushToSubscribers(sessionID string, msg ServerMessage) {
	data, err := marshalMessage(msg)
	if err != nil {
		return
	}

	s.mu.RLock()
	defer s.mu.RUnlock()
	for client := range s.clients {
		client.mu.RLock()
		_, subscribed := client.subscriptions[sessionID]
		client.mu.RUnlock()
		if subscribed {
			enqueueUnsafe(client, data)
		}
	}
}

func (s *WebSocketServer) broadcastStatusChange(sessionID string, status SessionStatus, lastEventAt time.Time) {
	data, err := marshalMessage(ServerMessage{
		Type: MsgTypeSessionStatusChange,
		Data: SessionStatusChangeData{
			SessionID:   sessionID,
			Status:      status,
			LastEventAt: lastEventAt,
		},
	})
	if err != nil {
		return
	}

	s.mu.RLock()
	defer s.mu.RUnlock()
	for client := range s.clients {
		enqueueUnsafe(client, data)
	}
}
