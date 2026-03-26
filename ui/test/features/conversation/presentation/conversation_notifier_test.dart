import 'dart:async';

import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/core/websocket/websocket_service.dart';
import 'package:ccsession/features/conversation/presentation/conversation_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_conversation_factory.dart';

class MockWebSocketService extends Mock implements WebSocketService {}

Future<void> _pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  group('TG-20: ConversationNotifier', () {
    late ProviderContainer container;
    late StreamController<ServerMessage> messageController;
    late MockWebSocketService mockService;

    setUp(() {
      messageController = StreamController<ServerMessage>.broadcast();
      mockService = MockWebSocketService();
      when(() => mockService.messageStream)
          .thenAnswer((_) => messageController.stream);
      when(() => mockService.requestSessionHistory(any(),
          limit: any(named: 'limit'),
          before: any(named: 'before'))).thenReturn(null);
      when(() => mockService.subscribeSession(any())).thenReturn(null);
      when(() => mockService.unsubscribeSession(any())).thenReturn(null);

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

    Future<void> initNotifier() async {
      container.listen(conversationNotifierProvider, (_, __) {});
      await _pump();
    }

    Future<void> sendMessage(ServerMessage message) async {
      messageController.add(message);
      await _pump();
    }

    ConversationState getState() {
      return container
          .read(conversationNotifierProvider)
          .requireValue;
    }

    // TC-20-01: 載入 session 歷史 — 成功
    test('loads session history successfully', () async {
      await initNotifier();
      expect(getState().events, isEmpty);

      container.read(conversationNotifierProvider.notifier).loadSession('session-1');
      await _pump();
      expect(getState().isLoadingHistory, isTrue);

      final events = [
        createUserEvent('hello', sessionId: 'session-1'),
        createAssistantEvent('hi', sessionId: 'session-1'),
        createToolUseEvent('Read', sessionId: 'session-1'),
      ];
      await sendMessage(
        createSessionHistoryMessage('session-1', events),
      );

      final state = getState();
      expect(state.events.length, 3);
      expect(state.sessionId, 'session-1');
      expect(state.hasMore, isFalse);
      expect(state.isLoadingHistory, isFalse);
    });

    // TC-20-02: 載入 session 歷史 — 空 session
    test('handles empty session history', () async {
      await initNotifier();

      container.read(conversationNotifierProvider.notifier).loadSession('empty-session');
      await sendMessage(
        createSessionHistoryMessage('empty-session', []),
      );

      final state = getState();
      expect(state.events, isEmpty);
      expect(state.sessionId, 'empty-session');
      expect(state.isLoadingHistory, isFalse);
      expect(state.hasMore, isFalse);
    });

    // TC-20-03: 載入 session 歷史 — 有更多分頁
    test('sets hasMore when more history available', () async {
      await initNotifier();

      container.read(conversationNotifierProvider.notifier).loadSession('session-1');
      final events = List.generate(
        100,
        (i) => createUserEvent('msg $i', sessionId: 'session-1'),
      );
      await sendMessage(
        createSessionHistoryMessage('session-1', events, hasMore: true),
      );

      final state = getState();
      expect(state.events.length, 100);
      expect(state.hasMore, isTrue);
    });

    // TC-20-04: 載入更多歷史 — 分頁 prepend
    test('prepends older events on loadMoreHistory', () async {
      await initNotifier();

      container.read(conversationNotifierProvider.notifier).loadSession('session-1');
      final initialEvents = [
        createUserEvent('msg-3', sessionId: 'session-1'),
        createUserEvent('msg-4', sessionId: 'session-1'),
        createUserEvent('msg-5', sessionId: 'session-1'),
      ];
      await sendMessage(
        createSessionHistoryMessage('session-1', initialEvents, hasMore: true),
      );
      expect(getState().events.length, 3);
      expect(getState().hasMore, isTrue);

      container.read(conversationNotifierProvider.notifier).loadMoreHistory();
      await _pump();

      final olderEvents = [
        createUserEvent('msg-1', sessionId: 'session-1'),
        createUserEvent('msg-2', sessionId: 'session-1'),
      ];
      await sendMessage(
        createSessionHistoryMessage('session-1', olderEvents),
      );

      final state = getState();
      expect(state.events.length, 5);
      expect(state.events[0].content.text, 'msg-1');
      expect(state.events[4].content.text, 'msg-5');
      expect(state.hasMore, isFalse);
    });

    // TC-20-05: 載入更多歷史 — hasMore 為 false 時忽略
    test('ignores loadMoreHistory when hasMore is false', () async {
      await initNotifier();

      container.read(conversationNotifierProvider.notifier).loadSession('session-1');
      await sendMessage(
        createSessionHistoryMessage('session-1', [createUserEvent('a', sessionId: 'session-1')]),
      );
      expect(getState().hasMore, isFalse);

      // Reset call count after loadSession
      clearInteractions(mockService);
      when(() => mockService.messageStream)
          .thenAnswer((_) => messageController.stream);

      container.read(conversationNotifierProvider.notifier).loadMoreHistory();
      await _pump();

      verifyNever(() => mockService.requestSessionHistory(
            any(),
            limit: any(named: 'limit'),
            before: any(named: 'before'),
          ));
    });

    // TC-20-06: 載入更多歷史 — 正在載入時忽略
    test('ignores loadMoreHistory when already loading', () async {
      await initNotifier();

      container.read(conversationNotifierProvider.notifier).loadSession('session-1');
      final events = [createUserEvent('a', sessionId: 'session-1')];
      await sendMessage(
        createSessionHistoryMessage('session-1', events, hasMore: true),
      );

      // First loadMore
      container.read(conversationNotifierProvider.notifier).loadMoreHistory();
      await _pump();
      expect(getState().isLoadingHistory, isTrue);

      clearInteractions(mockService);
      when(() => mockService.messageStream)
          .thenAnswer((_) => messageController.stream);

      // Second loadMore while still loading - should be ignored
      container.read(conversationNotifierProvider.notifier).loadMoreHistory();
      await _pump();

      verifyNever(() => mockService.requestSessionHistory(
            any(),
            limit: any(named: 'limit'),
            before: any(named: 'before'),
          ));
    });

    // TC-20-07: 即時事件接收 — sessionId 匹配
    test('appends matching session events', () async {
      await initNotifier();

      container.read(conversationNotifierProvider.notifier).loadSession('session-1');
      final events = [
        createUserEvent('hello', sessionId: 'session-1'),
        createAssistantEvent('hi', sessionId: 'session-1'),
      ];
      await sendMessage(
        createSessionHistoryMessage('session-1', events),
      );
      expect(getState().events.length, 2);

      final newEvent = createAssistantEvent('hello back', sessionId: 'session-1');
      await sendMessage(createSessionEventMessage(newEvent));

      final state = getState();
      expect(state.events.length, 3);
      expect(state.events.last.type, 'assistant');
      expect(state.events.last.content.text, 'hello back');
    });

    // TC-20-08: 即時事件接收 — sessionId 不匹配則忽略
    test('ignores events from other sessions', () async {
      await initNotifier();

      container.read(conversationNotifierProvider.notifier).loadSession('session-1');
      final events = [
        createUserEvent('hello', sessionId: 'session-1'),
        createAssistantEvent('hi', sessionId: 'session-1'),
      ];
      await sendMessage(
        createSessionHistoryMessage('session-1', events),
      );
      expect(getState().events.length, 2);

      final otherEvent = createUserEvent('other', sessionId: 'session-other');
      await sendMessage(createSessionEventMessage(otherEvent));

      expect(getState().events.length, 2);
    });

    // TC-20-09: 即時事件接收 — 格式異常容錯
    test('handles malformed session_event gracefully', () async {
      await initNotifier();

      container.read(conversationNotifierProvider.notifier).loadSession('session-1');
      final events = [
        createUserEvent('hello', sessionId: 'session-1'),
        createAssistantEvent('hi', sessionId: 'session-1'),
      ];
      await sendMessage(
        createSessionHistoryMessage('session-1', events),
      );
      expect(getState().events.length, 2);

      // Send malformed event
      await sendMessage(const ServerMessage(
        type: 'session_event',
        data: {'bad': 'data'},
      ));
      expect(getState().events.length, 2);

      // Subsequent valid events still work
      final validEvent = createAssistantEvent('still works', sessionId: 'session-1');
      await sendMessage(createSessionEventMessage(validEvent));
      expect(getState().events.length, 3);
    });

    // TC-20-10: 切換 session — 正確清理和重新載入
    test('cleans up and reloads on session switch', () async {
      await initNotifier();

      container.read(conversationNotifierProvider.notifier).loadSession('session-A');
      final eventsA = [
        createUserEvent('a1', sessionId: 'session-A'),
        createAssistantEvent('a2', sessionId: 'session-A'),
        createToolUseEvent('Read', sessionId: 'session-A'),
      ];
      await sendMessage(
        createSessionHistoryMessage('session-A', eventsA),
      );
      expect(getState().sessionId, 'session-A');

      container.read(conversationNotifierProvider.notifier).loadSession('session-B');
      verify(() => mockService.unsubscribeSession('session-A')).called(1);

      // Events should be cleared before new history arrives
      expect(getState().events, isEmpty);

      final eventsB = [
        createUserEvent('b1', sessionId: 'session-B'),
      ];
      await sendMessage(
        createSessionHistoryMessage('session-B', eventsB),
      );

      expect(getState().sessionId, 'session-B');
      expect(getState().events.length, 1);
      expect(getState().events.first.content.text, 'b1');
    });

    // TC-20-11: 切換 session — 前 session 事件不再處理
    test('ignores events from previous session after switch', () async {
      await initNotifier();

      container.read(conversationNotifierProvider.notifier).loadSession('session-A');
      await sendMessage(
        createSessionHistoryMessage('session-A', [
          createUserEvent('a', sessionId: 'session-A'),
        ]),
      );

      container.read(conversationNotifierProvider.notifier).loadSession('session-B');
      await sendMessage(
        createSessionHistoryMessage('session-B', [
          createUserEvent('b', sessionId: 'session-B'),
        ]),
      );
      expect(getState().sessionId, 'session-B');

      // Event from old session-A should be ignored
      await sendMessage(createSessionEventMessage(
        createUserEvent('old', sessionId: 'session-A'),
      ));
      expect(getState().events.length, 1);
      expect(getState().events.first.content.text, 'b');
    });

    // TC-20-12: leaveSession — 取消訂閱並清空
    test('unsubscribes and clears state on leaveSession', () async {
      await initNotifier();

      container.read(conversationNotifierProvider.notifier).loadSession('session-1');
      await sendMessage(
        createSessionHistoryMessage('session-1', [
          createUserEvent('hello', sessionId: 'session-1'),
        ]),
      );
      expect(getState().sessionId, 'session-1');

      container.read(conversationNotifierProvider.notifier).leaveSession();
      await _pump();

      verify(() => mockService.unsubscribeSession('session-1')).called(1);
      expect(getState().sessionId, isNull);
      expect(getState().events, isEmpty);
    });

    // TC-20-13: setAutoScroll — 狀態切換
    test('toggles autoScroll state', () async {
      await initNotifier();
      expect(getState().isAutoScrollEnabled, isTrue);

      container.read(conversationNotifierProvider.notifier).setAutoScroll(false);
      await _pump();
      expect(getState().isAutoScrollEnabled, isFalse);

      container.read(conversationNotifierProvider.notifier).setAutoScroll(true);
      await _pump();
      expect(getState().isAutoScrollEnabled, isTrue);
    });

    // TC-20-14: loadSession 發送正確請求
    test('sends correct requests on loadSession', () async {
      await initNotifier();

      container.read(conversationNotifierProvider.notifier).loadSession('session-1');
      await _pump();

      verify(() => mockService.requestSessionHistory('session-1')).called(1);
      verify(() => mockService.subscribeSession('session-1')).called(1);
    });

    // TC-20-15: get_session_history 回傳 error — 設定 errorMessage
    test('sets errorMessage on error response', () async {
      await initNotifier();

      container.read(conversationNotifierProvider.notifier).loadSession('bad-session');
      await sendMessage(createErrorMessage('SESSION_NOT_FOUND'));

      final state = getState();
      expect(state.errorMessage, isNotNull);
      expect(state.events, isEmpty);
      expect(state.isLoadingHistory, isFalse);
    });
  });
}
