import 'package:ccsession/core/constants/session_list_constants.dart';
import 'package:ccsession/core/models/session_info.dart';
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
        _sessionTitle(session),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _sessionSubtitle(session),
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

/// 需求：[0.2.1-W2-003] 標題顯示（含 Agent 前綴）
/// 優先級：agentType 非空時加 [Agent] 前綴 + fallback 文字
String _sessionTitle(SessionInfo session) {
  final titleText = _buildTitleText(session);
  if (session.agentType.isNotEmpty) {
    return '${SessionListConstants.agentTitlePrefix} $titleText';
  }
  return titleText;
}

/// 需求：摘要 fallback 邏輯
/// 優先級：summary > lastMessage 前 N 字元 > id 前 8 字元
String _buildTitleText(SessionInfo session) {
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

/// 需求：[0.2.1-W2-003] 副標題只顯示 agentName
/// 約束：v0.2 中 agentName 永遠為空字串，v0.3 填充後自動生效
String _sessionSubtitle(SessionInfo session) {
  return session.agentName;
}
