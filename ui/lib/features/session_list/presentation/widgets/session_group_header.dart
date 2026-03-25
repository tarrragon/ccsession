import 'package:ccsession/core/constants/session_list_constants.dart';
import 'package:ccsession/core/models/session_info.dart';
import 'package:flutter/material.dart';

/// 需求：分組標題 Widget，顯示狀態名稱和 session 計數
/// 範例：「Active (3)」「Idle (1)」「Completed (5)」
/// 維護：狀態名稱來自 SessionListConstants.statusDisplayName，待 l10n 後遷移
class SessionGroupHeader extends StatelessWidget {
  const SessionGroupHeader({
    super.key,
    required this.status,
    required this.count,
  });

  final SessionStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final displayName = SessionListConstants.statusDisplayName(status);
    return Padding(
      padding: SessionListConstants.groupHeaderPadding,
      child: Text(
        '$displayName ($count)',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
