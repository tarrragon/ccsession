import 'package:ccsession/core/models/client_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-04: ClientMessage JSON 序列化', () {
    /// TC-04-01: subscribe_session 訊息序列化
    test('subscribe_session 訊息序列化', () {
      const msg = ClientMessage(
        action: 'subscribe_session',
        sessionId: 'session-123',
      );

      final json = msg.toJson();

      expect(json['action'], 'subscribe_session');
      expect(json['sessionId'], 'session-123');
    });

    /// TC-04-02: get_session_history 含 limit 和 before
    test('get_session_history 含 limit 和 before', () {
      const msg = ClientMessage(
        action: 'get_session_history',
        sessionId: 's1',
        limit: 50,
        before: 'cursor-abc',
      );

      final json = msg.toJson();

      expect(json['limit'], 50);
      expect(json['before'], 'cursor-abc');
    });

    /// TC-04-03: 最小參數序列化
    test('最小參數序列化 — @Default 值', () {
      const msg = ClientMessage(action: 'get_session_list');

      final json = msg.toJson();

      expect(json['action'], 'get_session_list');
      expect(json['sessionId'], '');
      expect(json['limit'], 0);
    });

    /// TC-04-04: fromJson 往返
    test('fromJson 往返', () {
      const original = ClientMessage(
        action: 'subscribe_session',
        sessionId: 's1',
        limit: 10,
        before: 'cursor',
      );

      final roundTrip = ClientMessage.fromJson(original.toJson());

      expect(roundTrip, original);
    });
  });
}
