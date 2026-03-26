import 'package:ccsession/core/models/connection_state.dart';
import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/websocket/websocket_service.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/features/conversation/presentation/conversation_notifier.dart';
import 'package:ccsession/features/dashboard/presentation/dashboard_page.dart';
import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

/// Fake WebSocketService 用於測試
class FakeWebSocketService implements WebSocketService {
  @override
  WsConnectionState get connectionState => WsConnectionState.connected;

  @override
  Stream<WsConnectionState> get connectionStateStream =>
      Stream.value(WsConnectionState.connected);

  @override
  Stream<ServerMessage> get messageStream => Stream.empty();

  @override
  Future<void> connect({Uri? uri}) async {}

  @override
  Future<void> disconnect() async {}

  @override
  void send(dynamic message) {}

  @override
  void requestSessionList() {}

  @override
  void requestSessionHistory(
    String sessionId, {
    int? limit,
    String? before,
  }) {}

  @override
  void subscribeSession(String sessionId) {}

  @override
  void unsubscribeSession(String sessionId) {}

  @override
  void dispose() {}
}

/// Fake SessionListNotifier 用於測試
class FakeSessionListNotifier extends SessionListNotifier {
  FakeSessionListNotifier(this._initialState) : _state = _initialState;

  final SessionListState _initialState;
  late SessionListState _state;

  @override
  Future<SessionListState> build() async => _state;

  /// 供測試控制 selectedSessionId
  void setSelectedSessionId(String? id) {
    _state = _state.copyWith(selectedSessionId: id);
    state = AsyncData(_state);
  }
}

/// Fake ConversationNotifier 用於測試
class FakeConversationNotifier extends ConversationNotifier {
  FakeConversationNotifier(this._initialState);

  final ConversationState _initialState;
  final List<String> loadSessionCalls = [];

  @override
  Future<ConversationState> build() async => _initialState;

  @override
  Future<void> loadSession(String sessionId) async {
    loadSessionCalls.add(sessionId);
    state = AsyncData(_initialState.copyWith(sessionId: sessionId));
  }

  @override
  void loadMoreHistory() {}

  @override
  void setAutoScroll(bool enabled) {}

  @override
  void leaveSession() {}
}

/// 測試 helper：建立 DashboardPage 並配置所有 provider override
Widget buildDashboardWithOverrides({
  SessionListState? sessionListState,
  ConversationState? conversationState,
  WsConnectionState? connectionState,
  List<Override> additionalOverrides = const [],
}) {
  final mockSessionListState = sessionListState ??
      const SessionListState(
        sessions: [],
        selectedSessionId: null,
      );

  final mockConversationState = conversationState ??
      const ConversationState(
        sessionId: null,
        events: [],
        isLoadingHistory: false,
      );

  final mockConnectionState = connectionState ?? WsConnectionState.connected;

  return ProviderScope(
    overrides: [
      webSocketServiceProvider.overrideWithValue(FakeWebSocketService()),
      sessionListNotifierProvider.overrideWith(
        () => FakeSessionListNotifier(mockSessionListState),
      ),
      conversationNotifierProvider.overrideWith(
        () => FakeConversationNotifier(mockConversationState),
      ),
      connectionStateProvider.overrideWith(
        (ref) => Stream.value(mockConnectionState),
      ),
      ...additionalOverrides,
    ],
    child: const MaterialApp(home: DashboardPage()),
  );
}
