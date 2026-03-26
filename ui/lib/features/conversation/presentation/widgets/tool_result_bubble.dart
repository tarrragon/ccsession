import 'package:ccsession/core/models/session_event.dart';
import 'package:flutter/material.dart';

/// 需求：工具執行結果 Bubble（Phase 1 3.3）
/// 約束：isError 時顯示紅色邊框，程式碼區塊風格
class ToolResultBubble extends StatelessWidget {
  const ToolResultBubble({required this.event, super.key});

  final SessionEvent event;

  @override
  Widget build(BuildContext context) {
    final isError = event.content.isError;
    final borderColor = isError ? Colors.red : Theme.of(context).colorScheme.outline;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          isError ? 'Error' : 'Result',
          style: TextStyle(
            fontFamily: 'monospace',
            color: isError ? Colors.red : null,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              event.content.output,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
