import 'package:ccsession/core/constants/conversation_constants.dart';
import 'package:ccsession/features/conversation/presentation/widgets/bubble_markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-MD-03: buildBubbleMarkdownStyleSheet', () {
    late ThemeData theme;

    setUp(() {
      theme = ThemeData(
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 14),
        ),
      );
    });

    // TC-MD-03-01: 程式碼區塊使用 monospace 字體
    test('code style uses monospace fontFamily from ConversationConstants', () {
      final sheet = buildBubbleMarkdownStyleSheet(theme);

      expect(
        sheet.code?.fontFamily,
        ConversationConstants.monospaceStyle.fontFamily,
      );
    });

    // TC-MD-03-02: 程式碼區塊有背景裝飾
    test('codeblockDecoration has backgroundColor', () {
      final sheet = buildBubbleMarkdownStyleSheet(theme);

      expect(sheet.codeblockDecoration, isNotNull);
      final decoration = sheet.codeblockDecoration! as BoxDecoration;
      expect(decoration.color, isNotNull);
    });

    // TC-MD-03-03: 表格有邊框
    test('tableBorder is not null', () {
      final sheet = buildBubbleMarkdownStyleSheet(theme);

      expect(sheet.tableBorder, isNotNull);
    });
  });
}
