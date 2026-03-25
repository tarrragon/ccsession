import 'package:ccsession/core/constants/session_list_constants.dart';
import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/session_list_helpers.dart';
import 'package:ccsession/features/session_list/presentation/widgets/status_indicator.dart';
import 'package:flutter/material.dart';

/// 需求：單一 session 項目 Widget
/// 顯示：摘要、專案名稱、agentName（gitBranch fallback）、相對時間、狀態指示燈
/// 約束：點擊觸發 onTap callback
class SessionListTile extends StatelessWidget {
  const SessionListTile({
    super.key,
    required this.session,
    required this.isSelected,
    this.onTap,
  });

  final SessionInfo session;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.3,
      ),
      leading: StatusIndicator(status: session.status),
      title: Text(
        _displaySummary(session),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _buildSubtitle(session),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// 需求：摘要 fallback 邏輯
/// 優先級：summary > lastMessage 前 N 字元 > id 前 8 字元
String _displaySummary(SessionInfo session) {
  if (session.summary.isNotEmpty) {
    return session.summary;
  }
  if (session.lastMessage.isNotEmpty) {
    final maxLen = SessionListConstants.summaryFallbackMaxLength;
    if (session.lastMessage.length > maxLen) {
      return session.lastMessage.substring(0, maxLen);
    }
    return session.lastMessage;
  }
  return session.id.substring(
    0,
    session.id.length < SessionListConstants.sessionIdFallbackLength
        ? session.id.length
        : SessionListConstants.sessionIdFallbackLength,
  );
}

/// 需求：副標題組合專案名稱和 agentName
String _buildSubtitle(SessionInfo session) {
  final projectName = extractProjectName(session.projectPath);
  final parts = <String>[
    if (projectName.isNotEmpty) projectName,
    if (session.agentName.isNotEmpty) session.agentName,
  ];
  return parts.join(' / ');
}
