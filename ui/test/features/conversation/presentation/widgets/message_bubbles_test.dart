import 'package:ccsession/features/conversation/presentation/widgets/assistant_message_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/message_bubble_factory.dart';
import 'package:ccsession/features/conversation/presentation/widgets/thinking_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/tool_result_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/tool_use_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/user_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_conversation_factory.dart';

void main() {
  group('TG-22: MessageBubble Widgets', () {
    // TC-22-01: UserMessageBubble — 正確渲染
    testWidgets('UserMessageBubble renders text aligned right', (tester) async {
      final event = createUserEvent('Hello world');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: UserMessageBubble(event: event)),
      ));

      expect(find.text('Hello world'), findsOneWidget);
      expect(find.byType(Align), findsOneWidget);

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerRight);
    });

    // TC-22-02: AssistantMessageBubble — 正確渲染
    testWidgets('AssistantMessageBubble renders text aligned left',
        (tester) async {
      final event = createAssistantEvent('I can help');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AssistantMessageBubble(event: event)),
      ));

      expect(find.text('I can help'), findsOneWidget);
      expect(find.byType(Align), findsOneWidget);

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerLeft);
    });

    // TC-22-03: ToolUseBubble — 正確渲染工具名稱
    testWidgets('ToolUseBubble renders tool name', (tester) async {
      final event = createToolUseEvent('Read', input: {'path': '/file.dart'});

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ToolUseBubble(event: event)),
      ));

      expect(find.text('Read'), findsOneWidget);
    });

    // TC-22-04: ToolUseBubble — toolInput 為 null
    testWidgets('ToolUseBubble handles null toolInput gracefully',
        (tester) async {
      final event = createToolUseEvent('ListFiles');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ToolUseBubble(event: event)),
      ));

      expect(find.text('ListFiles'), findsOneWidget);
      // No exception thrown
    });

    // TC-22-05: ToolResultBubble — 正常結果
    testWidgets('ToolResultBubble renders normal result', (tester) async {
      final event = createToolResultEvent(output: 'file contents here');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ToolResultBubble(event: event)),
      ));

      // Expand the tile to see the content
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.text('file contents here'), findsOneWidget);

      // Verify no red border (normal result)
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(ExpansionTile),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border!.top.color, isNot(Colors.red));
    });

    // TC-22-06: ToolResultBubble — 錯誤結果（isError=true）
    testWidgets('ToolResultBubble renders error result with red border',
        (tester) async {
      final event = createToolResultEvent(
        output: 'Error: file not found',
        isError: true,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ToolResultBubble(event: event)),
      ));

      // Expand the tile to see the content
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.text('Error: file not found'), findsOneWidget);

      // Verify red border
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(ExpansionTile),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border!.top.color, Colors.red);
    });

    // TC-22-07: ThinkingBubble — 正確渲染
    testWidgets('ThinkingBubble renders thinking text', (tester) async {
      final event = createThinkingEvent('Let me think about this...');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ThinkingBubble(event: event)),
      ));

      // Expand the tile to see the content
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.text('Let me think about this...'), findsOneWidget);
    });

    // TC-22-08: ThinkingBubble — 空文字不渲染
    testWidgets('empty thinking text renders SizedBox.shrink via factory',
        (tester) async {
      final event = createThinkingEvent('');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: MessageBubbleFactory.build(event)),
      ));

      expect(find.byType(ThinkingBubble), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    // TC-22-09: MessageBubbleFactory — 未知類型 fallback
    testWidgets('unknown event type renders SizedBox.shrink', (tester) async {
      final event = createTestEvent(type: 'unknown_type', text: 'data');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: MessageBubbleFactory.build(event)),
      ));

      expect(find.byType(UserMessageBubble), findsNothing);
      expect(find.byType(AssistantMessageBubble), findsNothing);
      expect(find.byType(ToolUseBubble), findsNothing);
      expect(find.byType(ToolResultBubble), findsNothing);
      expect(find.byType(ThinkingBubble), findsNothing);
    });
  });
}
