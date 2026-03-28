import 'dart:async';

import 'package:ccsession/core/constants/websocket_constants.dart';
import 'package:ccsession/core/models/client_message.dart';
import 'package:ccsession/core/models/connection_state.dart';
import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/core/websocket/websocket_service.dart';
import 'package:ccsession/features/conversation/presentation/conversation_notifier.dart';
import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// -- Fake WebSocketService --

/// 需求：[0.2.1-W1-001] 整合測試用 FakeWebSocketService
/// 約束：透過 StreamController 注入訊息，記錄所有送出的 ClientMessage
class FakeWebSocketService implements WebSocketService {
  final StreamController<ServerMessage> messageController =
      StreamController<ServerMessage>.broadcast();
  final StreamController<WsConnectionState> connectionStateController =
      StreamController<WsConnectionState>.broadcast();
  final List<ClientMessage> sentMessages = [];

  WsConnectionState _connectionState = WsConnectionState.connected;

  @override
  WsConnectionState get connectionState => _connectionState;

  @override
  Stream<WsConnectionState> get connectionStateStream =>
      connectionStateController.stream;

  @override
  Stream<ServerMessage> get messageStream => messageController.stream;

  @override
  Future<void> connect({Uri? uri}) async {}

  @override
  Future<void> disconnect() async {}

  @override
  void send(ClientMessage message) => sentMessages.add(message);

  @override
  void requestSessionList() => send(
        const ClientMessage(
          action: WebSocketConstants.actionGetSessionList,
        ),
      );

  @override
  void requestSessionHistory(
    String sessionId, {
    int? limit,
    String? before,
  }) =>
      send(ClientMessage(
        action: WebSocketConstants.actionGetSessionHistory,
        sessionId: sessionId,
        limit: limit ?? 0,
        before: before ?? '',
      ));

  @override
  void subscribeSession(String sessionId) => send(ClientMessage(
        action: WebSocketConstants.actionSubscribeSession,
        sessionId: sessionId,
      ));

  @override
  void unsubscribeSession(String sessionId) => send(ClientMessage(
        action: WebSocketConstants.actionUnsubscribeSession,
        sessionId: sessionId,
      ));

  @override
  void dispose() {
    messageController.close();
    connectionStateController.close();
  }
}

// -- Test Helpers --

/// 等待 async notifier build 完成
Future<void> pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

/// 建立單一 session 的 JSON 資料
Map<String, dynamic> buildSessionJson({
  required String id,
  String status = 'active',
  String projectPath = '/test/project',
}) {
  return {
    'id': id,
    'projectPath': projectPath,
    'summary': 'Test session $id',
    'status': status,
    'firstEventAt': '2026-03-29T10:00:00Z',
    'lastEventAt': '2026-03-29T10:00:00Z',
    'eventCount': 1,
  };
}

// -- Tests --

