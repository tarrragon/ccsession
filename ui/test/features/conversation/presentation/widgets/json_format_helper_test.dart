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
  });
}
