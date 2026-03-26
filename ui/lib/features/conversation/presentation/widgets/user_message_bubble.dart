import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/core/constants/search_constants.dart';
import 'package:ccsession/features/conversation/presentation/widgets/search_highlight_utils.dart';
import 'package:flutter/material.dart';

/// 需求：使用者訊息 Bubble（Phase 1 3.3）
/// 約束：靠右對齊，藍色系背景，顯示 event.content.text
/// 維護：highlightRanges 依 field='text' 過濾，防止 RangeError（0.2.0-W2-011）
class UserMessageBubble extends StatelessWidget {
  const UserMessageBubble({
    required this.event,
    this.highlightRanges,
    super.key,
  });

  final SessionEvent event;
  final List<HighlightRange>? highlightRanges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _buildTextContent(theme),
      ),
    );
  }

  Widget _buildTextContent(ThemeData theme) {
    final ranges = filterRangesByField(highlightRanges, SearchConstants.fieldText);
    if (ranges == null || ranges.isEmpty) {
      return Text(event.content.text);
    }
    return RichText(
      text: TextSpan(
        children: buildHighlightedSpans(
          event.content.text,
          ranges,
          theme.textTheme.bodyMedium ?? const TextStyle(),
        ),
      ),
    );
  }
}
