import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/features/conversation/presentation/widgets/tool_use_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('E: ToolUseBubble 渲染驗證', () {
    Widget buildTestWidget(SessionEvent event) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ToolUseBubble(event: event),
          ),
        ),
      );
    }

    testWidgets('E1: 扁平 Map toolInput 以 key-value 格式顯示', (
      WidgetTester tester,
    ) async {
      final event = SessionEvent(
        sessionId: 'test-session',
        type: 'tool_use',
        content: EventContent(
          toolName: 'Read',
          toolInput: <String, dynamic>{
            'file_path': '/src/main.dart',
            'limit': 100,
          },
        ),
      );

      await tester.pumpWidget(buildTestWidget(event));

      // 展開 ExpansionTile
      await tester.tap(find.text('Read'));
      await tester.pumpAndSettle();

      // 驗證 key-value 格式（非 JSON 大括號格式）
      expect(find.textContaining('file_path: /src/main.dart'), findsOneWidget);
      expect(find.textContaining('limit: 100'), findsOneWidget);
    });

    testWidgets('E2: null toolInput 不顯示內容區塊', (
      WidgetTester tester,
    ) async {
      final event = SessionEvent(
        sessionId: 'test-session',
        type: 'tool_use',
        content: EventContent(
          toolName: 'EmptyTool',
        ),
      );

      await tester.pumpWidget(buildTestWidget(event));

      await tester.tap(find.text('EmptyTool'));
      await tester.pumpAndSettle();

      // 只有工具名稱，無內容
      expect(find.text('EmptyTool'), findsOneWidget);
    });

    testWidgets('E3: 巢狀 Map toolInput 以 compact JSON 顯示巢狀值', (
      WidgetTester tester,
    ) async {
      final event = SessionEvent(
        sessionId: 'test-session',
        type: 'tool_use',
        content: EventContent(
          toolName: 'Search',
          toolInput: <String, dynamic>{
            'query': 'test',
            'options': <String, dynamic>{'recursive': true},
          },
        ),
      );

      await tester.pumpWidget(buildTestWidget(event));

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(find.textContaining('query: test'), findsOneWidget);
      expect(
        find.textContaining('options: {"recursive":true}'),
        findsOneWidget,
      );
    });
  });
}
