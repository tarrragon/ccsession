import 'package:ccsession/core/models/connection_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-05: WsConnectionState enum', () {
    /// TC-05-01: enum 值完整性
    test('包含且僅包含四個值', () {
      expect(WsConnectionState.values, hasLength(4));
      expect(
        WsConnectionState.values,
        containsAll([
          WsConnectionState.connected,
          WsConnectionState.connecting,
          WsConnectionState.disconnected,
          WsConnectionState.reconnecting,
        ]),
      );
    });
  });
}
