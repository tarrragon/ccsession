/// 時間相關常數
abstract final class DurationConstants {
  /// 重連策略（spec 4.4）
  static const reconnectInitialDelay = Duration(seconds: 1);
  static const reconnectMaxDelay = Duration(seconds: 30);
  static const reconnectBackoffMultiplier = 2;

  /// 心跳（對應 Go HeartbeatInterval = 30s）
  static const heartbeatInterval = Duration(seconds: 30);

  /// Pong 超時（對應 Go PongWaitTimeout = 35s）
  static const pongTimeout = Duration(seconds: 35);

  /// 自動捲動動畫時長（ConversationView auto-scroll）
  static const autoScrollDuration = Duration(milliseconds: 200);
}
