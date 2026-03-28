import 'package:ccsession/core/constants/conversation_constants.dart';
import 'package:ccsession/core/constants/search_constants.dart';
import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/features/conversation/presentation/widgets/bubble_markdown_style.dart';
import 'package:ccsession/features/conversation/presentation/widgets/search_highlight_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// 需求：助手訊息 Bubble（Phase 1 3.3）
/// 約束：靠左對齊，灰色系背景，顯示 event.content.text
/// 維護：highlightRanges 依 field='text' 過濾，防止 RangeError（0.2.0-W2-011）
/// 維護：無高亮時使用 MarkdownBody 渲染；有高亮時降級為純文字（0.2.1-W1-002）
class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({
    required this.event,
    this.highlightRanges,
    super.key,
  });

  final SessionEvent event;
  final List<HighlightRange>? highlightRanges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHighlight =
        highlightRanges != null && highlightRanges!.isNotEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: ConversationConstants.bubbleMargin,
        padding: ConversationConstants.bubbleContentPadding,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(ConversationConstants.messageBubbleBorderRadius),
        ),
        child: hasHighlight
            ? _buildHighlightFallback(theme)
            : _buildMarkdownContent(theme),
      ),
    );
  }

  /// 需求：[0.2.1-W1-002] Markdown 渲染路徑
  Widget _buildMarkdownContent(ThemeData theme) {
    return MarkdownBody(
      data: event.content.text,
      selectable: true,
      shrinkWrap: true,
      styleSheet: buildBubbleMarkdownStyleSheet(theme),
    );
  }

  /// 需求：[0.2.1-W1-002] 搜尋高亮降級路徑（保留原有邏輯）
  Widget _buildHighlightFallback(ThemeData theme) {
    return buildHighlightableText(
      text: event.content.text,
      field: SearchConstants.fieldText,
      baseStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
      highlightRanges: highlightRanges,
    );
  }
}
