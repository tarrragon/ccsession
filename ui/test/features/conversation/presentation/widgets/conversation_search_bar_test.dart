import 'dart:async';

import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/core/websocket/websocket_service.dart';
import 'package:ccsession/features/conversation/domain/search_match.dart';
import 'package:ccsession/features/conversation/presentation/conversation_search_notifier.dart';
import 'package:ccsession/features/conversation/presentation/conversation_search_state.dart';
import 'package:ccsession/features/conversation/presentation/widgets/conversation_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWebSocketService extends Mock implements WebSocketService {}

/// 需求：Fake Notifier 記錄方法呼叫，供 Widget 測試驗證互動
class FakeConversationSearchNotifier
    extends ConversationSearchNotifier {
  final List<String> calls = [];
  final ConversationSearchState _state;

  FakeConversationSearchNotifier(this._state);

  @override
  ConversationSearchState build(int panelIndex) => _state;

  @override
  void openSearch() {
    calls.add('openSearch');
  }

  @override
  void closeSearch() {
    calls.add('closeSearch');
  }

  @override
  void updateQuery(String query) {
    calls.add('updateQuery:$query');
  }

  @override
  void nextMatch() {
    calls.add('nextMatch');
  }

  @override
  void previousMatch() {
    calls.add('previousMatch');
  }
}

