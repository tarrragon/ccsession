import 'package:ccsession/core/constants/conversation_constants.dart';
import 'package:ccsession/core/constants/search_constants.dart';
import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/features/conversation/presentation/widgets/search_highlight_utils.dart';
import 'package:flutter/material.dart';

/// 需求：助手訊息 Bubble（Phase 1 3.3）
/// 約束：靠左對齊，灰色系背景，顯示 event.content.text
/// 維護：highlightRanges 依 field='text' 過濾，防止 RangeError（0.2.0-W2-011）
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: ConversationConstants.bubbleMargin,
        padding: ConversationConstants.bubbleContentPadding,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: buildHighlightableText(
          text: event.content.text,
          field: SearchConstants.fieldText,
          baseStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
          highlightRanges: highlightRanges,
        ),
      ),
    );
  }
}
