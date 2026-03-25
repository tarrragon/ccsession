import 'package:ccsession/features/session_list/presentation/session_list_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-11: extractProjectName', () {
    // TC-11-01: 標準路徑
    test('extracts last segment from standard path', () {
      expect(extractProjectName('/Users/foo/Projects/myapp'), equals('myapp'));
    });

    // TC-11-02: 空字串
    test('returns empty string for empty input', () {
      expect(extractProjectName(''), equals(''));
    });

    // TC-11-03: 根路徑
    test('returns empty string for root path', () {
      expect(extractProjectName('/'), equals(''));
    });

    // TC-11-04: 尾部斜線
    test('handles trailing slash', () {
      expect(
        extractProjectName('/Users/foo/Projects/myapp/'),
        equals('myapp'),
      );
    });

    // TC-11-05: 單層路徑
    test('extracts name from single-level path', () {
      expect(extractProjectName('/myapp'), equals('myapp'));
    });

    // TC-11-06: 無斜線字串
    test('returns input when no slash present', () {
      expect(extractProjectName('myapp'), equals('myapp'));
    });
  });
}
