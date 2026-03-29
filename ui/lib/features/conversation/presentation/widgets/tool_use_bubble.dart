import 'package:ccsession/core/constants/conversation_constants.dart';
import 'package:ccsession/core/constants/search_constants.dart';
import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/features/conversation/presentation/widgets/json_format_helper.dart';
import 'package:ccsession/features/conversation/presentation/widgets/search_highlight_utils.dart';
import 'package:flutter/material.dart';

/// 需求：工具呼叫 Bubble（Phase 1 3.3）
/// 約束：顯示 toolName，toolInput 為 null 時 graceful handling
/// 維護：highlightRanges 依 field='toolName' 過濾，防止 RangeError（0.2.0-W2-011）
class ToolUseBubble extends StatelessWidget {
  const ToolUseBubble({
    required this.event,
    this.highlightRanges,
    super.key,
  });

  final SessionEvent event;
  final List<HighlightRange>? highlightRanges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toolName = event.content.toolName;
    final toolInput = event.content.toolInput;

    return Container(
      margin: ConversationConstants.bubbleMargin,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(ConversationConstants.toolBubbleBorderRadius),
      ),
      child: ExpansionTile(
        title: buildHighlightableText(
          text: toolName,
          field: SearchConstants.fieldToolName,
          baseStyle: ConversationConstants.monospaceStyle,
          highlightRanges: highlightRanges,
        ),
        children: [
          if (toolInput != null)
            Padding(
              padding: ConversationConstants.bubbleContentPadding,
              child: SelectableText(
                formatJsonObject(toolInput),
                style: ConversationConstants.monospaceStyle,
              ),
            ),
        ],
      ),
    );
  }

}
