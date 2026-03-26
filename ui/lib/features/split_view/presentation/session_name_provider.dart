import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_name_provider.g.dart';

/// 需求：UC-004 從 session 列表中解析 session 顯示名稱
/// 約束：sessionId 為 null 時回傳空字串，找不到或 agentName 為空時 fallback 為 sessionId
@riverpod
String sessionName(SessionNameRef ref, {required String? sessionId}) {
  if (sessionId == null) return '';
  final sessionListState =
      ref.watch(sessionListNotifierProvider).valueOrNull;
  if (sessionListState == null) return sessionId;
  final matches = sessionListState.sessions.where((s) => s.id == sessionId);
  if (matches.isEmpty) return sessionId;
  final name = matches.first.agentName;
  return name.isNotEmpty ? name : sessionId;
}
