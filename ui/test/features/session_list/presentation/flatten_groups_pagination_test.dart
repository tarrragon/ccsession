import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/session_group_ui_state.dart';
import 'package:ccsession/features/session_list/presentation/session_list_items.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_session_factory.dart';

void main() {
  group('TG-21: flattenGroups pagination/collapse logic', () {
    SessionGroupUiState makeUiState({
      Map<SessionStatus, int> pages = const {},
      Map<SessionStatus, bool> expanded = const {},
    }) {
      return SessionGroupUiState(
        currentPages: {
          SessionStatus.active: 0,
          SessionStatus.idle: 0,
          SessionStatus.completed: 0,
          ...pages,
        },
        expandedGroups: {
          SessionStatus.active: true,
          SessionStatus.idle: true,
          SessionStatus.completed: false,
          ...expanded,
        },
      );
    }

    List<SessionInfo> generateSessions(
      int count,
      SessionStatus status,
      String prefix,
    ) {
      return List.generate(
        count,
        (i) => createTestSession(id: '$prefix$i', status: status),
      );
    }

    // TC-21-01: 展開分組 — 不足一頁不產生 PaginationItem
    test('expanded group with fewer than 10 items has no pagination', () {
      final grouped = {
        SessionStatus.active: generateSessions(5, SessionStatus.active, 'a'),
      };
      final items = flattenGroups(grouped, makeUiState());

      expect(items.length, 6); // 1 header + 5 tiles
      expect(items[0], isA<HeaderItem>());
      expect(items.whereType<PaginationItem>(), isEmpty);
    });

    // TC-21-02: 展開分組 — 超過一頁產生 PaginationItem（第 1 頁）
    test('expanded group with 15 items shows page 1 of 2', () {
      final grouped = {
        SessionStatus.active: generateSessions(15, SessionStatus.active, 'a'),
      };
      final items = flattenGroups(grouped, makeUiState());

      // 1 header + 10 tiles + 1 pagination
      expect(items.length, 12);
      final pagination = items.whereType<PaginationItem>().single;
      expect(pagination.currentPage, 0);
      expect(pagination.totalPages, 2);
      expect(items.whereType<TileItem>().length, 10);
    });

    // TC-21-03: 展開分組 — 第 2 頁顯示剩餘項目
    test('expanded group page 2 shows remaining items', () {
      final grouped = {
        SessionStatus.active: generateSessions(15, SessionStatus.active, 'a'),
      };
      final uiState = makeUiState(pages: {SessionStatus.active: 1});
      final items = flattenGroups(grouped, uiState);

      expect(items.whereType<TileItem>().length, 5);
      final pagination = items.whereType<PaginationItem>().single;
      expect(pagination.currentPage, 1);
      expect(pagination.totalPages, 2);
    });

    // TC-21-04: 摺疊分組 — 只產生 Header，無 Session 和 Pagination
    test('collapsed group only produces header', () {
      final grouped = {
        SessionStatus.completed:
            generateSessions(20, SessionStatus.completed, 'c'),
      };
      // completed defaults to collapsed
      final items = flattenGroups(grouped, makeUiState());

      expect(items.length, 1);
      expect(items[0], isA<HeaderItem>());
      expect((items[0] as HeaderItem).count, 20);
    });

    // TC-21-05: 頁碼超出範圍 — clamp 到最後一頁
    test('out-of-range page clamps to last page', () {
      final grouped = {
        SessionStatus.active: generateSessions(15, SessionStatus.active, 'a'),
      };
      final uiState = makeUiState(pages: {SessionStatus.active: 5});
      final items = flattenGroups(grouped, uiState);

      // Should show last page (page 1), items 10-14
      expect(items.whereType<TileItem>().length, 5);
      final pagination = items.whereType<PaginationItem>().single;
      expect(pagination.currentPage, 1);
    });

    // TC-21-06: 多分組混合 — 各分組獨立分頁
    test('multiple groups paginate independently', () {
      final grouped = {
        SessionStatus.active: generateSessions(15, SessionStatus.active, 'a'),
        SessionStatus.idle: generateSessions(5, SessionStatus.idle, 'i'),
        SessionStatus.completed:
            generateSessions(20, SessionStatus.completed, 'c'),
      };
      final uiState = makeUiState(pages: {SessionStatus.active: 1});
      final items = flattenGroups(grouped, uiState);

      // active: 1 header + 5 tiles (page 2) + 1 pagination = 7
      // idle: 1 header + 5 tiles = 6
      // completed: 1 header (collapsed) = 1
      // total = 14
      expect(items.length, 14);

      // Active pagination
      final activePagination = items
          .whereType<PaginationItem>()
          .where((p) => p.status == SessionStatus.active)
          .single;
      expect(activePagination.currentPage, 1);

      // No idle pagination
      expect(
        items
            .whereType<PaginationItem>()
            .where((p) => p.status == SessionStatus.idle),
        isEmpty,
      );
    });

    // TC-21-07: 恰好 10 筆 — 不產生 PaginationItem
    test('exactly 10 items has no pagination', () {
      final grouped = {
        SessionStatus.active: generateSessions(10, SessionStatus.active, 'a'),
      };
      final items = flattenGroups(grouped, makeUiState());

      expect(items.whereType<TileItem>().length, 10);
      expect(items.whereType<PaginationItem>(), isEmpty);
    });

    // TC-21-08: 恰好 11 筆 — 產生 2 頁
    test('11 items produces 2 pages', () {
      final grouped = {
        SessionStatus.active: generateSessions(11, SessionStatus.active, 'a'),
      };
      final items = flattenGroups(grouped, makeUiState());

      expect(items.whereType<TileItem>().length, 10);
      final pagination = items.whereType<PaginationItem>().single;
      expect(pagination.currentPage, 0);
      expect(pagination.totalPages, 2);
    });

    // TC-21-09: 恰好 20 筆 — 第 2 頁恰好滿頁
    test('20 items page 2 is exactly full', () {
      final grouped = {
        SessionStatus.active: generateSessions(20, SessionStatus.active, 'a'),
      };
      final uiState = makeUiState(pages: {SessionStatus.active: 1});
      final items = flattenGroups(grouped, uiState);

      expect(items.whereType<TileItem>().length, 10);
      final pagination = items.whereType<PaginationItem>().single;
      expect(pagination.currentPage, 1);
      expect(pagination.totalPages, 2);
    });
  });
}
