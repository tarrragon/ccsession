package main

// WebSocket server log messages
const (
	LogWSServerStarted       = "websocket server started"
	LogWSServerStopped       = "websocket server stopped"
	LogWSClientConnected     = "websocket client connected"
	LogWSClientDisconnected  = "websocket client disconnected"
	LogWSUpgradeFailed       = "websocket upgrade failed"
	LogWSReadError           = "websocket read error"
	LogWSWriteError          = "websocket write error"
	LogWSInvalidJSON         = "invalid JSON from client"
	LogWSInvalidAction       = "unknown client action"
	LogWSSubscribed          = "client subscribed to session"
	LogWSUnsubscribed        = "client unsubscribed from session"
	LogWSSessionListSent     = "session list sent to client"
	LogWSSessionHistorySent  = "session history sent to client"
	LogWSSendBufferFull      = "client send buffer full, closing connection"
	LogWSDispatchChClosed    = "dispatch channel closed"
	LogWSEventDispatched     = "dispatched event processed"
	LogWSInvalidParams       = "invalid parameters from client"
	LogWSSessionNotFound      = "session not found"
	LogWSMarshalFailed        = "failed to marshal server message"
	LogWSInvalidBeforeFormat  = "invalid before timestamp format, ignoring filter"
	LogWSSubscriptionLimitReached = "client subscription limit reached, rejecting subscribe"
)