void main() {
  group('TG-SEARCH-BAR: ConversationSearchBar Widget', () {
    late StreamController<ServerMessage> messageController;
    late MockWebSocketService mockService;

    setUp(() {
      messageController = StreamController<ServerMessage>.broadcast();
      mockService = MockWebSocketService();
      when(() => mockService.messageStream)
          .thenAnswer((_) => messageController.stream);
      when(() => mockService.requestSessionHistory(
            any(),
            limit: any(named: 'limit'),
            before: any(named: 'before'),
          )).thenReturn(null);
      when(() => mockService.subscribeSession(any())).thenReturn(null);
      when(() => mockService.unsubscribeSession(any())).thenReturn(null);
    });

    tearDown(() {
      messageController.close();
    });

    Widget buildTestWidget({
      required FakeConversationSearchNotifier fakeNotifier,
    }) {
      return ProviderScope(
        overrides: [
          webSocketServiceProvider.overrideWithValue(mockService),
          conversationSearchNotifierProvider(0).overrideWith(
            () => fakeNotifier,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ConversationSearchBar(panelIndex: 0),
          ),
        ),
      );
    }

    // TC-SEARCH-50: basic elements rendering
    testWidgets('TC-SEARCH-50: renders TextField, close, up, down buttons',
        (WidgetTester tester) async {
      final fakeNotifier = FakeConversationSearchNotifier(
        const ConversationSearchState(isSearchVisible: true),
      );

      await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
      await tester.pumpAndSettle();

      // 前置驗證
      expect(find.byType(ConversationSearchBar), findsOneWidget);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    // TC-SEARCH-51: hidden when isSearchVisible=false
    testWidgets('TC-SEARCH-51: hidden when isSearchVisible is false',
        (WidgetTester tester) async {
      final fakeNotifier = FakeConversationSearchNotifier(
        const ConversationSearchState(isSearchVisible: false),
      );

      await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });

    // TC-SEARCH-52: text input triggers updateQuery
    testWidgets('TC-SEARCH-52: text input calls updateQuery',
        (WidgetTester tester) async {
      final fakeNotifier = FakeConversationSearchNotifier(
        const ConversationSearchState(isSearchVisible: true),
      );

      await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'error');
      await tester.pump();

      expect(fakeNotifier.calls, contains('updateQuery:error'));
    });

    // TC-SEARCH-53: match count display
    testWidgets('TC-SEARCH-53: displays matchCountDisplay text',
        (WidgetTester tester) async {
      final fakeNotifier = FakeConversationSearchNotifier(
        const ConversationSearchState(
          isSearchVisible: true,
          query: 'test',
          matches: [
            SearchMatch(eventIndex: 0, startOffset: 0, endOffset: 4, field: 'text'),
            SearchMatch(eventIndex: 1, startOffset: 0, endOffset: 4, field: 'text'),
            SearchMatch(eventIndex: 2, startOffset: 0, endOffset: 4, field: 'text'),
          ],
          currentMatchIndex: 2,
        ),
      );

      await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
      await tester.pumpAndSettle();

      expect(find.text('3/3'), findsOneWidget);
    });

    // TC-SEARCH-54: up/down button calls
    testWidgets('TC-SEARCH-54: navigation buttons call nextMatch and previousMatch',
        (WidgetTester tester) async {
      final fakeNotifier = FakeConversationSearchNotifier(
        const ConversationSearchState(
          isSearchVisible: true,
          query: 'test',
          matches: [
            SearchMatch(eventIndex: 0, startOffset: 0, endOffset: 4, field: 'text'),
          ],
          currentMatchIndex: 0,
        ),
      );

      await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
      await tester.pumpAndSettle();

      // 前置驗證
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pump();
      expect(fakeNotifier.calls, contains('nextMatch'));

      await tester.tap(find.byIcon(Icons.keyboard_arrow_up));
      await tester.pump();
      expect(fakeNotifier.calls, contains('previousMatch'));
    });

    // TC-SEARCH-55: close button calls closeSearch
    testWidgets('TC-SEARCH-55: close button calls closeSearch',
        (WidgetTester tester) async {
      final fakeNotifier = FakeConversationSearchNotifier(
        const ConversationSearchState(isSearchVisible: true),
      );

      await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(fakeNotifier.calls, contains('closeSearch'));
    });

    // TC-SEARCH-56: buttons disabled when no matches
    testWidgets('TC-SEARCH-56: navigation buttons disabled when no matches',
        (WidgetTester tester) async {
      final fakeNotifier = FakeConversationSearchNotifier(
        const ConversationSearchState(
          isSearchVisible: true,
          query: 'xyz',
        ),
      );

      await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
      await tester.pumpAndSettle();

      final upButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.keyboard_arrow_up),
      );
      final downButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.keyboard_arrow_down),
      );

      expect(upButton.onPressed, isNull);
      expect(downButton.onPressed, isNull);
    });

    // TC-SEARCH-57: Enter key calls nextMatch
    testWidgets('TC-SEARCH-57: Enter key triggers nextMatch',
        (WidgetTester tester) async {
      final fakeNotifier = FakeConversationSearchNotifier(
        const ConversationSearchState(
          isSearchVisible: true,
          query: 'test',
          matches: [
            SearchMatch(eventIndex: 0, startOffset: 0, endOffset: 4, field: 'text'),
          ],
          currentMatchIndex: 0,
        ),
      );

      await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
      await tester.pumpAndSettle();

      // 前置驗證: TextField has focus
      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(fakeNotifier.calls, contains('nextMatch'));
    });

    // TC-SEARCH-58: Shift+Enter calls previousMatch
    testWidgets('TC-SEARCH-58: Shift+Enter triggers previousMatch',
        (WidgetTester tester) async {
      final fakeNotifier = FakeConversationSearchNotifier(
        const ConversationSearchState(
          isSearchVisible: true,
          query: 'test',
          matches: [
            SearchMatch(eventIndex: 0, startOffset: 0, endOffset: 4, field: 'text'),
          ],
          currentMatchIndex: 0,
        ),
      );

      await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(fakeNotifier.calls, contains('previousMatch'));
    });

    // TC-SEARCH-59: Escape key calls closeSearch
    testWidgets('TC-SEARCH-59: Escape key triggers closeSearch',
        (WidgetTester tester) async {
      final fakeNotifier = FakeConversationSearchNotifier(
        const ConversationSearchState(isSearchVisible: true),
      );

      await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(fakeNotifier.calls, contains('closeSearch'));
    });
  });
}
