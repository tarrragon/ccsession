import 'package:ccsession/core/models/session_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-01: SessionInfo JSON 序列化', () {
    /// TC-01-01: 完整欄位 JSON 反序列化
    test('完整欄位 JSON 反序列化', () {
      final json = <String, dynamic>{
        'id': 'session-abc',
        'projectPath': '/path/to/project',
        'summary': 'Test session',
        'status': 'active',
        'firstEventAt': '2026-03-25T10:00:00.000Z',
        'lastEventAt': '2026-03-25T10:05:00.000Z',
        'firstUserMessageAt': '2026-03-25T10:01:00.000Z',
        'eventCount': 42,
        'agentId': 'agent-1',
        'agentType': 'main',
        'lastMessage': 'Hello',
        'parentAgentId': '',
        'agentName': 'claude',
      };
      expect(json, isNotNull);
      expect(json.containsKey('id'), isTrue);

      final result = SessionInfo.fromJson(json);

      expect(result.id, 'session-abc');
      expect(result.status, SessionStatus.active);
      expect(result.eventCount, 42);
      expect(result.firstUserMessageAt, isNotNull);
    });

    /// TC-01-02: 最小欄位 JSON 反序列化
    test('最小欄位 JSON — @Default 填入預設值', () {
      final json = <String, dynamic>{
        'id': 'session-min',
        'projectPath': '/p',
        'status': 'idle',
        'firstEventAt': '2026-03-25T10:00:00.000Z',
        'lastEventAt': '2026-03-25T10:05:00.000Z',
      };
      expect(json.containsKey('summary'), isFalse);
      expect(json.containsKey('eventCount'), isFalse);
      expect(json.containsKey('agentId'), isFalse);

      final result = SessionInfo.fromJson(json);

      expect(result.summary, '');
      expect(result.eventCount, 0);
      expect(result.agentId, '');
      expect(result.firstUserMessageAt, isNull);
    });

    /// TC-01-03: SessionStatus enum JSON 對應
    test('SessionStatus enum JSON 對應', () {
      final statuses = ['active', 'idle', 'completed'];
      final expected = [
        SessionStatus.active,
        SessionStatus.idle,
        SessionStatus.completed,
      ];

      for (var i = 0; i < statuses.length; i++) {
        final json = <String, dynamic>{
          'id': 's$i',
          'projectPath': '/p',
          'status': statuses[i],
          'firstEventAt': '2026-03-25T10:00:00.000Z',
          'lastEventAt': '2026-03-25T10:05:00.000Z',
        };
        final result = SessionInfo.fromJson(json);
        expect(result.status, expected[i]);
      }
    });

    /// TC-01-04: toJson 往返
    test('toJson 往返', () {
      final original = SessionInfo(
        id: 'session-rt',
        projectPath: '/path',
        summary: 'roundtrip',
        status: SessionStatus.active,
        firstEventAt: DateTime.utc(2026, 3, 25, 10),
        lastEventAt: DateTime.utc(2026, 3, 25, 10, 5),
        firstUserMessageAt: DateTime.utc(2026, 3, 25, 10, 1),
        eventCount: 10,
        agentId: 'a1',
        agentType: 'main',
        lastMessage: 'hi',
        parentAgentId: 'p1',
        agentName: 'claude',
      );

      final roundTrip = SessionInfo.fromJson(original.toJson());

      expect(roundTrip, original);
    });

    /// TC-01-05: freezed equality 和 copyWith
    test('freezed equality 和 copyWith', () {
      final a = SessionInfo(
        id: 's1',
        projectPath: '/p',
        status: SessionStatus.idle,
        firstEventAt: DateTime.utc(2026),
        lastEventAt: DateTime.utc(2026),
      );
      final b = SessionInfo(
        id: 's1',
        projectPath: '/p',
        status: SessionStatus.idle,
        firstEventAt: DateTime.utc(2026),
        lastEventAt: DateTime.utc(2026),
      );

      expect(a, b);

      final copied = a.copyWith(summary: 'new');
      expect(copied.summary, 'new');
      expect(copied.id, a.id);
    });
  });
}
