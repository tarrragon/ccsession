import 'package:ccsession/core/constants/session_list_constants.dart';
import 'package:ccsession/core/models/session_info.dart';
import 'package:flutter/material.dart';

/// 需求：分組標題 Widget，顯示狀態名稱、session 計數和摺疊狀態
/// 範例：「> Active (3)」（展開）「v Completed (5)」（摺疊）
/// 維護：狀態名稱來自 SessionListConstants.statusDisplayName，待 l10n 後遷移
class SessionGroupHeader extends StatelessWidget {
  const SessionGroupHeader({
    super.key,
    required this.status,
    required this.count,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  final SessionStatus status;
  final int count;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final displayName = SessionListConstants.statusDisplayName(status);
    return GestureDetector(
      onTap: onToggleExpand,
      child: Padding(
        padding: SessionListConstants.groupHeaderPadding,
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: SessionListConstants.groupHeaderIconSize,
            ),
            const SizedBox(width: SessionListConstants.groupHeaderIconSpacing),
            Text(
              '$displayName ($count)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
