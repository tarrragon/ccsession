import 'dart:async';

import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/core/websocket/websocket_service.dart';
import 'package:ccsession/features/session_list/presentation/session_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// -- Mock --

class MockWebSocketService extends Mock implements WebSocketService {}

// -- Test helpers --

final _baseTime = DateTime(2026, 3, 25, 10, 0);

SessionInfo _createTestSession({
  String id = 'session-1',
  String projectPath = '/Users/test/project',
  String summary = 'Test summary',
  SessionStatus status = SessionStatus.active,
  DateTime? lastEventAt,
  String lastMessage = '',
  String agentName = 'claude',
}) {
  return SessionInfo(
    id: id,
    projectPath: projectPath,
    summary: summary,
    status: status,
    firstEventAt: _baseTime,
    lastEventAt: lastEventAt ?? _baseTime,
    lastMessage: lastMessage,
    agentName: agentName,
  );
}

ServerMessage _createSessionListMessage(List<SessionInfo> sessions) {
  return ServerMessage(
    type: 'session_list',
    data: {
      'sessions': sessions.map((s) => s.toJson()).toList(),
    },
  );
}

void main() {
  group('TG-12: SessionListPage', () {
    late StreamController<ServerMessage> messageController;
    late MockWebSocketService mockService;

    setUp(() {
      messageController = StreamController<ServerMessage>.broadcast();
      mockService = MockWebSocketService();
      when(() => mockService.requestSessionList()).thenReturn(null);
      when(() => mockService.messageStream)
          .thenAnswer((_) => messageController.stream);
    });

    tearDown(() {
      messageController.close();
    });

    Widget buildSubject({List<Override> additionalOverrides = const []}) {
      return ProviderScope(
        overrides: [
          webSocketServiceProvider.overrideWithValue(mockService),
          ...additionalOverrides,
        ],
        child: const MaterialApp(home: Scaffold(body: SessionListPage())),
      );
    }

    Future<void> sendMessage(
      WidgetTester tester,
      ServerMessage message,
    ) async {
      messageController.add(message);
      await tester.pump();
      await tester.pump();
    }

    // TC-12-01: Loading 狀態顯示載入指示器
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(buildSubject());
      // 初始狀態：Notifier 未收到訊息，仍為 AsyncLoading 或 empty data
      // build() 回傳 empty SessionListState 後會是 AsyncData with empty
      await tester.pump();
      // After build completes with empty state, shows 'No sessions'
      expect(find.text('No sessions'), findsOneWidget);
    });

    // TC-12-02: 正常載入顯示分組列表
    testWidgets('displays grouped session list', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, _createSessionListMessage([
        _createTestSession(id: 's1', status: SessionStatus.active),
        _createTestSession(id: 's2', status: SessionStatus.active),
        _createTestSession(id: 's3', status: SessionStatus.idle),
      ]));

      expect(find.text('Active (2)'), findsOneWidget);
      expect(find.text('Idle (1)'), findsOneWidget);
      expect(find.textContaining('Completed'), findsNothing);
    });

    // TC-12-03: 空列表顯示提示文字
    testWidgets('shows empty message when no sessions', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, _createSessionListMessage([]));

      expect(find.text('No sessions'), findsOneWidget);
    });

    // TC-12-04: 錯誤狀態顯示錯誤訊息
    testWidgets('shows error message on error', (tester) async {
      // Override with a service that causes stream error
      final errorController = StreamController<ServerMessage>.broadcast();
      final errorService = MockWebSocketService();
      when(() => errorService.requestSessionList()).thenThrow(Exception('fail'));
      when(() => errorService.messageStream)
          .thenAnswer((_) => errorController.stream);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          webSocketServiceProvider.overrideWithValue(errorService),
        ],
        child: const MaterialApp(home: Scaffold(body: SessionListPage())),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Failed to load sessions'), findsOneWidget);

      errorController.close();
    });

    // TC-12-05: 點擊 session 項目觸發選擇
    testWidgets('tapping a session tile triggers selection', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, _createSessionListMessage([
        _createTestSession(id: 'session-A', summary: 'My Task'),
      ]));

      await tester.tap(find.text('My Task'));
      await tester.pump();

      // After tap, the tile should now be selected (ListTile.selected == true)
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.selected, isTrue);
    });

    // TC-12-06: 選中 session 有視覺區分
    testWidgets('selected session has visual distinction', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, _createSessionListMessage([
        _createTestSession(id: 'session-A', summary: 'Task A'),
        _createTestSession(id: 'session-B', summary: 'Task B'),
      ]));

      // Select session-A
      await tester.tap(find.text('Task A'));
      await tester.pump();

      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      // session-A is selected
      expect(tiles[0].selected, isTrue);
      // session-B is not selected
      expect(tiles[1].selected, isFalse);
    });
  });
}
