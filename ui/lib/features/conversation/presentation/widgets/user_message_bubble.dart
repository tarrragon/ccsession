import 'package:ccsession/core/models/session_event.dart';
import 'package:flutter/material.dart';

/// 需求：使用者訊息 Bubble（Phase 1 3.3）
/// 約束：靠右對齊，藍色系背景，顯示 event.content.text
class UserMessageBubble extends StatelessWidget {
  const UserMessageBubble({required this.event, super.key});

  final SessionEvent event;

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
        child: Text(event.content.text),
      ),
    );
  }
}
