import 'dart:async';

import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/core/websocket/websocket_service.dart';
import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_session_factory.dart';

// -- Mock --

class MockWebSocketService extends Mock implements WebSocketService {}

// -- Test helpers --

ServerMessage _createStatusChangeMessage(
  String sessionId,
  SessionStatus newStatus,
) {
  return ServerMessage(
    type: 'session_status_change',
    data: {
      'sessionId': sessionId,
      'status': newStatus.name,
    },
  );
}

/// 等待 async 完成
Future<void> _pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  group('TG-10: SessionListNotifier', () {
    late ProviderContainer container;
    late StreamController<ServerMessage> messageController;
    late MockWebSocketService mockService;

    setUp(() {
      messageController = StreamController<ServerMessage>.broadcast();
      mockService = MockWebSocketService();
      when(() => mockService.requestSessionList()).thenReturn(null);
      when(() => mockService.messageStream)
          .thenAnswer((_) => messageController.stream);

      container = ProviderContainer(
        overrides: [
          webSocketServiceProvider.overrideWithValue(mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      messageController.close();
    });

    /// 初始化 notifier：建立 listener 以保持 provider 活躍，等待 build 完成
    Future<void> initNotifier() async {
      container.listen(sessionListNotifierProvider, (_, __) {});
      await _pump();
    }

    /// 傳送訊息並等待處理完成
    Future<void> sendMessage(ServerMessage message) async {
      messageController.add(message);
      await _pump();
    }

    // TC-10-01: 初始載入 — 成功
    test('loads session list from session_list message', () async {
      await initNotifier();

      final sessions = [
        createTestSession(id: 's1', status: SessionStatus.active),
        createTestSession(id: 's2', status: SessionStatus.idle),
        createTestSession(id: 's3', status: SessionStatus.completed),
      ];
      await sendMessage(createSessionListMessage(sessions));

      final state = container.read(sessionListNotifierProvider).valueOrNull;
      expect(state, isNotNull);
      expect(state!.sessions.length, equals(3));

      final notifier =
          container.read(sessionListNotifierProvider.notifier);
      final grouped = notifier.groupedSessions;
      expect(grouped.keys.length, equals(3));
      expect(grouped.containsKey(SessionStatus.active), isTrue);
      expect(grouped.containsKey(SessionStatus.idle), isTrue);
      expect(grouped.containsKey(SessionStatus.completed), isTrue);
    });

    // TC-10-02: 初始載入 — 空列表
    test('handles empty session list', () async {
      await initNotifier();
      await sendMessage(createSessionListMessage([]));

      final state = container.read(sessionListNotifierProvider).valueOrNull;
      expect(state, isNotNull);
      expect(state!.sessions, isEmpty);

      final notifier =
          container.read(sessionListNotifierProvider.notifier);
      expect(notifier.groupedSessions, isEmpty);
    });

    // TC-10-03: 即時狀態更新 — session 從 active 變 idle
    test('updates session status on session_status_change', () async {
      await initNotifier();

      await sendMessage(createSessionListMessage([
        createTestSession(id: 'session-A', status: SessionStatus.active),
        createTestSession(id: 'session-B', status: SessionStatus.idle),
      ]));

      final notifier =
          container.read(sessionListNotifierProvider.notifier);
      expect(
        notifier.groupedSessions[SessionStatus.active]
            ?.any((s) => s.id == 'session-A'),
        isTrue,
      );

      await sendMessage(
        _createStatusChangeMessage('session-A', SessionStatus.idle),
      );

      final grouped = notifier.groupedSessions;
      expect(
        grouped[SessionStatus.active]?.any((s) => s.id == 'session-A'),
        isNot(isTrue),
      );
      expect(
        grouped[SessionStatus.idle]?.any((s) => s.id == 'session-A'),
        isTrue,
      );
      final sessionA = container
          .read(sessionListNotifierProvider)
          .valueOrNull!
          .sessions
          .firstWhere((s) => s.id == 'session-A');
      expect(sessionA.status, equals(SessionStatus.idle));
    });

    // TC-10-04: 選擇 session
    test('selectSession updates selectedSessionId', () async {
      await initNotifier();
      await sendMessage(createSessionListMessage([
        createTestSession(id: 'session-A'),
      ]));

      expect(
        container.read(sessionListNotifierProvider).valueOrNull!
            .selectedSessionId,
        isNull,
      );

      container
          .read(sessionListNotifierProvider.notifier)
          .selectSession('session-A');

      expect(
        container.read(sessionListNotifierProvider).valueOrNull!
            .selectedSessionId,
        equals('session-A'),
      );
    });

    // TC-10-05: 切換選擇 session
    test('switching selection updates selectedSessionId', () async {
      await initNotifier();
      await sendMessage(createSessionListMessage([
        createTestSession(id: 'session-A'),
        createTestSession(id: 'session-B'),
      ]));

      final notifier =
          container.read(sessionListNotifierProvider.notifier);
      notifier.selectSession('session-A');
      expect(
        container.read(sessionListNotifierProvider).valueOrNull!
            .selectedSessionId,
        equals('session-A'),
      );

      notifier.selectSession('session-B');
      expect(
        container.read(sessionListNotifierProvider).valueOrNull!
            .selectedSessionId,
        equals('session-B'),
      );
    });

    // TC-10-06: 分組排序
    test('groupedSessions has fixed key order and sorts by lastEventAt desc',
        () async {
      await initNotifier();

      await sendMessage(createSessionListMessage([
        createTestSession(
          id: 'session-1',
          status: SessionStatus.active,
          lastEventAt: baseTime.add(const Duration(hours: 3)),
        ),
        createTestSession(
          id: 'session-2',
          status: SessionStatus.active,
          lastEventAt: baseTime.add(const Duration(hours: 1)),
        ),
        createTestSession(
          id: 'session-3',
          status: SessionStatus.idle,
          lastEventAt: baseTime.add(const Duration(hours: 2)),
        ),
        createTestSession(
          id: 'session-4',
          status: SessionStatus.completed,
          lastEventAt: baseTime,
        ),
      ]));

      final notifier =
          container.read(sessionListNotifierProvider.notifier);
      final grouped = notifier.groupedSessions;

      expect(
        grouped.keys.toList(),
        equals([
          SessionStatus.active,
          SessionStatus.idle,
          SessionStatus.completed,
        ]),
      );

      final activeGroup = grouped[SessionStatus.active]!;
      expect(activeGroup[0].id, equals('session-1'));
      expect(activeGroup[1].id, equals('session-2'));
    });

    // TC-10-07: 未知 sessionId 狀態變更 — 靜默忽略
    test('ignores status change for unknown sessionId', () async {
      await initNotifier();
      await sendMessage(createSessionListMessage([
        createTestSession(id: 'session-A'),
      ]));

      final stateBefore =
          container.read(sessionListNotifierProvider).valueOrNull!;
      expect(
        stateBefore.sessions.any((s) => s.id == 'unknown-id'),
        isFalse,
      );

      await sendMessage(
        _createStatusChangeMessage('unknown-id', SessionStatus.completed),
      );

      final stateAfter =
          container.read(sessionListNotifierProvider).valueOrNull!;
      expect(stateAfter.sessions.length, equals(stateBefore.sessions.length));
    });

    // TC-10-08: session_list 訊息替換整個列表
    test('session_list message replaces entire list', () async {
      await initNotifier();

      await sendMessage(createSessionListMessage([
        createTestSession(id: 's1'),
        createTestSession(id: 's2'),
      ]));
      expect(
        container.read(sessionListNotifierProvider).valueOrNull!
            .sessions.length,
        equals(2),
      );

      await sendMessage(createSessionListMessage([
        createTestSession(id: 's3'),
        createTestSession(id: 's4'),
        createTestSession(id: 's5'),
        createTestSession(id: 's6'),
        createTestSession(id: 's7'),
      ]));
      expect(
        container.read(sessionListNotifierProvider).valueOrNull!
            .sessions.length,
        equals(5),
      );
    });

    // TC-10-09: 空分組不出現在 groupedSessions
    test('empty groups are excluded from groupedSessions', () async {
      await initNotifier();
      await sendMessage(createSessionListMessage([
        createTestSession(id: 's1', status: SessionStatus.active),
        createTestSession(id: 's2', status: SessionStatus.active),
      ]));

      final notifier =
          container.read(sessionListNotifierProvider.notifier);
      final grouped = notifier.groupedSessions;

      expect(grouped.keys, contains(SessionStatus.active));
      expect(grouped.keys, isNot(contains(SessionStatus.idle)));
      expect(grouped.keys, isNot(contains(SessionStatus.completed)));
    });

    // TC-10-10: 斷線重連後重新請求列表
    test('requests session list on build (simulating reconnect)', () async {
      await initNotifier();
      verify(() => mockService.requestSessionList()).called(1);

      // 模擬重連：invalidate provider 觸發重新 build
      container.invalidate(sessionListNotifierProvider);
      await _pump();
      verify(() => mockService.requestSessionList()).called(1);
    });
  });
}
