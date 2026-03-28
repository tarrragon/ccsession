import 'package:ccsession/core/constants/conversation_constants.dart';
import 'package:flutter/material.dart';

/// 需求：[0.2.1-W4-003] 空內容事件的 fallback 顯示 Bubble
/// 約束：顯示事件類型和 fallback 提示文字，避免空框
/// 維護：所有事件類型（user/assistant/tool_use/tool_result/thinking）共用
class EmptyContentBubble extends StatelessWidget {
  const EmptyContentBubble({
    required this.eventType,
    this.alignment = Alignment.centerLeft,
    super.key,
  });

  final String eventType;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: alignment,
      child: Container(
        margin: ConversationConstants.bubbleMargin,
        padding: ConversationConstants.bubbleContentPadding,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(
            ConversationConstants.toolBubbleBorderRadius,
          ),
        ),
        child: Text(
          '[$eventType] ${ConversationConstants.emptyContentFallback}',
          style: ConversationConstants.emptyContentStyle,
        ),
      ),
    );
  }
}
