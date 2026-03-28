import 'package:ccsession/core/constants/conversation_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// 需求：[0.2.1-W1-002] Bubble 用 MarkdownStyleSheet 建構輔助函式
/// 約束：程式碼區塊用 monospace 字體、表格有邊框
MarkdownStyleSheet buildBubbleMarkdownStyleSheet(ThemeData theme) {
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    code: ConversationConstants.monospaceStyle.copyWith(
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
    ),
    codeblockDecoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(ConversationConstants.codeBlockBorderRadius),
    ),
    tableBorder: TableBorder.all(
      color: theme.colorScheme.outline.withValues(alpha: 0.3),
    ),
  );
}
