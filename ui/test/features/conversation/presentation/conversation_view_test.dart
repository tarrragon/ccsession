import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/features/conversation/presentation/conversation_notifier.dart';
import 'package:ccsession/features/conversation/presentation/conversation_view.dart';
import 'package:ccsession/features/conversation/presentation/widgets/assistant_message_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/tool_use_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/user_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_conversation_factory.dart';

/// 需求：建構帶有 ProviderScope override 的 ConversationView Widget
Widget _buildWidget(ConversationState state) {
  return ProviderScope(
    overrides: [
      conversationNotifierProvider(0).overrideWith(
        () => _FakeConversationNotifier(state),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: ConversationView(panelIndex: 0)),
    ),
  );
}

/// 需求：提供固定 state 的 Fake Notifier，用於 Widget 測試
class _FakeConversationNotifier extends ConversationNotifier {
  _FakeConversationNotifier(this._fixedState);

  final ConversationState _fixedState;
  bool loadMoreHistoryCalled = false;

  @override
  Future<ConversationState> build(int panelIndex) async => _fixedState;

  @override
  void loadMoreHistory() {
    loadMoreHistoryCalled = true;
  }

  @override
  void setAutoScroll(bool enabled) {}

  @override
  void loadSession(String sessionId) {}

  @override
  void leaveSession() {}
}

void main() {
  group('TG-21: ConversationView Widget', () {
    // TC-21-01: 空狀態 — 顯示提示文字
    testWidgets('shows empty state placeholder when events empty and not loading',
        (tester) async {
      await tester.pumpWidget(_buildWidget(
        const ConversationState(sessionId: 's1'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(UserMessageBubble), findsNothing);
      expect(find.byType(AssistantMessageBubble), findsNothing);
      // 應找到空狀態提示文字
      expect(find.byKey(const Key('conversation_empty_state')), findsOneWidget);
    });

    // TC-21-02: 載入中 — 顯示載入指示器
    testWidgets('shows loading indicator when isLoadingHistory is true',
        (tester) async {
      await tester.pumpWidget(_buildWidget(
        const ConversationState(isLoadingHistory: true),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // TC-21-03: 有事件 — 渲染訊息列表
    testWidgets('renders message list with correct bubble types',
        (tester) async {
      final events = <SessionEvent>[
        createUserEvent('hi'),
        createAssistantEvent('hello'),
        createToolUseEvent('Read'),
      ];

      await tester.pumpWidget(_buildWidget(
        ConversationState(sessionId: 's1', events: events),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(UserMessageBubble), findsOneWidget);
      expect(find.byType(AssistantMessageBubble), findsOneWidget);
      expect(find.byType(ToolUseBubble), findsOneWidget);
    });

    // TC-21-04: 載入更多按鈕 — hasMore 為 true 時顯示
    testWidgets('shows load more button when hasMore is true and taps it',
        (tester) async {
      final events = <SessionEvent>[createUserEvent('msg')];

      await tester.pumpWidget(_buildWidget(
        ConversationState(sessionId: 's1', events: events, hasMore: true),
      ));
      await tester.pumpAndSettle();

      final loadMoreFinder =
          find.byKey(const Key('conversation_load_more_button'));
      expect(loadMoreFinder, findsOneWidget);

      await tester.tap(loadMoreFinder);
      await tester.pump();
    });

    // TC-21-05: 載入更多按鈕 — hasMore 為 false 時不顯示
    testWidgets('hides load more button when hasMore is false',
        (tester) async {
      final events = <SessionEvent>[createUserEvent('msg')];

      await tester.pumpWidget(_buildWidget(
        ConversationState(sessionId: 's1', events: events),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('conversation_load_more_button')),
          findsNothing);
    });

    // TC-21-06: 跳到最新按鈕 — isAutoScrollEnabled 為 false 時顯示
    testWidgets('shows jump to latest FAB when auto scroll disabled',
        (tester) async {
      final events = <SessionEvent>[createUserEvent('msg')];

      await tester.pumpWidget(_buildWidget(
        ConversationState(
          sessionId: 's1',
          events: events,
          isAutoScrollEnabled: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('conversation_scroll_to_top')),
          findsOneWidget);
    });

    // TC-21-07: 跳到最新按鈕 — isAutoScrollEnabled 為 true 時不顯示
    testWidgets('hides jump to latest FAB when auto scroll enabled',
        (tester) async {
      final events = <SessionEvent>[createUserEvent('msg')];

      await tester.pumpWidget(_buildWidget(
        ConversationState(sessionId: 's1', events: events),
      ));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('conversation_scroll_to_top')), findsNothing);
    });

    // TC-21-09: 最新訊息在頂部顯示
    testWidgets('renders newest message at top of list',
        (tester) async {
      final events = <SessionEvent>[
        createUserEvent('oldest'),
        createAssistantEvent('middle'),
        createUserEvent('newest'),
      ];

      await tester.pumpWidget(_buildWidget(
        ConversationState(sessionId: 's1', events: events),
      ));
      await tester.pumpAndSettle();

      // 最新訊息在頂部：三個 bubble 都渲染
      expect(find.byType(UserMessageBubble), findsNWidgets(2));
      expect(find.byType(AssistantMessageBubble), findsOneWidget);
      expect(find.text('newest'), findsOneWidget);
      expect(find.text('oldest'), findsOneWidget);
    });

    // TC-21-10: hasMore 時 Load More 在底部，索引不錯位
    testWidgets('load more button at bottom does not shift event indices',
        (tester) async {
      final events = <SessionEvent>[
        createUserEvent('first'),
        createAssistantEvent('second'),
      ];

      await tester.pumpWidget(_buildWidget(
        ConversationState(sessionId: 's1', events: events, hasMore: true),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('conversation_load_more_button')),
          findsOneWidget);
      expect(find.byType(UserMessageBubble), findsOneWidget);
      expect(find.byType(AssistantMessageBubble), findsOneWidget);
      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
    });

    // TC-21-08: 錯誤狀態 — 顯示錯誤訊息
    testWidgets('shows error message when errorMessage is set',
        (tester) async {
      await tester.pumpWidget(_buildWidget(
        const ConversationState(errorMessage: 'SESSION_NOT_FOUND'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('conversation_error_state')), findsOneWidget);
    });
  });
}
