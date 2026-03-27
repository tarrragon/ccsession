import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/session_group_utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_session_factory.dart';

void main() {
  group('TG-30: groupSessionsByProject', () {
    // TC-30-01: 正常分組 — 多專案多 session
    test('groups sessions by projectPath with multiple projects', () {
      final sessions = [
        createTestSession(id: '1', projectPath: '/a/proj1'),
        createTestSession(id: '2', projectPath: '/a/proj1'),
        createTestSession(id: '3', projectPath: '/b/proj2'),
      ];

      expect(sessions.length, 3);

      final result = groupSessionsByProject(sessions);

      expect(result.length, 2);
      expect(result['/a/proj1']!.length, 2);
      expect(result['/b/proj2']!.length, 1);
    });

    // TC-30-02: 邊界 — 空列表
    test('returns empty map for empty list', () {
      final result = groupSessionsByProject([]);

      expect(result, isEmpty);
    });

    // TC-30-03: 邊界 — 所有 session 同一專案
    test('groups all sessions under single project', () {
      final sessions = [
        createTestSession(id: '1', projectPath: '/a/proj1'),
        createTestSession(id: '2', projectPath: '/a/proj1'),
        createTestSession(id: '3', projectPath: '/a/proj1'),
      ];

      final result = groupSessionsByProject(sessions);

      expect(result.length, 1);
      expect(result['/a/proj1']!.length, 3);
    });

    // TC-30-04: 邊界 — projectPath 為空字串
    test('uses empty string as key for empty projectPath', () {
      final sessions = [
        createTestSession(id: '1', projectPath: '/a/proj1'),
        createTestSession(id: '2', projectPath: ''),
      ];

      final result = groupSessionsByProject(sessions);

      expect(result.length, 2);
      expect(result['/a/proj1']!.length, 1);
      expect(result['']!.length, 1);
    });

    // TC-30-05: 邊界 — 全部 projectPath 為空
    test('groups all under empty key when all projectPaths empty', () {
      final sessions = [
        createTestSession(id: '1', projectPath: ''),
        createTestSession(id: '2', projectPath: ''),
      ];

      final result = groupSessionsByProject(sessions);

      expect(result.length, 1);
      expect(result['']!.length, 2);
    });

    // TC-30-06: 正常 — 單一 session
    test('handles single session', () {
      final sessions = [
        createTestSession(id: '1', projectPath: '/a/proj1'),
      ];

      final result = groupSessionsByProject(sessions);

      expect(result.length, 1);
      expect(result['/a/proj1']!.length, 1);
    });
  });

  group('TG-31: sortedProjectPaths', () {
    // TC-31-01: 正常排序 — 字母順序
    test('sorts by extractProjectName alphabetically', () {
      final grouped = <String, List<SessionInfo>>{
        '/x/zoo': [createTestSession(id: '1', projectPath: '/x/zoo')],
        '/x/alpha': [createTestSession(id: '2', projectPath: '/x/alpha')],
        '/x/beta': [createTestSession(id: '3', projectPath: '/x/beta')],
      };

      final result = sortedProjectPaths(grouped);

      expect(result, ['/x/alpha', '/x/beta', '/x/zoo']);
    });

    // TC-31-02: 邊界 — 空 projectPath 排最後
    test('places empty projectPath last', () {
      final grouped = <String, List<SessionInfo>>{
        '/x/alpha': [createTestSession(id: '1', projectPath: '/x/alpha')],
        '': [createTestSession(id: '2', projectPath: '')],
        '/x/zoo': [createTestSession(id: '3', projectPath: '/x/zoo')],
      };

      final result = sortedProjectPaths(grouped);

      expect(result, ['/x/alpha', '/x/zoo', '']);
    });

    // TC-31-03: 邊界 — 空 Map
    test('returns empty list for empty map', () {
      final result = sortedProjectPaths({});

      expect(result, isEmpty);
    });

    // TC-31-04: 邊界 — 只有空 projectPath
    test('returns single empty string for map with only empty key', () {
      final grouped = <String, List<SessionInfo>>{
        '': [createTestSession(id: '1', projectPath: '')],
      };

      final result = sortedProjectPaths(grouped);

      expect(result, ['']);
    });

    // TC-31-05: 正常 — case-insensitive 排序
    test('sorts case-insensitively', () {
      final grouped = <String, List<SessionInfo>>{
        '/x/Alpha': [createTestSession(id: '1', projectPath: '/x/Alpha')],
        '/x/beta': [createTestSession(id: '2', projectPath: '/x/beta')],
      };

      final result = sortedProjectPaths(grouped);

      expect(result, ['/x/Alpha', '/x/beta']);
    });

    // TC-31-06: 邊界 — 單一專案
    test('handles single project', () {
      final grouped = <String, List<SessionInfo>>{
        '/x/proj1': [createTestSession(id: '1', projectPath: '/x/proj1')],
      };

      final result = sortedProjectPaths(grouped);

      expect(result, ['/x/proj1']);
    });
  });
}
