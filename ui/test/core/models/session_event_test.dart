import 'package:ccsession/core/models/session_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-02: SessionEvent + EventContent JSON 序列化', () {
    /// TC-02-01: SessionEvent 完整欄位反序列化
    test('SessionEvent 完整欄位反序列化', () {
      final json = <String, dynamic>{
        'sessionId': 's1',
        'projectPath': '/p',
        'type': 'human',
        'timestamp': '2026-03-25T10:00:00.000Z',
        'messageId': 'msg-1',
        'contentIndex': 0,
        'isLastContent': true,
        'content': {
          'text': 'hello',
          'toolName': '',
          'toolUseId': '',
          'output': '',
          'isError': false,
        },
        'toolName': '',
      };

      final result = SessionEvent.fromJson(json);

      expect(result.content.text, 'hello');
      expect(result.isLastContent, isTrue);
    });

    /// TC-02-02: SessionEvent 最小欄位反序列化
    test('SessionEvent 最小欄位反序列化', () {
      final json = <String, dynamic>{
        'sessionId': 's1',
        'type': 'assistant',
        'timestamp': '2026-03-25T10:00:00.000Z',
        'content': <String, dynamic>{},
      };

      final result = SessionEvent.fromJson(json);

      expect(result.projectPath, '');
      expect(result.contentIndex, -1);
      expect(result.isLastContent, isFalse);
    });

    /// TC-02-03: EventContent 含 toolInput
    test('EventContent 含 toolInput', () {
      final json = <String, dynamic>{
        'text': '',
        'toolName': 'read',
        'toolInput': {'key': 'value'},
        'toolUseId': 'tu1',
        'output': '',
        'isError': false,
      };

      final result = EventContent.fromJson(json);

      expect(result.toolInput, isA<Map<String, dynamic>>());
      expect((result.toolInput! as Map<String, dynamic>)['key'], 'value');
    });

    /// TC-02-04: EventContent 空物件
    test('EventContent 空物件', () {
      final json = <String, dynamic>{};

      final result = EventContent.fromJson(json);

      expect(result.text, '');
      expect(result.isError, isFalse);
      expect(result.toolInput, isNull);
    });

    /// TC-02-05a: SessionEvent fallback 格式（Hook 來源，缺少 type/timestamp/content）
    test('SessionEvent fallback 格式安全解析', () {
      final json = <String, dynamic>{
        'sessionId': 's1',
        'agentId': 'agent-1',
      };

      final result = SessionEvent.fromJson(json);

      expect(result.sessionId, 's1');
      expect(result.type, '');
      expect(result.timestamp, isNull);
      expect(result.isComplete, isFalse);
    });

    /// TC-02-05b: SessionEvent 完整格式 isComplete 為 true
    test('SessionEvent 完整格式 isComplete 為 true', () {
      final json = <String, dynamic>{
        'sessionId': 's1',
        'type': 'human',
        'timestamp': '2026-03-25T10:00:00.000Z',
        'content': {'text': 'hello'},
      };

      final result = SessionEvent.fromJson(json);

      expect(result.isComplete, isTrue);
    });

    /// TC-02-05: SessionEvent toJson 往返
    test('SessionEvent toJson 往返', () {
      final original = SessionEvent(
        sessionId: 's1',
        projectPath: '/p',
        type: 'human',
        timestamp: DateTime.utc(2026, 3, 25, 10),
        messageId: 'msg-1',
        contentIndex: 0,
        isLastContent: true,
        content: const EventContent(text: 'hello'),
        toolName: '',
      );

      final roundTrip = SessionEvent.fromJson(original.toJson());

      expect(roundTrip, original);
    });
  });
}
