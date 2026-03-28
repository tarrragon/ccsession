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

  group('TG-W4-002-C: groupSessionsByStatus 排序驗證', () {
    /// TC-C01: 同一狀態組內降序排列
    test('sorts sessions within group by lastEventAt descending', () {
      final sessions = [
        createTestSession(
          id: '1',
          status: SessionStatus.active,
          lastEventAt: DateTime.utc(2026, 3, 25, 10, 0),
        ),
        createTestSession(
          id: '2',
          status: SessionStatus.active,
          lastEventAt: DateTime.utc(2026, 3, 25, 10, 30),
        ),
        createTestSession(
          id: '3',
          status: SessionStatus.active,
          lastEventAt: DateTime.utc(2026, 3, 25, 10, 15),
        ),
      ];

      final result = groupSessionsByStatus(sessions);
      final ids = result[SessionStatus.active]!.map((s) => s.id).toList();

      expect(ids, ['2', '3', '1']);
    });

    /// TC-C02: 相同 lastEventAt 不產生錯誤
    test('handles sessions with identical lastEventAt', () {
      final sameTime = DateTime.utc(2026, 3, 25, 10, 0);
      final sessions = [
        createTestSession(id: '1', status: SessionStatus.active, lastEventAt: sameTime),
        createTestSession(id: '2', status: SessionStatus.active, lastEventAt: sameTime),
      ];

      final result = groupSessionsByStatus(sessions);

      expect(result[SessionStatus.active]!.length, 2);
    });

    /// TC-C03: 空列表和單一 session
    test('handles empty list and single session', () {
      expect(groupSessionsByStatus([]), isEmpty);

      final single = [
        createTestSession(id: '1', status: SessionStatus.idle),
      ];
      final result = groupSessionsByStatus(single);
      expect(result[SessionStatus.idle]!.length, 1);
    });

    /// TC-C04: 多狀態組各自獨立排序
    test('sorts each status group independently', () {
      final sessions = [
        createTestSession(id: 'a1', status: SessionStatus.active,
            lastEventAt: DateTime.utc(2026, 3, 25, 10, 0)),
        createTestSession(id: 'a2', status: SessionStatus.active,
            lastEventAt: DateTime.utc(2026, 3, 25, 10, 30)),
        createTestSession(id: 'i1', status: SessionStatus.idle,
            lastEventAt: DateTime.utc(2026, 3, 25, 9, 0)),
        createTestSession(id: 'i2', status: SessionStatus.idle,
            lastEventAt: DateTime.utc(2026, 3, 25, 9, 45)),
        createTestSession(id: 'c1', status: SessionStatus.completed,
            lastEventAt: DateTime.utc(2026, 3, 25, 8, 0)),
        createTestSession(id: 'c2', status: SessionStatus.completed,
            lastEventAt: DateTime.utc(2026, 3, 25, 8, 15)),
      ];

      final result = groupSessionsByStatus(sessions);

      expect(result[SessionStatus.active]!.map((s) => s.id), ['a2', 'a1']);
      expect(result[SessionStatus.idle]!.map((s) => s.id), ['i2', 'i1']);
      expect(result[SessionStatus.completed]!.map((s) => s.id), ['c2', 'c1']);
    });
  });

  group('TG-W4-002-D: 搜尋結果排序驗證', () {
    /// TC-D01: 搜尋結果中每個組內降序排列
    test('filtered sessions maintain descending sort within group', () {
      // 模擬搜尋結果：3 個匹配的 Active session
      final filtered = [
        createTestSession(
          id: '1',
          status: SessionStatus.active,
          lastEventAt: DateTime.utc(2026, 3, 25, 10, 0),
          summary: 'match',
        ),
        createTestSession(
          id: '2',
          status: SessionStatus.active,
          lastEventAt: DateTime.utc(2026, 3, 25, 10, 30),
          summary: 'match',
        ),
        createTestSession(
          id: '3',
          status: SessionStatus.active,
          lastEventAt: DateTime.utc(2026, 3, 25, 10, 15),
          summary: 'match',
        ),
      ];

      final result = groupSessionsByStatus(filtered);
      final ids = result[SessionStatus.active]!.map((s) => s.id).toList();

      expect(ids, ['2', '3', '1']);
    });

    /// TC-D02: 搜尋結果為空時無排序錯誤
    test('empty filtered list returns empty map without error', () {
      final result = groupSessionsByStatus([]);

      expect(result, isEmpty);
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
