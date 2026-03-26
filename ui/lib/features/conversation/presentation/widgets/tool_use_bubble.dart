import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/features/conversation/presentation/widgets/search_highlight_utils.dart';
import 'package:flutter/material.dart';

/// 需求：工具呼叫 Bubble（Phase 1 3.3）
/// 約束：顯示 toolName，toolInput 為 null 時 graceful handling
/// 維護：highlightRanges 由搜尋功能注入，無值時行為不變（0.2.0-W2-005）
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
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: _buildToolNameTitle(toolName, theme),
        children: [
          if (toolInput != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(toolInput.toString()),
            ),
        ],
      ),
    );
  }

  Widget _buildToolNameTitle(String toolName, ThemeData theme) {
    final ranges = highlightRanges;
    if (ranges == null || ranges.isEmpty) {
      return Text(toolName, style: const TextStyle(fontFamily: 'monospace'));
    }
    const baseStyle = TextStyle(fontFamily: 'monospace');
    return RichText(
      text: TextSpan(
        children: buildHighlightedSpans(toolName, ranges, baseStyle),
      ),
    );
  }
}
