import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/session_list_helpers.dart';

/// 需求：[0.2.0-W4-003 Phase 4b] 共用 session 分組邏輯
/// 約束：key 順序固定 active/idle/completed，空組不含
/// 每組內按 lastEventAt 降序排列
Map<SessionStatus, List<SessionInfo>> groupSessionsByStatus(
  List<SessionInfo> sessions,
) {
  final result = <SessionStatus, List<SessionInfo>>{};
  for (final status in SessionStatus.values) {
    final group = sessions.where((s) => s.status == status).toList()
      ..sort((a, b) => b.lastEventAt.compareTo(a.lastEventAt));
    if (group.isNotEmpty) {
      result[status] = group;
    }
  }
  return result;
}

/// 需求：[0.2.1-W2-001] 按 projectPath 分組 sessions
/// 約束：空 projectPath 歸入空字串 key
Map<String, List<SessionInfo>> groupSessionsByProject(
  List<SessionInfo> sessions,
) {
  final result = <String, List<SessionInfo>>{};
  for (final session in sessions) {
    (result[session.projectPath] ??= []).add(session);
  }
  return result;
}

/// 需求：[0.2.1-W2-001] 從 project 分組中提取排序後的 projectPath 列表
/// 約束：按 extractProjectName 結果做 case-insensitive 排序
/// 約束：空 projectPath 排在最後
List<String> sortedProjectPaths(Map<String, List<SessionInfo>> grouped) {
  final keys = grouped.keys.toList();
  final nonEmpty = keys.where((k) => k.isNotEmpty).toList()
    ..sort((a, b) => extractProjectName(a)
        .toLowerCase()
        .compareTo(extractProjectName(b).toLowerCase()));
  final empty = keys.where((k) => k.isEmpty).toList();
  return [...nonEmpty, ...empty];
}
