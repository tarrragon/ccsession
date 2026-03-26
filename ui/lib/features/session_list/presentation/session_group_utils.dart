import 'package:ccsession/core/models/session_info.dart';

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
