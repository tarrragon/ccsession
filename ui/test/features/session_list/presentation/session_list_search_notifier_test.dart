import 'dart:async';

import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/core/websocket/websocket_service.dart';
import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:ccsession/features/session_list/presentation/session_list_search_notifier.dart';
import 'package:ccsession/features/session_list/presentation/session_list_search_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_session_factory.dart';

class MockWebSocketService extends Mock implements WebSocketService {}

Future<void> _pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  late ProviderContainer container;
  late StreamController<ServerMessage> messageController;
  late MockWebSocketService mockService;

  setUp(() {
    messageController = StreamController<ServerMessage>.broadcast();
    mockService = MockWebSocketService();
    when(() => mockService.requestSessionList()).thenReturn(null);
    when(() => mockService.messageStream)
        .thenAnswer((_) => messageController.stream);

    container = ProviderContainer(
      overrides: [
        webSocketServiceProvider.overrideWithValue(mockService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    messageController.close();
  });

  Future<void> initNotifiers() async {
    container.listen(sessionListNotifierProvider, (_, __) {});
    container.listen(sessionListSearchNotifierProvider, (_, __) {});
    await _pump();
  }

  Future<void> loadSessions(List<SessionInfo> sessions) async {
    messageController.add(createSessionListMessage(sessions));
    await _pump();
  }

  SessionListSearchState getSearchState() {
    return container.read(sessionListSearchNotifierProvider);
  }

  Map<SessionStatus, List<SessionInfo>> getFiltered() {
    return container
        .read(sessionListSearchNotifierProvider.notifier)
        .filteredGroupedSessions();
  }

  int countAllSessions(Map<SessionStatus, List<SessionInfo>> grouped) {
    return grouped.values.fold(0, (sum, list) => sum + list.length);
  }

  // -- Standard test data --

  final sessionA = createTestSession(
    id: 'a',
    summary: 'refactor auth module',
    projectPath: '/Users/dev/auth-service',
    agentName: 'claude',
    lastMessage: 'completed refactoring',
    status: SessionStatus.active,
    lastEventAt: baseTime.add(const Duration(hours: 1)),
  );

  final sessionB = createTestSession(
    id: 'b',
    summary: 'add payment flow',
    projectPath: '/Users/dev/payment-service',
    agentName: 'opus',
    lastMessage: 'implementing checkout',
    status: SessionStatus.active,
    lastEventAt: baseTime.add(const Duration(hours: 2)),
  );

  final sessionC = createTestSession(
    id: 'c',
    summary: 'fix login bug',
    projectPath: '/Users/dev/auth-service',
    agentName: 'claude',
    lastMessage: 'fixed null check',
    status: SessionStatus.idle,
    lastEventAt: baseTime.add(const Duration(hours: 3)),
  );

  final sessionE = createTestSession(
    id: 'e',
    summary: '',
    projectPath: '/Users/dev/empty',
    agentName: '',
    lastMessage: '',
    status: SessionStatus.active,
  );

  group('TG-FILTER-01: 搜尋 UI 狀態管理', () {
    test('TC-FILTER-01: openSearch 設定 isSearchVisible 為 true', () async {
      await initNotifiers();

      expect(getSearchState().isSearchVisible, isFalse);
      expect(getSearchState().query, isEmpty);

      container
          .read(sessionListSearchNotifierProvider.notifier)
          .openSearch();

      expect(getSearchState().isSearchVisible, isTrue);
      expect(getSearchState().query, isEmpty);
    });

    test('TC-FILTER-02: closeSearch 重置所有搜尋狀態', () async {
      await initNotifiers();
      await loadSessions([sessionA, sessionB, sessionC]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);

      // 開啟搜尋並設定 query
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('auth');
        async.elapse(const Duration(milliseconds: 300));
      });

      expect(getSearchState().isSearchVisible, isTrue);
      expect(getSearchState().query, 'auth');

      notifier.closeSearch();

      expect(getSearchState().isSearchVisible, isFalse);
      expect(getSearchState().query, isEmpty);
      // 完整列表恢復
      expect(countAllSessions(getFiltered()), 3);
    });

    test('TC-FILTER-03: hasActiveFilter 衍生屬性', () async {
      await initNotifiers();

      expect(getSearchState().hasActiveFilter, isFalse);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('auth');
        async.elapse(const Duration(milliseconds: 300));
      });

      expect(getSearchState().hasActiveFilter, isTrue);
    });
  });

  group('TG-FILTER-02: 篩選邏輯核心', () {
    test('TC-FILTER-10: 基本文字篩選 — summary 匹配', () async {
      await initNotifiers();
      await loadSessions([sessionA, sessionB, sessionC]);

      expect(countAllSessions(getFiltered()), 3);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('pay');
        async.elapse(const Duration(milliseconds: 300));
      });

      final filtered = getFiltered();
      expect(countAllSessions(filtered), 1);
      expect(filtered[SessionStatus.active]!.first.id, 'b');
    });

    test('TC-FILTER-11: Case-insensitive 篩選', () async {
      await initNotifiers();
      final upperSession = createTestSession(
        id: 'upper',
        summary: 'Refactor Auth Module',
        status: SessionStatus.active,
      );
      await loadSessions([upperSession]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();

      fakeAsync((async) {
        notifier.updateQuery('refactor');
        async.elapse(const Duration(milliseconds: 300));
      });
      expect(countAllSessions(getFiltered()), 1);

      fakeAsync((async) {
        notifier.updateQuery('REFACTOR');
        async.elapse(const Duration(milliseconds: 300));
      });
      expect(countAllSessions(getFiltered()), 1);
    });

    test('TC-FILTER-12: 多欄位匹配 — projectPath', () async {
      await initNotifiers();
      final session = createTestSession(
        id: 'pp',
        summary: 'fix bug',
        projectPath: '/Users/dev/payment-service',
        status: SessionStatus.active,
      );
      await loadSessions([session]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('payment');
        async.elapse(const Duration(milliseconds: 300));
      });

      expect(countAllSessions(getFiltered()), 1);
    });

    test('TC-FILTER-13: 多欄位匹配 — agentName', () async {
      await initNotifiers();
      await loadSessions([sessionA, sessionB]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('opus');
        async.elapse(const Duration(milliseconds: 300));
      });

      final filtered = getFiltered();
      expect(countAllSessions(filtered), 1);
      expect(filtered[SessionStatus.active]!.first.id, 'b');
    });

    test('TC-FILTER-14: 多欄位匹配 — lastMessage', () async {
      await initNotifiers();
      await loadSessions([sessionB, sessionC]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('checkout');
        async.elapse(const Duration(milliseconds: 300));
      });

      final filtered = getFiltered();
      expect(countAllSessions(filtered), 1);
      expect(filtered[SessionStatus.active]!.first.id, 'b');
    });

    test('TC-FILTER-15: 任一欄位匹配即顯示（OR 邏輯）', () async {
      await initNotifiers();
      final session = createTestSession(
        id: 'or',
        summary: 'fix bug',
        projectPath: '/Users/dev/auth-service',
        status: SessionStatus.active,
      );
      await loadSessions([session]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('auth');
        async.elapse(const Duration(milliseconds: 300));
      });

      expect(countAllSessions(getFiltered()), 1);
    });

    test('TC-FILTER-16: 無匹配結果', () async {
      await initNotifiers();
      await loadSessions([sessionA, sessionB, sessionC]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('zzzznotexist');
        async.elapse(const Duration(milliseconds: 300));
      });

      expect(getFiltered(), isEmpty);
    });

    test('TC-FILTER-17: 清空篩選恢復完整列表', () async {
      await initNotifiers();
      await loadSessions([sessionA, sessionB, sessionC]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();

      // 先篩選
      fakeAsync((async) {
        notifier.updateQuery('auth');
        async.elapse(const Duration(milliseconds: 300));
      });
      expect(countAllSessions(getFiltered()), lessThan(3));

      // 清空
      fakeAsync((async) {
        notifier.updateQuery('');
        async.elapse(const Duration(milliseconds: 300));
      });
      expect(countAllSessions(getFiltered()), 3);
    });

    test('TC-FILTER-18: 空查詢顯示全部', () async {
      await initNotifiers();
      await loadSessions([sessionA, sessionB, sessionC]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();

      // query 為空時，filteredGroupedSessions 與完整列表相同
      expect(countAllSessions(getFiltered()), 3);
    });

    test('TC-FILTER-19: 篩選結果保持分組排序', () async {
      await initNotifiers();

      final active1 = createTestSession(
        id: 'a1',
        summary: 'test a1',
        status: SessionStatus.active,
        lastEventAt: baseTime.add(const Duration(hours: 3)),
      );
      final active2 = createTestSession(
        id: 'a2',
        summary: 'test a2',
        status: SessionStatus.active,
        lastEventAt: baseTime.add(const Duration(hours: 1)),
      );
      final active3 = createTestSession(
        id: 'a3',
        summary: 'test a3',
        status: SessionStatus.active,
        lastEventAt: baseTime.add(const Duration(hours: 2)),
      );
      final idle1 = createTestSession(
        id: 'i1',
        summary: 'test i1',
        status: SessionStatus.idle,
        lastEventAt: baseTime.add(const Duration(hours: 4)),
      );
      final idle2 = createTestSession(
        id: 'i2',
        summary: 'test i2',
        status: SessionStatus.idle,
        lastEventAt: baseTime,
      );

      await loadSessions([active1, active2, active3, idle1, idle2]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('test');
        async.elapse(const Duration(milliseconds: 300));
      });

      final filtered = getFiltered();

      // active 在 idle 前
      final keys = filtered.keys.toList();
      expect(keys.indexOf(SessionStatus.active),
          lessThan(keys.indexOf(SessionStatus.idle)));

      // active 組內按 lastEventAt 降序
      final activeGroup = filtered[SessionStatus.active]!;
      expect(activeGroup.map((s) => s.id).toList(), ['a1', 'a3', 'a2']);

      // idle 組內按 lastEventAt 降序
      final idleGroup = filtered[SessionStatus.idle]!;
      expect(idleGroup.map((s) => s.id).toList(), ['i1', 'i2']);
    });

    test('TC-FILTER-40: 特殊字元當純文字處理', () async {
      await initNotifiers();
      final session = createTestSession(
        id: 'special',
        summary: 'project',
        projectPath: '/Users/dev/my-project (v2)',
        status: SessionStatus.active,
      );
      await loadSessions([session]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('(v2)');
        async.elapse(const Duration(milliseconds: 300));
      });

      expect(countAllSessions(getFiltered()), 1);
    });

    test('TC-FILTER-41: 超長輸入字串正常處理', () async {
      await initNotifiers();
      await loadSessions([sessionA]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('a' * 1000);
        async.elapse(const Duration(milliseconds: 300));
      });

      expect(getFiltered(), isEmpty);
    });

    test('TC-FILTER-42: query 前後空白 trim', () async {
      await initNotifiers();
      final session = createTestSession(
        id: 'trim',
        summary: 'auth module',
        status: SessionStatus.active,
      );
      await loadSessions([session]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('  auth  ');
        async.elapse(const Duration(milliseconds: 300));
      });

      expect(countAllSessions(getFiltered()), 1);
    });

    test('TC-FILTER-43: 所有欄位為空字串的 session', () async {
      await initNotifiers();
      await loadSessions([sessionE, sessionA]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();

      // 有 query 時，空欄位 session 不匹配
      fakeAsync((async) {
        notifier.updateQuery('auth');
        async.elapse(const Duration(milliseconds: 300));
      });
      final filtered = getFiltered();
      final allIds = filtered.values.expand((l) => l).map((s) => s.id);
      expect(allIds, isNot(contains('e')));

      // 空 query 時，所有 session 顯示
      fakeAsync((async) {
        notifier.updateQuery('');
        async.elapse(const Duration(milliseconds: 300));
      });
      expect(countAllSessions(getFiltered()), 2);
    });

    test('TC-FILTER-44: 篩選中已選中 session 被篩掉', () async {
      await initNotifiers();
      await loadSessions([sessionA, sessionB]);

      // 選中 session A
      container
          .read(sessionListNotifierProvider.notifier)
          .selectSession('a');
      await _pump();

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('payment');
        async.elapse(const Duration(milliseconds: 300));
      });

      // session A 不在篩選結果中
      final allIds =
          getFiltered().values.expand((l) => l).map((s) => s.id);
      expect(allIds, isNot(contains('a')));

      // selectedSessionId 不變
      final listState =
          container.read(sessionListNotifierProvider).valueOrNull;
      expect(listState?.selectedSessionId, 'a');
    });
  });

  group('TG-34: filteredGroupedSessions projectPath 過濾', () {
    test('TC-34-01: filters sessions by projectPath', () async {
      await initNotifiers();

      final s1 = createTestSession(
        id: 's1',
        projectPath: '/proj1',
        status: SessionStatus.active,
      );
      final s2 = createTestSession(
        id: 's2',
        projectPath: '/proj1',
        status: SessionStatus.idle,
      );
      final s3 = createTestSession(
        id: 's3',
        projectPath: '/proj2',
        status: SessionStatus.active,
      );
      final s4 = createTestSession(
        id: 's4',
        projectPath: '/proj2',
        status: SessionStatus.completed,
      );
      await loadSessions([s1, s2, s3, s4]);

      expect(
        container
            .read(sessionListNotifierProvider)
            .valueOrNull!
            .sessions
            .length,
        4,
      );

      final filtered = container
          .read(sessionListSearchNotifierProvider.notifier)
          .filteredGroupedSessions(projectPath: '/proj1');

      final totalCount = countAllSessions(filtered);
      expect(totalCount, 2);
      expect(filtered[SessionStatus.active]?.length, 1);
      expect(filtered[SessionStatus.idle]?.length, 1);
    });

    test('TC-34-02: returns empty map when no sessions match projectPath',
        () async {
      await initNotifiers();
      await loadSessions([
        createTestSession(id: '1', projectPath: '/proj1'),
        createTestSession(id: '2', projectPath: '/proj1'),
      ]);

      final filtered = container
          .read(sessionListSearchNotifierProvider.notifier)
          .filteredGroupedSessions(projectPath: '/proj2');

      expect(filtered, isEmpty);
    });

    test('TC-34-03: combines search query with projectPath filter',
        () async {
      await initNotifiers();

      final s1 = createTestSession(
        id: 's1',
        projectPath: '/proj1',
        summary: 'auth login',
        status: SessionStatus.active,
      );
      final s2 = createTestSession(
        id: 's2',
        projectPath: '/proj1',
        summary: 'auth signup',
        status: SessionStatus.active,
      );
      final s3 = createTestSession(
        id: 's3',
        projectPath: '/proj1',
        summary: 'dashboard',
        status: SessionStatus.active,
      );
      await loadSessions([s1, s2, s3]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('auth');
        async.elapse(const Duration(milliseconds: 300));
      });

      final filtered = notifier.filteredGroupedSessions(
        projectPath: '/proj1',
      );

      expect(countAllSessions(filtered), 2);
    });

    test('TC-34-04: filters by empty projectPath', () async {
      await initNotifiers();
      await loadSessions([
        createTestSession(id: '1', projectPath: ''),
        createTestSession(id: '2', projectPath: '/proj1'),
        createTestSession(id: '3', projectPath: '/proj1'),
      ]);

      final filtered = container
          .read(sessionListSearchNotifierProvider.notifier)
          .filteredGroupedSessions(projectPath: '');

      expect(countAllSessions(filtered), 1);
    });
  });

  group('TG-FILTER-03: Debounce 與時間控制', () {
    test('TC-FILTER-20: debounce 只在最後一次輸入後 300ms 執行篩選',
        () async {
      await initNotifiers();
      await loadSessions([sessionA, sessionB]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();

      fakeAsync((async) {
        // 快速連續輸入，每次間隔 100ms
        notifier.updateQuery('a');
        async.elapse(const Duration(milliseconds: 100));

        notifier.updateQuery('au');
        async.elapse(const Duration(milliseconds: 100));

        notifier.updateQuery('aut');
        async.elapse(const Duration(milliseconds: 100));

        notifier.updateQuery('auth');

        // 還沒到 300ms — state 應仍為 openSearch 後的狀態（query 為空）
        async.elapse(const Duration(milliseconds: 200));
        expect(getSearchState().query, isEmpty);

        // 再過 100ms（最後一次 updateQuery 後滿 300ms）
        async.elapse(const Duration(milliseconds: 100));
        expect(getSearchState().query, 'auth');
      });
    });
  });

  group('TG-FILTER-04: 即時事件串流與篩選互動', () {
    test('TC-FILTER-30: 新匹配 session 自動加入篩選結果', () async {
      await initNotifiers();
      await loadSessions([sessionA, sessionC]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('auth');
        async.elapse(const Duration(milliseconds: 300));
      });

      // auth 匹配 sessionA (summary) 和 sessionC (projectPath)
      expect(countAllSessions(getFiltered()), 2);

      // WebSocket 推送新 session
      final newSession = createTestSession(
        id: 'new',
        summary: 'auth migration',
        status: SessionStatus.active,
        lastEventAt: baseTime.add(const Duration(hours: 5)),
      );
      await loadSessions([sessionA, sessionC, newSession]);

      expect(countAllSessions(getFiltered()), 3);
      expect(getSearchState().query, 'auth');
    });

    test('TC-FILTER-31: 不匹配的新 session 不出現', () async {
      await initNotifiers();
      await loadSessions([sessionA]);

      final notifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      notifier.openSearch();
      fakeAsync((async) {
        notifier.updateQuery('auth');
        async.elapse(const Duration(milliseconds: 300));
      });

      final beforeCount = countAllSessions(getFiltered());

      // 推送不匹配的新 session
      final unmatched = createTestSession(
        id: 'unm',
        summary: 'add logging',
        status: SessionStatus.active,
      );
      await loadSessions([sessionA, unmatched]);

      expect(countAllSessions(getFiltered()), beforeCount);
    });

    test('TC-FILTER-32: 無篩選時新 session 直接出現', () async {
      await initNotifiers();
      await loadSessions([sessionA, sessionB, sessionC]);

      expect(countAllSessions(getFiltered()), 3);

      // 推送新 session（未開啟搜尋）
      final newSession = createTestSession(
        id: 'new',
        summary: 'new one',
        status: SessionStatus.active,
        lastEventAt: baseTime.add(const Duration(hours: 5)),
      );
      await loadSessions([sessionA, sessionB, sessionC, newSession]);

      expect(countAllSessions(getFiltered()), 4);
    });
  });
}
