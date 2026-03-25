/// WebSocket 通訊常數，對應 Go Backend websocket_constants.go
abstract final class WebSocketConstants {
  /// Backend WebSocket 端點
  static const defaultHost = 'localhost';
  static const defaultPort = 8765;
  static const wsPath = '/ws';

  /// Client -> Server action 名稱
  static const actionSubscribeSession = 'subscribe_session';
  static const actionUnsubscribeSession = 'unsubscribe_session';
  static const actionGetSessionList = 'get_session_list';
  static const actionGetSessionHistory = 'get_session_history';

  /// Server -> Client message type
  static const msgTypeSessionList = 'session_list';
  static const msgTypeSessionEvent = 'session_event';
  static const msgTypeSessionStatusChange = 'session_status_change';
  static const msgTypeSessionHistory = 'session_history';
  static const msgTypeError = 'error';

  /// Server error codes
  static const errCodeInvalidJson = 'INVALID_JSON';
  static const errCodeInvalidAction = 'INVALID_ACTION';
  static const errCodeInvalidParams = 'INVALID_PARAMS';
  static const errCodeSessionNotFound = 'SESSION_NOT_FOUND';
  static const errCodeInternalError = 'INTERNAL_ERROR';

  /// 歷史事件限制
  static const defaultHistoryLimit = 100;
  static const maxHistoryLimit = 1000;
}
