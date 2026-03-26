import 'package:ccsession/features/conversation/domain/search_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_conversation_factory.dart';

void main() {
  group('TG-SEARCH-HELPER: extractSearchableText', () {
    // TC-SEARCH-01
    test('user event 回傳 [{field: text, text: content}]', () {
      final event = createUserEvent('Hello world');
      final result = extractSearchableText(event);

      expect(result, hasLength(1));
      expect(result[0].field, 'text');
      expect(result[0].text, 'Hello world');
    });

    // TC-SEARCH-02
    test('assistant event 回傳 [{field: text, text: content}]', () {
      final event = createAssistantEvent('I can help');
      final result = extractSearchableText(event);

      expect(result, hasLength(1));
      expect(result[0].field, 'text');
      expect(result[0].text, 'I can help');
    });

    // TC-SEARCH-03
    test('thinking event（非空）回傳 [{field: text, text: content}]', () {
      final event = createThinkingEvent('Let me think...');
      final result = extractSearchableText(event);

      expect(result, hasLength(1));
      expect(result[0].field, 'text');
      expect(result[0].text, 'Let me think...');
    });

    // TC-SEARCH-04
    test('thinking event（空文字）回傳空列表', () {
      final event = createThinkingEvent('');
      final result = extractSearchableText(event);

      expect(result, isEmpty);
    });

    // TC-SEARCH-05
    test('tool_use event 回傳 toolName 和 text 欄位', () {
      final event = createTestEvent(
        type: 'tool_use',
        toolName: 'Read',
        text: '/file.dart',
      );
      final result = extractSearchableText(event);

      expect(result, hasLength(2));
      expect(result[0].field, 'toolName');
      expect(result[0].text, 'Read');
      expect(result[1].field, 'text');
      expect(result[1].text, '/file.dart');
    });

    // TC-SEARCH-06
    test('tool_result event 回傳 output 和 text 欄位', () {
      final event = createTestEvent(
        type: 'tool_result',
        output: 'file contents',
        text: 'summary',
      );
      final result = extractSearchableText(event);

      expect(result, hasLength(2));
      expect(result[0].field, 'output');
      expect(result[0].text, 'file contents');
      expect(result[1].field, 'text');
      expect(result[1].text, 'summary');
    });

    // TC-SEARCH-07
    test('未知 event type 回傳空列表', () {
      final event = createTestEvent(type: 'unknown_type', text: 'something');
      final result = extractSearchableText(event);

      expect(result, isEmpty);
    });
  });

  group('TG-SEARCH-HELPER: findAllMatches', () {
    // TC-SEARCH-08
    test('單一匹配', () {
      final result = findAllMatches('Hello world', 'world');

      expect(result, hasLength(1));
      expect(result[0].start, 6);
      expect(result[0].end, 11);
    });

    // TC-SEARCH-09
    test('多重匹配', () {
      final result = findAllMatches('error in error handling', 'error');

      expect(result, hasLength(2));
      expect(result[0].start, 0);
      expect(result[0].end, 5);
      expect(result[1].start, 9);
      expect(result[1].end, 14);
    });

    // TC-SEARCH-10
    test('大小寫不敏感', () {
      final result = findAllMatches('Error ERROR error', 'error');

      expect(result, hasLength(3));
      expect(result[0].start, 0);
      expect(result[0].end, 5);
      expect(result[1].start, 6);
      expect(result[1].end, 11);
      expect(result[2].start, 12);
      expect(result[2].end, 17);
    });

    // TC-SEARCH-11
    test('無匹配', () {
      final result = findAllMatches('Hello world', 'xyz');

      expect(result, isEmpty);
    });

    // TC-SEARCH-12
    test('空 query 回傳空列表', () {
      final result = findAllMatches('Hello world', '');

      expect(result, isEmpty);
    });

    // TC-SEARCH-13
    test('特殊字元（字面匹配，非正則）', () {
      final result = findAllMatches('file.dart (main)', '.dart');

      expect(result, hasLength(1));
      expect(result[0].start, 4);
      expect(result[0].end, 9);
    });

    // TC-SEARCH-14
    test('重疊匹配處理（非重疊，從 end 開始）', () {
      final result = findAllMatches('aaa', 'aa');

      expect(result, hasLength(1));
      expect(result[0].start, 0);
      expect(result[0].end, 2);
    });
  });
}
