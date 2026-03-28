import 'package:ccsession/core/constants/conversation_constants.dart';
import 'package:ccsession/core/constants/search_constants.dart';
import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/features/conversation/presentation/widgets/search_highlight_utils.dart';
import 'package:flutter/material.dart';

/// 需求：使用者訊息 Bubble（Phase 1 3.3）
/// 約束：靠右對齊，藍色系背景，預設摺疊（ExpansionTile），標題預覽前 50 字
/// 維護：[0.2.1-W4-003] 改為 ExpansionTile 預設摺疊，避免長 prompt 干擾閱讀
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
        margin: ConversationConstants.bubbleMargin,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(
            ConversationConstants.messageBubbleBorderRadius,
          ),
        ),
        child: _buildExpansionTile(theme),
      ),
    );
  }

  /// 需求：[0.2.1-W4-003] 預設摺疊的 ExpansionTile，標題顯示前 N 字預覽
  Widget _buildExpansionTile(ThemeData theme) {
    return ExpansionTile(
      initiallyExpanded: false,
      tilePadding: ConversationConstants.bubbleContentPadding,
      childrenPadding: ConversationConstants.bubbleContentPadding,
      title: Text(
        _buildPreviewText(),
        style: theme.textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: buildHighlightableText(
            text: event.content.text,
            field: SearchConstants.fieldText,
            baseStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
            highlightRanges: highlightRanges,
          ),
        ),
      ],
    );
  }

  /// 需求：[0.2.1-W4-003] 取第一行或前 N 字作為預覽標題
  String _buildPreviewText() {
    final text = event.content.text;
    final firstLine = text.split('\n').first;
    const maxLength = ConversationConstants.userBubblePreviewMaxLength;
    if (firstLine.length <= maxLength) return firstLine;
    return '${firstLine.substring(0, maxLength)}...';
  }
}
