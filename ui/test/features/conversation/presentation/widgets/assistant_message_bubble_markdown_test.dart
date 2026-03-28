import 'package:ccsession/core/constants/conversation_constants.dart';
import 'package:ccsession/features/conversation/presentation/widgets/assistant_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_conversation_factory.dart';

void main() {
  group('TG-MD-01: AssistantMessageBubble Markdown', () {
    // TC-MD-01-01: 無搜尋高亮時使用 MarkdownBody
    testWidgets('uses MarkdownBody when highlightRanges is null',
        (tester) async {
      final event = createAssistantEvent('**bold** and *italic*');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AssistantMessageBubble(event: event)),
      ));

      expect(find.byType(AssistantMessageBubble), findsOneWidget);
      expect(find.byType(MarkdownBody), findsOneWidget);
    });

    // TC-MD-01-02: highlightRanges 為空列表時使用 MarkdownBody
    testWidgets('uses MarkdownBody when highlightRanges is empty list',
        (tester) async {
      final event = createAssistantEvent('# Heading\n- item1\n- item2');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AssistantMessageBubble(event: event, highlightRanges: const []),
        ),
      ));

      expect(find.byType(AssistantMessageBubble), findsOneWidget);
      expect(find.byType(MarkdownBody), findsOneWidget);
    });

    // TC-MD-01-03: Markdown 表格渲染為 Table Widget
    testWidgets('renders Markdown table as Table widget', (tester) async {
      final event = createAssistantEvent(
        '| col1 | col2 |\n|------|------|\n| a | b |',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AssistantMessageBubble(event: event)),
      ));

      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.byType(Table), findsOneWidget);
    });

    // TC-MD-01-04: 程式碼區塊以視覺區分渲染
    testWidgets('renders code block without crash', (tester) async {
      final event = createAssistantEvent('```dart\nfinal x = 1;\n```');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AssistantMessageBubble(event: event)),
      ));

      expect(find.byType(MarkdownBody), findsOneWidget);
      // No crash = pass
    });

    // TC-MD-01-05: 有 highlightRanges 時不使用 MarkdownBody
    testWidgets('does not use MarkdownBody when highlightRanges is non-empty',
        (tester) async {
      final event = createAssistantEvent('**bold** text');
      const ranges = [
        (start: 0, end: 4, isCurrent: false, field: 'text'),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AssistantMessageBubble(
            event: event,
            highlightRanges: ranges,
          ),
        ),
      ));

      expect(find.byType(AssistantMessageBubble), findsOneWidget);
      expect(find.byType(MarkdownBody), findsNothing);
      expect(find.byType(RichText), findsOneWidget);
    });

    // TC-MD-01-06: 搜尋高亮降級不 crash
    testWidgets('highlight fallback does not crash with complex Markdown',
        (tester) async {
      final event =
          createAssistantEvent('# Title\n\n**bold** [link](url)');
      const ranges = [
        (start: 2, end: 7, isCurrent: true, field: 'text'),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AssistantMessageBubble(
            event: event,
            highlightRanges: ranges,
          ),
        ),
      ));

      expect(find.byType(MarkdownBody), findsNothing);
    });

    // TC-MD-01-07: 純文字無退化
    testWidgets('plain text renders correctly via MarkdownBody',
        (tester) async {
      final event = createAssistantEvent('Hello, this is plain text.');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AssistantMessageBubble(event: event)),
      ));

      expect(find.byType(AssistantMessageBubble), findsOneWidget);
      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.text('Hello, this is plain text.'), findsOneWidget);
    });

    // TC-MD-01-08: 空內容不 crash
    testWidgets('empty content does not crash', (tester) async {
      final event = createAssistantEvent('');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AssistantMessageBubble(event: event)),
      ));

      expect(find.byType(AssistantMessageBubble), findsOneWidget);
    });

    // TC-MD-01-09: 僅空白字元不 crash
    testWidgets('whitespace-only content does not crash', (tester) async {
      final event = createAssistantEvent('   \n\n  ');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AssistantMessageBubble(event: event)),
      ));

      // No crash = pass
    });

    // TC-MD-01-10: 超長 Markdown 內容不 crash
    testWidgets('long Markdown content does not crash', (tester) async {
      final longContent =
          List.generate(200, (i) => '- item $i').join('\n');
      final event = createAssistantEvent(longContent);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AssistantMessageBubble(event: event),
          ),
        ),
      ));

      expect(find.byType(MarkdownBody), findsOneWidget);
    });

    // TC-MD-01-11: 外層 Container 維持 bubbleMargin 和 bubbleContentPadding
    testWidgets('Container keeps bubbleMargin and bubbleContentPadding',
        (tester) async {
      final event = createAssistantEvent('**test**');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AssistantMessageBubble(event: event)),
      ));

      expect(find.byType(AssistantMessageBubble), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.margin, ConversationConstants.bubbleMargin);
      expect(container.padding, ConversationConstants.bubbleContentPadding);
    });

    // TC-MD-01-12: 靠左對齊不變
    testWidgets('alignment remains centerLeft', (tester) async {
      final event = createAssistantEvent('# Title');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AssistantMessageBubble(event: event)),
      ));

      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerLeft);
    });
  });
}
