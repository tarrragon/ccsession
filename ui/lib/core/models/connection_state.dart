/// WebSocket 連線狀態（spec 4.4 連線狀態表）
enum WsConnectionState {
  /// 已建立連線
  connected,

  /// 首次連線中
  connecting,

  /// 已斷線（非預期或手動關閉）
  disconnected,

  /// 斷線後自動重連中
  reconnecting,
}
