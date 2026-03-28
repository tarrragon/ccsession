import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/session_group_utils.dart';
import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:ccsession/features/session_list/presentation/session_list_search_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'filtered_grouped_sessions_provider.g.dart';

/// 需求：[0.2.0-W4-003] 篩選後的分組 session 列表（computed provider）
/// 約束：依賴 sessionListNotifier 和 searchNotifier，任一變化自動重算
/// 約束：空 query（trim 後）回傳完整列表；非空則 case-insensitive contains
/// 約束：若指定 projectPath，先按 projectPath 過濾
@riverpod
Map<SessionStatus, List<SessionInfo>> filteredGroupedSessions(
  FilteredGroupedSessionsRef ref, {
  String? projectPath,
}) {
  final sessionListState =
      ref.watch(sessionListNotifierProvider).valueOrNull;
  if (sessionListState == null) return {};

  final sessions = _filterByProject(sessionListState.sessions, projectPath);
  final searchState = ref.watch(sessionListSearchNotifierProvider);

  return _filterByQuery(sessions, searchState.query);
}

/// 需求：按 projectPath 過濾 sessions
List<SessionInfo> _filterByProject(
  List<SessionInfo> sessions,
  String? projectPath,
) {
  if (projectPath == null) return sessions;
  return sessions.where((s) => s.projectPath == projectPath).toList();
}

/// 需求：按搜尋字串過濾並分組
/// 約束：空 query 回傳全部；非空則任一欄位 case-insensitive 匹配
Map<SessionStatus, List<SessionInfo>> _filterByQuery(
  List<SessionInfo> sessions,
  String query,
) {
  final trimmedQuery = query.trim();
  if (trimmedQuery.isEmpty) {
    return groupSessionsByStatus(sessions);
  }

  final normalizedQuery = trimmedQuery.toLowerCase();
  final filtered = sessions.where(
    (session) => _matchesQuery(session, normalizedQuery),
  ).toList();

  return groupSessionsByStatus(filtered);
}

/// 需求：檢查 session 是否匹配查詢字串（任一欄位匹配即可）
bool _matchesQuery(SessionInfo session, String normalizedQuery) {
  final fields = [
    session.summary,
    session.projectPath,
    session.agentName,
    session.lastMessage,
  ];
  return fields.any(
    (field) => field.toLowerCase().contains(normalizedQuery),
  );
}
