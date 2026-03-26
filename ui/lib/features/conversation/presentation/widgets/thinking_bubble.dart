import 'package:ccsession/core/models/session_event.dart';
import 'package:flutter/material.dart';

/// 需求：模型思考過程 Bubble（Phase 1 3.3）
/// 約束：斜體樣式，可摺疊區塊
class ThinkingBubble extends StatelessWidget {
  const ThinkingBubble({required this.event, super.key});

  final SessionEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          'Thinking',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              event.content.text,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
