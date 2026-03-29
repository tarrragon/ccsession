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

    test('formats string value', () {
      final result = formatJsonObject('hello');

      expect(result, '"hello"');
    });

    test('formats numeric value', () {
      final result = formatJsonObject(42);

      expect(result, '42');
    });

    test('returns toString for unsupported object', () {
      final result = formatJsonObject(DateTime(2026));

      expect(result, isNotEmpty);
    });
  });
}
