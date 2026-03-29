import 'dart:convert';

import 'package:ccsession/features/conversation/presentation/widgets/json_format_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatJsonContent', () {
    test('formats valid JSON object with indentation', () {
      const input = '{"name":"test","value":42}';
      final result = formatJsonContent(input);

      expect(result, contains('"name": "test"'));
      expect(result, contains('"value": 42'));
      expect(result, contains('\n'));
    });

    test('formats valid JSON array with indentation', () {
      const input = '[1,2,3]';
      final result = formatJsonContent(input);

      expect(result, '[\n  1,\n  2,\n  3\n]');
    });

    test('returns original string for non-JSON content', () {
      const input = 'This is plain text output';
      final result = formatJsonContent(input);

      expect(result, input);
    });

    test('returns original string for empty string', () {
      const input = '';
      final result = formatJsonContent(input);

      expect(result, input);
    });

    test('returns original string for partial JSON', () {
      const input = '{"incomplete": ';
      final result = formatJsonContent(input);

      expect(result, input);
    });

    test('formats nested JSON objects', () {
      const input = '{"outer":{"inner":"value"}}';
      final result = formatJsonContent(input);

      expect(result, contains('  "outer"'));
      expect(result, contains('    "inner"'));
    });

    test('handles JSON string primitive', () {
      const input = '"just a string"';
      final result = formatJsonContent(input);

      expect(result, '"just a string"');
    });

    test('unescapes \\n in string values to actual newlines', () {
      const input = '{"prompt":"## Title\\n\\nContent"}';
      final result = formatJsonContent(input);

      expect(result, contains('## Title\n\nContent'));
    });

    test('unescapes \\t in string values to actual tabs', () {
      const input = '{"code":"line1\\n\\tindented"}';
      final result = formatJsonContent(input);

      expect(result, contains('line1\n\tindented'));
    });

    test('unescapes \\" in string values to actual quotes', () {
      const input = '{"text":"He said \\"hello\\""}';
      final result = formatJsonContent(input);

      expect(result, contains('He said "hello"'));
    });

    test('unescapes \\\\ in string values to actual backslash', () {
      const input = '{"path":"C:\\\\Users\\\\file"}';
      final result = formatJsonContent(input);

      expect(result, contains('C:\\Users\\file'));
    });

    test('handles mixed escape sequences in correct order', () {
      const input = '{"text":"line1\\npath\\\\dir\\\\file\\tand \\"quoted\\""}';
      final result = formatJsonContent(input);

      expect(result, contains('line1\npath\\dir\\file\tand "quoted"'));
    });
  });

  group('formatJsonObject', () {
    test('formats Map object with indentation', () {
      final input = <String, dynamic>{'name': 'test', 'value': 42};
      final result = formatJsonObject(input);

      expect(result, contains('"name": "test"'));
      expect(result, contains('"value": 42'));
      expect(result, contains('\n'));
    });

    test('formats nested Map object', () {
      final input = <String, dynamic>{
        'outer': <String, dynamic>{'inner': 'value'},
      };
      final result = formatJsonObject(input);

      expect(result, contains('  "outer"'));
      expect(result, contains('    "inner"'));
    });

    test('formats List object', () {
      final input = <int>[1, 2, 3];
      final result = formatJsonObject(input);

      expect(result, '[\n  1,\n  2,\n  3\n]');
    });

    test('returns empty string for null', () {
      final result = formatJsonObject(null);

      expect(result, '');
    });

    test('formats JSON string value by decoding first', () {
      const input = '{"file_path":"/path","limit":35}';
      final result = formatJsonObject(input);

      expect(result, contains('"file_path": "/path"'));
      expect(result, contains('"limit": 35'));
      expect(result, contains('\n'));
    });

    test('returns plain string for non-JSON string', () {
      final result = formatJsonObject('hello');

      expect(result, 'hello');
    });

    test('formats numeric value', () {
      final result = formatJsonObject(42);

      expect(result, '42');
    });

    test('returns toString for unsupported object', () {
      final result = formatJsonObject(DateTime(2026));

      expect(result, isNotEmpty);
    });

    test('unescapes \\n in Map string values to actual newlines', () {
      final input = <String, dynamic>{
        'prompt': '## Title\n\nContent with\nnewlines',
      };
      final result = formatJsonObject(input);

      expect(result, contains('## Title\n\nContent with\nnewlines'));
    });

    test('unescapes \\n in JSON string input to actual newlines', () {
      const input = '{"prompt":"## Title\\n\\nContent"}';
      final result = formatJsonObject(input);

      expect(result, contains('## Title\n\nContent'));
    });
  });

  group('formatKeyValue', () {
    group('A: 正常流程', () {
      test('A1: 扁平 Map — 基本 key-value 格式化', () {
        final input = <String, dynamic>{
          'file_path': '/main.dart',
          'limit': 100,
        };
        final result = formatKeyValue(input);

        expect(result, 'file_path: /main.dart\nlimit: 100');
      });

      test('A2: 單一 key-value', () {
        final input = <String, dynamic>{'name': 'test'};
        final result = formatKeyValue(input);

        expect(result, 'name: test');
      });

      test('A3: value 為數值和布林型別', () {
        final input = <String, dynamic>{
          'count': 42,
          'ratio': 3.14,
          'enabled': true,
        };
        final result = formatKeyValue(input);

        expect(result, contains('count: 42'));
        expect(result, contains('ratio: 3.14'));
        expect(result, contains('enabled: true'));
      });

      test('A4: value 含跳脫字元的字串', () {
        final input = <String, dynamic>{
          'content': 'line1\\nline2\\ttab',
        };
        final result = formatKeyValue(input);

        expect(result, contains('content: line1\nline2\ttab'));
      });

      test('A5: 巢狀 Map 值 — compact JSON', () {
        final input = <String, dynamic>{
          'options': <String, dynamic>{'recursive': true, 'depth': 3},
        };
        final result = formatKeyValue(input);

        expect(result, contains('options: {"recursive":true,"depth":3}'));
      });

      test('A6: 巢狀 List 值 — compact JSON', () {
        final input = <String, dynamic>{
          'items': <int>[1, 2, 3],
        };
        final result = formatKeyValue(input);

        expect(result, contains('items: [1,2,3]'));
      });

      test('A7: String 型別輸入（JSON 字串）— 解碼為 Map 後格式化', () {
        const input = '{"file_path":"/main.dart","limit":35}';
        final result = formatKeyValue(input);

        expect(result, 'file_path: /main.dart\nlimit: 35');
      });
    });

    group('B: 邊界條件', () {
      test('B1: null 輸入', () {
        final result = formatKeyValue(null);

        expect(result, '');
      });

      test('B2: 空 Map', () {
        final result = formatKeyValue(<String, dynamic>{});

        expect(result, '');
      });

      test('B3: value 為 null', () {
        final input = <String, dynamic>{'description': null};
        final result = formatKeyValue(input);

        expect(result, 'description: (empty)');
      });

      test('B4: value 為空字串', () {
        final input = <String, dynamic>{'content': ''};
        final result = formatKeyValue(input);

        expect(result, 'content:');
      });

      test('B5: JSON 字串值中的跳脫字元還原', () {
        const input = '{"text":"hello\\nworld"}';
        final result = formatKeyValue(input);

        expect(result, 'text: hello\nworld');
      });
    });

    group('C: Fallback 流程', () {
      test('C1: 輸入為 List — fallback 為 formatJsonObject', () {
        final input = <int>[1, 2, 3];
        final result = formatKeyValue(input);

        expect(result, formatJsonObject(input));
      });

      test('C2: 輸入為純數值 — fallback', () {
        final result = formatKeyValue(42);

        expect(result, formatJsonObject(42));
      });

      test('C3: 輸入為非 JSON 字串 — fallback', () {
        final result = formatKeyValue('hello world');

        expect(result, formatJsonObject('hello world'));
      });

      test('C4: 輸入為不可序列化物件 — fallback', () {
        final input = DateTime(2026);
        final result = formatKeyValue(input);

        expect(result, formatJsonObject(input));
      });
    });
  });

  group('unescapeForDisplay', () {
    test('D1: \\n 還原為換行', () {
      final result = unescapeForDisplay('hello\\nworld');

      expect(result, 'hello\nworld');
    });

    test('D2: \\t 還原為 tab', () {
      final result = unescapeForDisplay('col1\\tcol2');

      expect(result, 'col1\tcol2');
    });

    test('D3: \\" 還原為引號', () {
      final result = unescapeForDisplay('he said \\"hi\\"');

      expect(result, 'he said "hi"');
    });

    test('D4: \\\\ 還原為單一反斜線', () {
      final result = unescapeForDisplay('C:\\\\Users\\\\file');

      expect(result, 'C:\\Users\\file');
    });

    test('D5: 混合跳脫序列', () {
      final result =
          unescapeForDisplay('line1\\npath\\\\dir\\tand \\"q\\"');

      expect(result, 'line1\npath\\dir\tand "q"');
    });

    test('D6: 無跳脫字元 — 原樣回傳', () {
      final result = unescapeForDisplay('plain text');

      expect(result, 'plain text');
    });
  });
}
