import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/models/session_info.dart';

final baseTime = DateTime(2026, 3, 25, 10, 0);

SessionInfo createTestSession({
  String id = 'session-1',
  String projectPath = '/Users/test/project',
  String summary = 'Test summary',
  SessionStatus status = SessionStatus.active,
  DateTime? lastEventAt,
  String lastMessage = '',
  String agentName = 'claude',
  String agentType = '',
}) {
  return SessionInfo(
    id: id,
    projectPath: projectPath,
    summary: summary,
    status: status,
    firstEventAt: baseTime,
    lastEventAt: lastEventAt ?? baseTime,
    lastMessage: lastMessage,
    agentName: agentName,
    agentType: agentType,
  );
}

ServerMessage createSessionListMessage(List<SessionInfo> sessions) {
  return ServerMessage(
    type: 'session_list',
    data: {
      'sessions': sessions.map((s) => s.toJson()).toList(),
    },
  );
}
