import 'dart:math' as math;

import 'package:ccsession/core/constants/duration_constants.dart';

/// 需求：指數退避重連策略（spec 4.4）
/// 序列：1s -> 2s -> 4s -> 8s -> 16s -> 30s -> 30s -> ...
class ReconnectStrategy {
  int _attempt = 0;

  /// 計算下一次重連延遲（呼叫後內部遞增）
  Duration nextDelay() {
    final delaySeconds = DurationConstants.reconnectInitialDelay.inSeconds *
        math.pow(
          DurationConstants.reconnectBackoffMultiplier,
          _attempt,
        ).toInt();
    _attempt++;
    return Duration(
      seconds: math.min(
        delaySeconds,
        DurationConstants.reconnectMaxDelay.inSeconds,
      ),
    );
  }

  /// 當前延遲時間（不遞增）
  Duration get currentDelay {
    final delaySeconds = DurationConstants.reconnectInitialDelay.inSeconds *
        math.pow(
          DurationConstants.reconnectBackoffMultiplier,
          _attempt,
        ).toInt();
    return Duration(
      seconds: math.min(
        delaySeconds,
        DurationConstants.reconnectMaxDelay.inSeconds,
      ),
    );
  }

  /// 重置延遲到初始值（連線成功後呼叫）
  void reset() {
    _attempt = 0;
  }
}
