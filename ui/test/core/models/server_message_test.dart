import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/core/models/session_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-03: ServerMessage 信封 + Payload', () {
    /// TC-03-01: ServerMessage 信封反序列化
    test('ServerMessage 信封反序列化', () {
      final json = <String, dynamic>{
        'type': 'session_list',
        'data': <String, dynamic>{'sessions': <dynamic>[]},
      };

      final result = ServerMessage.fromJson(json);

      expect(result.type, 'session_list');
      expect(result.data, isA<Map<String, dynamic>>());
    });

    /// TC-03-02: SessionListData 反序列化
    test('SessionListData 反序列化', () {
      final sessionJson = <String, dynamic>{
        'id': 's1',
        'projectPath': '/p',
        'status': 'active',
        'firstEventAt': '2026-03-25T10:00:00.000Z',
        'lastEventAt': '2026-03-25T10:05:00.000Z',
      };
      final json = <String, dynamic>{
        'sessions': [sessionJson, sessionJson],
      };

      final result = SessionListData.fromJson(json);

      expect(result.sessions.length, 2);
      expect(result.sessions[0], isA<SessionInfo>());
    });

    /// TC-03-03: SessionListData 空列表
    test('SessionListData 空列表', () {
      final json = <String, dynamic>{
        'sessions': <dynamic>[],
      };

      final result = SessionListData.fromJson(json);

      expect(result.sessions.length, 0);
    });

    /// TC-03-04: SessionEventData 反序列化
    test('SessionEventData 反序列化', () {
      final json = <String, dynamic>{
        'sessionId': 's1',
        'agentId': 'a1',
      };

      final result = SessionEventData.fromJson(json);

      expect(result.sessionId, 's1');
      expect(result.agentId, 'a1');
    });

    /// TC-03-05: SessionStatusChangeData 反序列化
    test('SessionStatusChangeData 反序列化', () {
      final json = <String, dynamic>{
        'sessionId': 's1',
        'status': 'idle',
      };

      final result = SessionStatusChangeData.fromJson(json);

      expect(result.sessionId, 's1');
      expect(result.status, SessionStatus.idle);
    });

    /// TC-03-06: SessionHistoryData 反序列化
    test('SessionHistoryData 反序列化', () {
      final eventJson = <String, dynamic>{
        'sessionId': 's1',
        'type': 'human',
        'timestamp': '2026-03-25T10:00:00.000Z',
        'content': <String, dynamic>{},
      };
      final json = <String, dynamic>{
        'sessionId': 's1',
        'events': [eventJson],
        'hasMore': true,
      };

      final result = SessionHistoryData.fromJson(json);

      expect(result.events.length, 1);
      expect(result.hasMore, isTrue);
    });

    /// TC-03-07: SessionHistoryData hasMore 預設值
    test('SessionHistoryData hasMore 預設值', () {
      final json = <String, dynamic>{
        'sessionId': 's1',
        'events': <dynamic>[],
      };

      final result = SessionHistoryData.fromJson(json);

      expect(result.hasMore, isFalse);
    });

    /// TC-03-08: ErrorData 反序列化
    test('ErrorData 反序列化', () {
      final json = <String, dynamic>{'code': 'SESSION_NOT_FOUND'};

      final result = ErrorData.fromJson(json);

      expect(result.code, 'SESSION_NOT_FOUND');
    });

    /// TC-03-09: 各 payload toJson 往返
    test('各 payload toJson 往返', () {
      // SessionListData
      final sessionListData = SessionListData(
        sessions: [
          SessionInfo(
            id: 's1',
            projectPath: '/p',
            status: SessionStatus.active,
            firstEventAt: DateTime.utc(2026),
            lastEventAt: DateTime.utc(2026),
          ),
        ],
      );
      expect(
        SessionListData.fromJson(sessionListData.toJson()),
        sessionListData,
      );

      // SessionEventData
      const eventData = SessionEventData(sessionId: 's1', agentId: 'a1');
      expect(SessionEventData.fromJson(eventData.toJson()), eventData);

      // SessionStatusChangeData
      const statusData = SessionStatusChangeData(
        sessionId: 's1',
        status: SessionStatus.idle,
      );
      expect(
        SessionStatusChangeData.fromJson(statusData.toJson()),
        statusData,
      );

      // SessionHistoryData
      final historyData = SessionHistoryData(
        sessionId: 's1',
        events: [
          SessionEvent(
            sessionId: 's1',
            type: 'human',
            timestamp: DateTime.utc(2026),
            content: const EventContent(),
          ),
        ],
        hasMore: true,
      );
      expect(
        SessionHistoryData.fromJson(historyData.toJson()),
        historyData,
      );

      // ErrorData
      const errorData = ErrorData(code: 'INTERNAL_ERROR');
      expect(ErrorData.fromJson(errorData.toJson()), errorData);
    });
  });
}