void main() {
  group('TC-FL: WebSocket -> Provider 整合測試', () {
    late FakeWebSocketService fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeWebSocketService();
      container = ProviderContainer(
        overrides: [
          webSocketServiceProvider.overrideWithValue(fake),
          connectionStateProvider
              .overrideWith((ref) => fake.connectionStateStream),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fake.dispose();
    });

    // -- SessionListNotifier helpers --

    Future<void> initSessionList() async {
      container.listen(sessionListNotifierProvider, (_, __) {});
      await pump();
    }

    Future<void> pushMessage(String type, Map<String, dynamic> data) async {
      fake.messageController.add(ServerMessage(type: type, data: data));
      await pump();
    }

    SessionListState getSessionListState() {
      return container.read(sessionListNotifierProvider).requireValue;
    }

    // -- ConversationNotifier helpers --

    Future<void> initConversation() async {
      container.listen(conversationNotifierProvider(0), (_, __) {});
      await pump();
    }

    ConversationState getConvState() {
      return container.read(conversationNotifierProvider(0)).requireValue;
    }

    // === 群組 A：SessionListNotifier 串接 ===

    group('群組 A：SessionListNotifier 串接', () {
      /// TC-FL-01: session_list 訊息驅動 SessionListNotifier 狀態更新
      test('TC-FL-01: session_list 訊息驅動 SessionListNotifier 狀態更新',
          () async {
        await initSessionList();

        // Then（前置驗證）: 初始 sessions 為空
        expect(getSessionListState().sessions, isEmpty);

        // When: 推入 session_list
        await pushMessage('session_list', {
          'sessions': [
            buildSessionJson(id: 's1', status: 'active'),
            buildSessionJson(id: 's2', status: 'idle'),
          ],
        });

        // Then: sessions 長度為 2，狀態正確
        final state = getSessionListState();
        expect(state.sessions, hasLength(2));

        final ids = state.sessions.map((s) => s.id).toSet();
        expect(ids, containsAll(['s1', 's2']));

        final s1 = state.sessions.firstWhere((s) => s.id == 's1');
        final s2 = state.sessions.firstWhere((s) => s.id == 's2');
        expect(s1.status.name, 'active');
        expect(s2.status.name, 'idle');
      });

      /// TC-FL-01 邊界：空 session_list 清空列表
      test('TC-FL-01 邊界：空 session_list 清空列表', () async {
        await initSessionList();

        // 先推入 2 個 session
        await pushMessage('session_list', {
          'sessions': [
            buildSessionJson(id: 's1'),
            buildSessionJson(id: 's2'),
          ],
        });
        expect(getSessionListState().sessions, hasLength(2));

        // When: 推入空 session_list
        await pushMessage('session_list', {'sessions': <dynamic>[]});

        // Then: sessions 為空
        expect(getSessionListState().sessions, isEmpty);
      });

      /// TC-FL-03: session_status_change 驅動狀態欄位更新
      test('TC-FL-03: session_status_change 驅動 SessionListNotifier 狀態欄位更新',
          () async {
        await initSessionList();

        // Given: 已有 session s1 (active)
        await pushMessage('session_list', {
          'sessions': [buildSessionJson(id: 's1', status: 'active')],
        });
        expect(getSessionListState().sessions.first.status.name, 'active');

        // When: 推入 session_status_change
        await pushMessage('session_status_change', {
          'sessionId': 's1',
          'status': 'idle',
        });

        // Then: s1 status 變為 idle
        expect(getSessionListState().sessions.first.status.name, 'idle');
      });

      /// TC-FL-03 邊界：未知 sessionId 的 status_change 靜默忽略
      test('TC-FL-03 邊界：未知 sessionId 的 status_change 靜默忽略',
          () async {
        await initSessionList();

        await pushMessage('session_list', {
          'sessions': [buildSessionJson(id: 's1', status: 'active')],
        });

        // When: 推入未知 sessionId 的 status_change
        await pushMessage('session_status_change', {
          'sessionId': 'unknown-session',
          'status': 'idle',
        });

        // Then: sessions 不變
        final state = getSessionListState();
        expect(state.sessions, hasLength(1));
        expect(state.sessions.first.id, 's1');
        expect(state.sessions.first.status.name, 'active');
      });
    });

    // === 群組 B：ConversationNotifier 串接 ===

    group('群組 B：ConversationNotifier 串接', () {
      /// TC-FL-02: session_event 驅動 ConversationNotifier 事件追加
      test('TC-FL-02: session_event 驅動 ConversationNotifier 事件追加',
          () async {
        await initConversation();

        // loadSession 觸發 requestSessionHistory + subscribeSession
        container
            .read(conversationNotifierProvider(0).notifier)
            .loadSession('session-1');
        await pump();

        // 驗證 loadSession 發送了正確的命令
        expect(
          fake.sentMessages.any((m) =>
              m.action == WebSocketConstants.actionGetSessionHistory &&
              m.sessionId == 'session-1'),
          isTrue,
        );
        expect(
          fake.sentMessages.any((m) =>
              m.action == WebSocketConstants.actionSubscribeSession &&
              m.sessionId == 'session-1'),
          isTrue,
        );

        // Given: 先推入空的 session_history 回應
        await pushMessage('session_history', {
          'sessionId': 'session-1',
          'events': <dynamic>[],
          'hasMore': false,
        });

        expect(getConvState().events, isEmpty);
        expect(getConvState().isLoadingHistory, false);

        // When: 推入 session_event
        await pushMessage('session_event', {
          'sessionId': 'session-1',
          'type': 'assistant',
          'content': {'text': 'Hello'},
          'timestamp': '2026-03-29T10:00:01Z',
          'messageId': 'msg-1',
          'contentIndex': 0,
          'isLastContent': true,
        });

        // Then: events 長度增加 1
        expect(getConvState().events, hasLength(1));
        expect(getConvState().events.last.content.text, 'Hello');
      });

      /// TC-FL-02 邊界：不同 sessionId 的 session_event 被忽略
      test('TC-FL-02 邊界：不同 sessionId 的 session_event 被忽略',
          () async {
        await initConversation();

        container
            .read(conversationNotifierProvider(0).notifier)
            .loadSession('session-1');
        await pump();

        await pushMessage('session_history', {
          'sessionId': 'session-1',
          'events': <dynamic>[],
          'hasMore': false,
        });

        // When: 推入不同 sessionId 的 event
        await pushMessage('session_event', {
          'sessionId': 'session-other',
          'type': 'assistant',
          'content': {'text': 'Should be ignored'},
          'timestamp': '2026-03-29T10:00:01Z',
          'messageId': 'msg-2',
          'contentIndex': 0,
          'isLastContent': true,
        });

        // Then: events 不變
        expect(getConvState().events, isEmpty);
      });

      /// TC-FL-05: loadSession 發送正確的 WebSocket 命令序列
      test('TC-FL-05: loadSession 發送正確的 WebSocket 命令序列', () async {
        await initConversation();

        final initialCount = fake.sentMessages.length;

        // When: loadSession
        container
            .read(conversationNotifierProvider(0).notifier)
            .loadSession('new-session');
        await pump();

        // Then: 發送了 history 請求和訂閱命令
        final newMessages = fake.sentMessages.sublist(initialCount);
        final historyIdx = newMessages.indexWhere((m) =>
            m.action == WebSocketConstants.actionGetSessionHistory &&
            m.sessionId == 'new-session');
        final subscribeIdx = newMessages.indexWhere((m) =>
            m.action == WebSocketConstants.actionSubscribeSession &&
            m.sessionId == 'new-session');

        expect(historyIdx, greaterThanOrEqualTo(0));
        expect(subscribeIdx, greaterThanOrEqualTo(0));
        // history 在 subscribe 之前
        expect(historyIdx, lessThan(subscribeIdx));
      });

      /// TC-FL-05 邊界：切換 session 時先取消前一個訂閱
      test('TC-FL-05 邊界：切換 session 時先取消前一個訂閱', () async {
        await initConversation();

        container
            .read(conversationNotifierProvider(0).notifier)
            .loadSession('old-session');
        await pump();

        // 清空記錄
        fake.sentMessages.clear();

        // When: 切換到新 session
        container
            .read(conversationNotifierProvider(0).notifier)
            .loadSession('new-session');
        await pump();

        // Then: 先 unsubscribe 舊 session
        final unsubIdx = fake.sentMessages.indexWhere((m) =>
            m.action == WebSocketConstants.actionUnsubscribeSession &&
            m.sessionId == 'old-session');
        expect(unsubIdx, greaterThanOrEqualTo(0),
            reason: 'Should unsubscribe old session');

        // 然後 subscribe 新 session
        final subIdx = fake.sentMessages.indexWhere((m) =>
            m.action == WebSocketConstants.actionSubscribeSession &&
            m.sessionId == 'new-session');
        expect(subIdx, greaterThanOrEqualTo(0),
            reason: 'Should subscribe new session');

        // unsubscribe 在 subscribe 之前
        expect(unsubIdx, lessThan(subIdx));
      });

      /// TC-FL-06: error 訊息驅動 ConversationNotifier 錯誤狀態
      test('TC-FL-06: error 訊息驅動 ConversationNotifier 錯誤狀態',
          () async {
        await initConversation();

        container
            .read(conversationNotifierProvider(0).notifier)
            .loadSession('s1');
        await pump();

        // 此時 isLoadingHistory 應為 true
        expect(getConvState().isLoadingHistory, true);

        // When: 推入 error
        await pushMessage('error', {'code': 'SESSION_NOT_FOUND'});

        // Then: errorMessage 設定，isLoadingHistory 為 false
        expect(getConvState().errorMessage, 'SESSION_NOT_FOUND');
        expect(getConvState().isLoadingHistory, false);
      });

      /// TC-FL-04: WebSocket 重連後自動重新訂閱
      test('TC-FL-04: WebSocket 重連後 ConversationNotifier 自動重新訂閱',
          () async {
        await initConversation();

        container
            .read(conversationNotifierProvider(0).notifier)
            .loadSession('s1');
        await pump();

        // 清空記錄
        fake.sentMessages.clear();

        // When: 模擬重連
        fake.connectionStateController.add(WsConnectionState.reconnecting);
        await pump();
        fake.connectionStateController.add(WsConnectionState.connected);
        await pump();

        // Then: sentMessages 包含 subscribe 和 history 請求
        expect(
          fake.sentMessages.any((m) =>
              m.action == WebSocketConstants.actionSubscribeSession &&
              m.sessionId == 's1'),
          isTrue,
          reason: 'Should resubscribe after reconnect',
        );
        expect(
          fake.sentMessages.any((m) =>
              m.action == WebSocketConstants.actionGetSessionHistory &&
              m.sessionId == 's1'),
          isTrue,
          reason: 'Should request history after reconnect',
        );
      });

      /// TC-FL-04 邊界：無 session 時重連不發送訊息
      test('TC-FL-04 邊界：無正在查看的 session 時重連不發送任何訊息',
          () async {
        await initConversation();

        fake.sentMessages.clear();

        // When: 模擬重連
        fake.connectionStateController.add(WsConnectionState.reconnecting);
        await pump();
        fake.connectionStateController.add(WsConnectionState.connected);
        await pump();

        // Then: 不發送任何訂閱或歷史請求
        final subscribeOrHistory = fake.sentMessages.where((m) =>
            m.action == WebSocketConstants.actionSubscribeSession ||
            m.action == WebSocketConstants.actionGetSessionHistory);
        expect(subscribeOrHistory, isEmpty);
      });
    });
  });
}
