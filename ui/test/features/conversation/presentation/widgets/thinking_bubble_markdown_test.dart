import 'package:ccsession/features/conversation/presentation/widgets/thinking_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_conversation_factory.dart';

void main() {
  group('TG-MD-02: ThinkingBubble Markdown', () {
    // TC-MD-02-01: 無高亮時展開後使用 MarkdownBody
    testWidgets('uses MarkdownBody when expanded without highlights',
        (tester) async {
      final event = createThinkingEvent('**important** thought');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ThinkingBubble(event: event)),
      ));

      expect(find.byType(ThinkingBubble), findsOneWidget);
      expect(find.byType(ExpansionTile), findsOneWidget);

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.byType(MarkdownBody), findsOneWidget);
    });

    // TC-MD-02-02: 有高亮時展開後降級為 RichText
    testWidgets('falls back to RichText when expanded with highlights',
        (tester) async {
      final event = createThinkingEvent('**bold** text');
      const ranges = [
        (start: 0, end: 4, isCurrent: false, field: 'text'),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ThinkingBubble(event: event, highlightRanges: ranges),
        ),
      ));

      expect(find.byType(ThinkingBubble), findsOneWidget);

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.byType(MarkdownBody), findsNothing);
      expect(find.byType(RichText), findsWidgets);
    });

    // TC-MD-02-03: Markdown 表格展開後渲染為 Table
    testWidgets('renders Markdown table as Table widget when expanded',
        (tester) async {
      final event = createThinkingEvent(
        '| col1 | col2 |\n|------|------|\n| a | b |',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ThinkingBubble(event: event)),
      ));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.byType(Table), findsOneWidget);
    });

    // TC-MD-02-04: 空內容展開後不 crash
    testWidgets('empty content does not crash when expanded', (tester) async {
      final event = createThinkingEvent('');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ThinkingBubble(event: event)),
      ));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();
      // No crash = pass
    });

    // TC-MD-02-05: 純文字展開後文字可見
    testWidgets('plain text is visible when expanded', (tester) async {
      final event = createThinkingEvent('Just a plain thought');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ThinkingBubble(event: event)),
      ));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.text('Just a plain thought'), findsOneWidget);
    });

    // TC-MD-02-06: 斜體基調 — styleSheet p 包含 italic
    testWidgets('MarkdownBody styleSheet has italic paragraph style',
        (tester) async {
      final event = createThinkingEvent('thinking content');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ThinkingBubble(event: event)),
      ));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      final markdownBody =
          tester.widget<MarkdownBody>(find.byType(MarkdownBody));
      expect(
        markdownBody.styleSheet?.p?.fontStyle,
        FontStyle.italic,
      );
    });
  });
}
