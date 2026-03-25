import 'package:ccsession/core/websocket/reconnect_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-06: ReconnectStrategy 指數退避', () {
    late ReconnectStrategy strategy;

    setUp(() {
      strategy = ReconnectStrategy();
    });

    /// TC-06-01: 初始延遲為 1 秒
    test('初始延遲為 1 秒', () {
      expect(strategy.currentDelay, isNotNull);

      final delay = strategy.nextDelay();

      expect(delay, const Duration(seconds: 1));
    });

    /// TC-06-02: 指數退避序列正確
    test('指數退避序列正確', () {
      final expectedSeconds = [1, 2, 4, 8, 16, 30];

      for (final expected in expectedSeconds) {
        expect(strategy.nextDelay(), Duration(seconds: expected));
      }
    });

    /// TC-06-03: 延遲觸頂不超過 30 秒
    test('延遲觸頂不超過 30 秒', () {
      // 先呼叫 6 次到觸頂
      for (var i = 0; i < 6; i++) {
        strategy.nextDelay();
      }
      expect(strategy.currentDelay, const Duration(seconds: 30));

      // 再呼叫 3 次仍為 30s
      for (var i = 0; i < 3; i++) {
        expect(strategy.nextDelay(), const Duration(seconds: 30));
      }
    });

    /// TC-06-04: reset 後延遲回到初始值
    test('reset 後延遲回到初始值', () {
      // 遞增幾次
      strategy.nextDelay();
      strategy.nextDelay();
      strategy.nextDelay();
      // 前置驗證：當前延遲 > 1s
      expect(strategy.currentDelay.inSeconds, greaterThan(1));

      strategy.reset();

      expect(strategy.nextDelay(), const Duration(seconds: 1));
    });

    /// TC-06-05: reset 後可再次完整遞增
    test('reset 後可再次完整遞增', () {
      // 呼叫 5 次後 reset
      for (var i = 0; i < 5; i++) {
        strategy.nextDelay();
      }
      strategy.reset();

      expect(strategy.nextDelay(), const Duration(seconds: 1));
      expect(strategy.nextDelay(), const Duration(seconds: 2));
      expect(strategy.nextDelay(), const Duration(seconds: 4));
    });
  });
}
