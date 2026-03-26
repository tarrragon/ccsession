import 'package:ccsession/core/models/session_event.dart';
import 'package:flutter/material.dart';

/// 需求：工具呼叫 Bubble（Phase 1 3.3）
/// 約束：顯示 toolName，toolInput 為 null 時 graceful handling
class ToolUseBubble extends StatelessWidget {
  const ToolUseBubble({required this.event, super.key});

  final SessionEvent event;

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
        title: Text(toolName, style: const TextStyle(fontFamily: 'monospace')),
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
}
