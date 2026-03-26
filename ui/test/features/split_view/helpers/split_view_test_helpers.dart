import 'dart:async';

import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/core/websocket/websocket_service.dart';
import 'package:ccsession/features/conversation/presentation/conversation_notifier.dart';
import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:ccsession/features/split_view/data/split_view_storage.dart';
import 'package:ccsession/features/split_view/presentation/split_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'fake_split_view_storage.dart';

/// 共用 Mock：WebSocketService
class MockWebSocketService extends Mock implements WebSocketService {}

/// 共用 Fake：ConversationNotifier（空實作）
class FakeConversationNotifier extends ConversationNotifier {
  FakeConversationNotifier({this.initialSessionId});

  final String? initialSessionId;

  @override
  Future<ConversationState> build(int panelIndex) async =>
      ConversationState(sessionId: initialSessionId);

  @override
  void loadSession(String sessionId) {}
  @override
  void loadMoreHistory() {}
  @override
  void setAutoScroll(bool enabled) {}
  @override
  void leaveSession() {}
}

/// 共用 Fake：SessionListNotifier（空列表）
class FakeSessionListNotifier extends SessionListNotifier {
  @override
  Future<SessionListState> build() async => const SessionListState();
}

/// 建立測試用 ProviderScope，包含所有 split_view 相關 overrides
///
/// [child] 為實際要測試的 Widget
/// [panelCount] 決定要 override 幾個 conversationNotifierProvider（預設 2）
/// [conversationFactory] 可自訂 FakeConversationNotifier 建構方式
Widget buildSplitViewTestWidget(
  SplitViewState initialState, {
  required Widget child,
  int panelCount = 2,
  FakeConversationNotifier Function()? conversationFactory,
}) {
  final fakeStorage = FakeSplitViewStorage()..loadResult = initialState;
  final messageController = StreamController<ServerMessage>.broadcast();
  final mockService = MockWebSocketService();
  when(() => mockService.messageStream)
      .thenAnswer((_) => messageController.stream);

  final factory = conversationFactory ?? FakeConversationNotifier.new;

  return ProviderScope(
    overrides: [
      splitViewStorageProvider.overrideWithValue(fakeStorage),
      webSocketServiceProvider.overrideWithValue(mockService),
      for (var i = 0; i < panelCount; i++)
        conversationNotifierProvider(i).overrideWith(factory),
      sessionListNotifierProvider.overrideWith(FakeSessionListNotifier.new),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}
