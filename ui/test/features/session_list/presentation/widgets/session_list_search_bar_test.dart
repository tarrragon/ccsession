import 'dart:async';

import 'package:ccsession/core/constants/search_constants.dart';
import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/core/websocket/websocket_service.dart';
import 'package:ccsession/features/session_list/presentation/session_list_search_notifier.dart';
import 'package:ccsession/features/session_list/presentation/session_list_search_state.dart';
import 'package:ccsession/features/session_list/presentation/widgets/session_list_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWebSocketService extends Mock implements WebSocketService {}

/// 需求：Fake Notifier 記錄方法呼叫，供 Widget 測試驗證互動
class FakeSessionListSearchNotifier extends SessionListSearchNotifier {
  final List<String> calls = [];
  final SessionListSearchState _state;

  FakeSessionListSearchNotifier(this._state);

  @override
  SessionListSearchState build() => _state;

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
}

void main() {
  group('TG-FILTER-05: SessionListSearchBar Widget', () {
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

    Widget buildTestWidget({
      required FakeSessionListSearchNotifier fakeNotifier,
    }) {
      return ProviderScope(
        overrides: [
          webSocketServiceProvider.overrideWithValue(mockService),
          sessionListSearchNotifierProvider.overrideWith(
            () => fakeNotifier,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SessionListSearchBar(),
          ),
        ),
      );
    }

    testWidgets(
      'TC-FILTER-50: 搜尋列可見時渲染 TextField 和關閉按鈕',
      (tester) async {
        final fakeNotifier = FakeSessionListSearchNotifier(
          const SessionListSearchState(isSearchVisible: true),
        );
        await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
        await tester.pump();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
        // 不存在導航按鈕
        expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
        expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
      },
    );

    testWidgets(
      'TC-FILTER-51: 搜尋列隱藏時不渲染',
      (tester) async {
        final fakeNotifier = FakeSessionListSearchNotifier(
          const SessionListSearchState(isSearchVisible: false),
        );
        await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
        await tester.pump();

        expect(find.byType(TextField), findsNothing);
      },
    );

    testWidgets(
      'TC-FILTER-52: 文字輸入觸發 updateQuery',
      (tester) async {
        final fakeNotifier = FakeSessionListSearchNotifier(
          const SessionListSearchState(isSearchVisible: true),
        );
        await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'auth');
        expect(fakeNotifier.calls, contains('updateQuery:auth'));
      },
    );

    testWidgets(
      'TC-FILTER-53: 關閉按鈕觸發 closeSearch',
      (tester) async {
        final fakeNotifier = FakeSessionListSearchNotifier(
          const SessionListSearchState(isSearchVisible: true),
        );
        await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.close));
        expect(fakeNotifier.calls, contains('closeSearch'));
      },
    );

    testWidgets(
      'TC-FILTER-54: Escape 鍵觸發 closeSearch',
      (tester) async {
        final fakeNotifier = FakeSessionListSearchNotifier(
          const SessionListSearchState(isSearchVisible: true),
        );
        await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
        await tester.pump();

        // 確保 focus 在 TextField
        await tester.tap(find.byType(TextField));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();

        expect(fakeNotifier.calls, contains('closeSearch'));
      },
    );

    testWidgets(
      'TC-FILTER-55: TextField 開啟時自動聚焦',
      (tester) async {
        final fakeNotifier = FakeSessionListSearchNotifier(
          const SessionListSearchState(isSearchVisible: true),
        );
        await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
        await tester.pump();

        // autofocus 屬性設為 true
        final textField =
            tester.widget<TextField>(find.byType(TextField));
        expect(textField.autofocus, isTrue);
      },
    );

    testWidgets(
      'TC-FILTER-56: hint 文字顯示正確',
      (tester) async {
        final fakeNotifier = FakeSessionListSearchNotifier(
          const SessionListSearchState(isSearchVisible: true),
        );
        await tester.pumpWidget(buildTestWidget(fakeNotifier: fakeNotifier));
        await tester.pump();

        expect(
          find.text(SearchConstants.sessionFilterHint),
          findsOneWidget,
        );
      },
    );
  });
}
