import 'package:ccsession/core/constants/conversation_constants.dart';
import 'package:ccsession/core/constants/search_constants.dart';
import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/features/conversation/presentation/widgets/search_highlight_utils.dart';
import 'package:flutter/material.dart';

/// 需求：模型思考過程 Bubble（Phase 1 3.3）
/// 約束：斜體樣式，可摺疊區塊
/// 維護：highlightRanges 依 field='text' 過濾（0.2.0-W2-011）
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
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
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
            child: _buildThinkingContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingContent() {
    final ranges = filterRangesByField(highlightRanges, SearchConstants.fieldText);
    if (ranges == null || ranges.isEmpty) {
      return Text(
        event.content.text,
        style: const TextStyle(fontStyle: FontStyle.italic),
      );
    }
    const baseStyle = TextStyle(fontStyle: FontStyle.italic);
    return RichText(
      text: TextSpan(
        children: buildHighlightedSpans(event.content.text, ranges, baseStyle),
      ),
    );
  }
}
