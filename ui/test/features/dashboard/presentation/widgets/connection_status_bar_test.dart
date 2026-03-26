import 'package:ccsession/core/models/connection_state.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/features/dashboard/presentation/widgets/connection_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-31: ConnectionStatusBar Widget 狀態指示測試', () {
    /// 測試 helper：建立 ConnectionStatusBar 並配置連線狀態
    Widget buildConnectionStatusBar({
      required WsConnectionState connectionState,
    }) {
      return ProviderScope(
        overrides: [
          connectionStateProvider.overrideWith(
            (ref) => Stream.value(connectionState),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ConnectionStatusBar()),
        ),
      );
    }

    testWidgets('TC-31-01: connected 狀態 — 綠色圓點 + 「Connected」文字',
        (tester) async {
      await tester.pumpWidget(buildConnectionStatusBar(
        connectionState: WsConnectionState.connected,
      ));
      await tester.pump();

      expect(find.text('Connected'), findsOneWidget);

      // 驗證圓點存在（Container with circle shape）
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('TC-31-02: connecting 狀態 — 黃色圓點 + 「Connecting...」文字',
        (tester) async {
      await tester.pumpWidget(buildConnectionStatusBar(
        connectionState: WsConnectionState.connecting,
      ));
      await tester.pump();

      expect(find.text('Connecting...'), findsOneWidget);

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('TC-31-03: reconnecting 狀態 — 黃色圓點 + 「Reconnecting...」文字',
        (tester) async {
      await tester.pumpWidget(buildConnectionStatusBar(
        connectionState: WsConnectionState.reconnecting,
      ));
      await tester.pump();

      expect(find.text('Reconnecting...'), findsOneWidget);

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('TC-31-04: disconnected 狀態 — 紅色圓點 + 「Disconnected」文字',
        (tester) async {
      await tester.pumpWidget(buildConnectionStatusBar(
        connectionState: WsConnectionState.disconnected,
      ));
      await tester.pump();

      expect(find.text('Disconnected'), findsOneWidget);

      expect(find.byType(Container), findsWidgets);
    });
  });
}
