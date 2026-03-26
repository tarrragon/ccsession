import 'package:ccsession/core/models/session_event.dart';
import 'package:flutter/material.dart';

/// 需求：助手訊息 Bubble（Phase 1 3.3）
/// 約束：靠左對齊，灰色系背景，顯示 event.content.text
class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({required this.event, super.key});

  final SessionEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(event.content.text),
      ),
    );
  }
}
