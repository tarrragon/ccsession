import 'package:ccsession/core/constants/conversation_constants.dart';
import 'package:ccsession/core/constants/search_constants.dart';
import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/features/conversation/presentation/widgets/bubble_markdown_style.dart';
import 'package:ccsession/features/conversation/presentation/widgets/search_highlight_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// 需求：模型思考過程 Bubble（Phase 1 3.3）
/// 約束：斜體樣式，可摺疊區塊
/// 維護：highlightRanges 依 field='text' 過濾（0.2.0-W2-011）
/// 維護：無高亮時使用 MarkdownBody（斜體基調）；有高亮時降級為 RichText（0.2.1-W1-002）
class ThinkingBubble extends StatelessWidget {
  const ThinkingBubble({
    required this.event,
    this.highlightRanges,
    super.key,
  });

  final SessionEvent event;
  final List<HighlightRange>? highlightRanges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: ConversationConstants.bubbleMargin,
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          'Thinking',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        children: [
          Padding(
            padding: ConversationConstants.bubbleContentPadding,
            child: _buildThinkingContent(theme),
          ),
        ],
      ),
    );
  }

  /// 需求：[0.2.1-W1-002] 思考內容渲染（Markdown 或降級高亮）
  Widget _buildThinkingContent(ThemeData theme) {
    final ranges = filterRangesByField(
      highlightRanges,
      SearchConstants.fieldText,
    );
    if (ranges == null || ranges.isEmpty) {
      return _buildMarkdownContent(theme);
    }
    return _buildHighlightFallback(ranges);
  }

  /// 需求：[0.2.1-W1-002] Markdown 渲染路徑（斜體基調）
  Widget _buildMarkdownContent(ThemeData theme) {
    final thinkingSheet = buildBubbleMarkdownStyleSheet(theme).copyWith(
      p: const TextStyle(fontStyle: FontStyle.italic),
    );
    return MarkdownBody(
      data: event.content.text,
      selectable: true,
      shrinkWrap: true,
      styleSheet: thinkingSheet,
    );
  }

  /// 需求：[0.2.1-W1-002] 搜尋高亮降級路徑（保留原有邏輯）
  Widget _buildHighlightFallback(List<HighlightRange> ranges) {
    const baseStyle = TextStyle(fontStyle: FontStyle.italic);
    return RichText(
      text: TextSpan(
        children: buildHighlightedSpans(
          event.content.text,
          ranges,
          baseStyle,
        ),
      ),
    );
  }
}
