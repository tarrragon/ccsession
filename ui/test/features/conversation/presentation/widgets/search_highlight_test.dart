import 'package:ccsession/core/constants/search_constants.dart';
import 'package:ccsession/features/conversation/presentation/widgets/assistant_message_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/search_highlight_utils.dart';
import 'package:ccsession/features/conversation/presentation/widgets/tool_use_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/user_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_conversation_factory.dart';

void main() {
  const baseStyle = TextStyle(fontSize: 14, color: Colors.black);

  group('TG-SEARCH-HIGHLIGHT: buildHighlightedSpans', () {
    // TC-SEARCH-60
    test('無高亮範圍回傳單一 TextSpan', () {
      final spans = buildHighlightedSpans('Hello world', [], baseStyle);

      expect(spans, hasLength(1));
      expect(spans[0].text, 'Hello world');
      expect(spans[0].style, baseStyle);
    });

    // TC-SEARCH-61
    test('單一高亮（普通匹配）有黃色背景', () {
      final spans = buildHighlightedSpans(
        'Hello world',
        [(start: 6, end: 11, isCurrent: false)],
        baseStyle,
      );

      expect(spans, hasLength(2));
      expect(spans[0].text, 'Hello ');
      expect(spans[0].style, baseStyle);
      expect(spans[1].text, 'world');
      expect(
        spans[1].style?.backgroundColor,
        SearchConstants.highlightColor,
      );
    });

    // TC-SEARCH-62
    test('當前聚焦匹配有橘色背景', () {
      final spans = buildHighlightedSpans(
        'Hello world',
        [(start: 6, end: 11, isCurrent: true)],
        baseStyle,
      );

      expect(spans, hasLength(2));
      expect(spans[1].text, 'world');
      expect(
        spans[1].style?.backgroundColor,
        SearchConstants.currentHighlightColor,
      );
    });

    // TC-SEARCH-63
    test('多重高亮：普通 + 當前聚焦', () {
      final spans = buildHighlightedSpans(
        'error in error',
        [
          (start: 0, end: 5, isCurrent: false),
          (start: 9, end: 14, isCurrent: true),
        ],
        baseStyle,
      );

      expect(spans, hasLength(3));
      expect(spans[0].text, 'error');
      expect(
        spans[0].style?.backgroundColor,
        SearchConstants.highlightColor,
      );
      expect(spans[1].text, ' in ');
      expect(spans[1].style, baseStyle);
      expect(spans[2].text, 'error');
      expect(
        spans[2].style?.backgroundColor,
        SearchConstants.currentHighlightColor,
      );
    });
  });

  group('TG-SEARCH-HIGHLIGHT: Bubble Widget 高亮', () {
    // TC-SEARCH-64
    testWidgets('AssistantMessageBubble 帶高亮渲染', (tester) async {
      final event = createAssistantEvent('Hello error world');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantMessageBubble(
              event: event,
              highlightRanges: const [
                (start: 6, end: 11, isCurrent: false),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsWidgets);
    });

    // TC-SEARCH-65
    testWidgets('UserMessageBubble 帶高亮渲染', (tester) async {
      final event = createUserEvent('search this');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserMessageBubble(
              event: event,
              highlightRanges: const [
                (start: 7, end: 11, isCurrent: true),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsWidgets);
    });

    // TC-SEARCH-66
    testWidgets('ToolUseBubble toolName 高亮', (tester) async {
      final event = createTestEvent(
        type: 'tool_use',
        toolName: 'Read',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolUseBubble(
              event: event,
              highlightRanges: const [
                (start: 0, end: 4, isCurrent: false),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsWidgets);
    });

    // TC-SEARCH-67
    testWidgets('Bubble 無高亮參數時正常渲染（向後相容）', (tester) async {
      final event = createAssistantEvent('Normal text');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantMessageBubble(event: event),
          ),
        ),
      );

      expect(find.text('Normal text'), findsOneWidget);
    });
  });
}
