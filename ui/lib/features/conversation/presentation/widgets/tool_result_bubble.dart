import 'package:ccsession/core/constants/conversation_constants.dart';
import 'package:ccsession/core/constants/search_constants.dart';
import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/features/conversation/presentation/widgets/search_highlight_utils.dart';
import 'package:flutter/material.dart';

/// 需求：工具執行結果 Bubble（Phase 1 3.3）
/// 約束：isError 時顯示紅色邊框，程式碼區塊風格
/// 維護：highlightRanges 依 field='output' 過濾，防止 RangeError（0.2.0-W2-011）
class ToolResultBubble extends StatelessWidget {
  const ToolResultBubble({
    required this.event,
    this.highlightRanges,
    super.key,
  });

  final SessionEvent event;
  final List<HighlightRange>? highlightRanges;

  @override
  Widget build(BuildContext context) {
    final isError = event.content.isError;
    final borderColor =
        isError ? ConversationConstants.errorColor : Theme.of(context).colorScheme.outline;

    return Container(
      margin: ConversationConstants.bubbleMargin,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          isError ? 'Error' : 'Result',
          style: ConversationConstants.monospaceStyle.copyWith(
            color: isError ? ConversationConstants.errorColor : null,
          ),
        ),
        children: [
          Padding(
            padding: ConversationConstants.bubbleContentPadding,
            child: buildHighlightableText(
              text: event.content.output,
              field: SearchConstants.fieldOutput,
              baseStyle: ConversationConstants.monospaceStyle,
              highlightRanges: highlightRanges,
            ),
          ),
        ],
      ),
    );
  }

}
