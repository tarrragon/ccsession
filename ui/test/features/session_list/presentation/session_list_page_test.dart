import 'dart:async';

import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/core/websocket/websocket_service.dart';
import 'package:ccsession/features/session_list/presentation/session_list_page.dart';
import 'package:ccsession/features/session_list/presentation/session_list_search_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_session_factory.dart';

// -- Mock --

class MockWebSocketService extends Mock implements WebSocketService {}

void main() {
  group('TG-12: SessionListPage', () {
    late StreamController<ServerMessage> messageController;
    late MockWebSocketService mockService;

    setUp(() {
      messageController = StreamController<ServerMessage>.broadcast();
      mockService = MockWebSocketService();
      when(() => mockService.requestSessionList()).thenReturn(null);
      when(() => mockService.messageStream)
          .thenAnswer((_) => messageController.stream);
    });

    /// 設定大畫面以讓所有 ListView items 可見
    Future<void> setLargeSurface(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 5000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }

    tearDown(() {
      messageController.close();
    });

    Widget buildSubject({List<Override> additionalOverrides = const []}) {
      return ProviderScope(
        overrides: [
          webSocketServiceProvider.overrideWithValue(mockService),
          ...additionalOverrides,
        ],
        child: const MaterialApp(home: Scaffold(body: SessionListPage())),
      );
    }

    Future<void> sendMessage(
      WidgetTester tester,
      ServerMessage message,
    ) async {
      messageController.add(message);
      await tester.pump();
      await tester.pump();
    }

    // TC-12-01: Loading 狀態顯示載入指示器
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.text('No sessions'), findsOneWidget);
    });

    // TC-12-02: 正常載入顯示分組列表
    testWidgets('displays grouped session list', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage([
        createTestSession(id: 's1', status: SessionStatus.active),
        createTestSession(id: 's2', status: SessionStatus.active),
        createTestSession(id: 's3', status: SessionStatus.idle),
      ]));

      expect(find.text('Active (2)'), findsOneWidget);
      expect(find.text('Idle (1)'), findsOneWidget);
      expect(find.textContaining('Completed'), findsNothing);
    });

    // TC-12-03: 空列表顯示提示文字
    testWidgets('shows empty message when no sessions', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage([]));

      expect(find.text('No sessions'), findsOneWidget);
    });

    // TC-12-04: 錯誤狀態顯示錯誤訊息
    testWidgets('shows error message on error', (tester) async {
      final errorController = StreamController<ServerMessage>.broadcast();
      final errorService = MockWebSocketService();
      when(() => errorService.requestSessionList()).thenThrow(Exception('fail'));
      when(() => errorService.messageStream)
          .thenAnswer((_) => errorController.stream);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          webSocketServiceProvider.overrideWithValue(errorService),
        ],
        child: const MaterialApp(home: Scaffold(body: SessionListPage())),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Failed to load sessions'), findsOneWidget);

      errorController.close();
    });

    // TC-12-05: 點擊 session 項目觸發選擇
    testWidgets('tapping a session tile triggers selection', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage([
        createTestSession(id: 'session-A', summary: 'My Task'),
      ]));

      await tester.tap(find.text('My Task'));
      await tester.pump();

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.selected, isTrue);
    });

    // TC-12-06: 選中 session 有視覺區分
    testWidgets('selected session has visual distinction', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage([
        createTestSession(id: 'session-A', summary: 'Task A'),
        createTestSession(id: 'session-B', summary: 'Task B'),
      ]));

      await tester.tap(find.text('Task A'));
      await tester.pump();

      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(tiles[0].selected, isTrue);
      expect(tiles[1].selected, isFalse);
    });

    // TC-12-10: Completed 預設摺疊 — 只顯示 Header
    testWidgets('completed group is collapsed by default', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage([
        createTestSession(id: 'a1', status: SessionStatus.active),
        createTestSession(id: 'a2', status: SessionStatus.active),
        createTestSession(id: 'a3', status: SessionStatus.active),
        ...List.generate(
          5,
          (i) => createTestSession(
            id: 'c$i',
            status: SessionStatus.completed,
            summary: 'Completed $i',
          ),
        ),
      ]));

      expect(find.text('Active (3)'), findsOneWidget);
      expect(find.text('Completed (5)'), findsOneWidget);
      // Completed tiles should not be visible
      expect(find.text('Completed 0'), findsNothing);
    });

    // TC-12-11: 點擊 Completed Header — 展開顯示 session
    testWidgets('tapping completed header expands group', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage([
        createTestSession(id: 'a1', status: SessionStatus.active),
        ...List.generate(
          5,
          (i) => createTestSession(
            id: 'c$i',
            status: SessionStatus.completed,
            summary: 'Done $i',
          ),
        ),
      ]));

      // Verify collapsed
      expect(find.text('Done 0'), findsNothing);

      // Tap to expand
      await tester.tap(find.text('Completed (5)'));
      await tester.pump();

      // Now visible (5 items, no pagination)
      expect(find.text('Done 0'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    // TC-12-12: 分頁顯示 — 超過 10 筆顯示分頁控制
    testWidgets('shows pagination for groups with more than 10 items',
        (tester) async {
      await setLargeSurface(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage(
        List.generate(
          15,
          (i) => createTestSession(
            id: 'a$i',
            status: SessionStatus.active,
            summary: 'Active $i',
          ),
        ),
      ));

      expect(find.text('Active (15)'), findsOneWidget);
      // Only 10 tiles visible
      expect(find.byType(ListTile), findsNWidgets(10));
      // Pagination visible
      expect(find.text('1 / 2'), findsOneWidget);
    });

    // TC-12-13: 分頁切換 — 點擊下一頁
    testWidgets('clicking next page shows next set of items', (tester) async {
      await setLargeSurface(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage(
        List.generate(
          15,
          (i) => createTestSession(
            id: 'a$i',
            status: SessionStatus.active,
            summary: 'Active $i',
          ),
        ),
      ));

      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      // Now on page 2
      expect(find.text('2 / 2'), findsOneWidget);
      // Only 5 tiles on page 2
      expect(find.byType(ListTile), findsNWidgets(5));
    });

    // TC-12-14: 搜尋重置分頁
    testWidgets('search resets pagination', (tester) async {
      await setLargeSurface(tester);
      late ProviderContainer container;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
            overrides: [
              webSocketServiceProvider.overrideWithValue(mockService),
            ],
          ),
          child: const MaterialApp(home: Scaffold(body: SessionListPage())),
        ),
      );
      await tester.pump();

      // Send 15 active sessions
      messageController.add(createSessionListMessage(
        List.generate(
          15,
          (i) => createTestSession(
            id: 'a$i',
            status: SessionStatus.active,
            summary: 'Active $i',
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();

      // Go to page 2
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      expect(find.text('2 / 2'), findsOneWidget);

      // Trigger search state change via notifier (opens search bar)
      container.read(sessionListSearchNotifierProvider.notifier).openSearch();
      await tester.pump();

      // ref.listen detects search state change → resetAllPages
      expect(find.text('1 / 2'), findsOneWidget);

      container.dispose();
    });

    // TC-12-15: 分頁切換不影響其他分組
    testWidgets('page change in one group does not affect others',
        (tester) async {
      await setLargeSurface(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage([
        ...List.generate(
          15,
          (i) => createTestSession(
            id: 'a$i',
            status: SessionStatus.active,
            summary: 'Active $i',
          ),
        ),
        ...List.generate(
          12,
          (i) => createTestSession(
            id: 'i$i',
            status: SessionStatus.idle,
            summary: 'Idle $i',
          ),
        ),
      ]));

      // Both on page 1
      // Find the active pagination (first chevron_right)
      final nextButtons = find.byIcon(Icons.chevron_right);
      expect(nextButtons, findsNWidgets(2)); // active + idle

      // Tap active's next
      await tester.tap(nextButtons.first);
      await tester.pump();

      // Active shows page 2, idle still page 1
      expect(find.text('2 / 2'), findsOneWidget); // active
      expect(find.text('1 / 2'), findsOneWidget); // idle
    });

    // TC-12-16: 摺疊不影響其他分組展開狀態
    testWidgets('collapsing one group does not affect others', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage([
        ...List.generate(
          3,
          (i) => createTestSession(
            id: 'a$i',
            status: SessionStatus.active,
            summary: 'Active $i',
          ),
        ),
        ...List.generate(
          3,
          (i) => createTestSession(
            id: 'i$i',
            status: SessionStatus.idle,
            summary: 'Idle $i',
          ),
        ),
      ]));

      // Both groups expanded
      expect(find.text('Active 0'), findsOneWidget);
      expect(find.text('Idle 0'), findsOneWidget);

      // Collapse active
      await tester.tap(find.text('Active (3)'));
      await tester.pump();

      // Active tiles gone, idle tiles still visible
      expect(find.text('Active 0'), findsNothing);
      expect(find.text('Idle 0'), findsOneWidget);
    });
  });

  group('TG-35: _ProjectTabbedView Widget', () {
    late StreamController<ServerMessage> messageController;
    late MockWebSocketService mockService;

    setUp(() {
      messageController = StreamController<ServerMessage>.broadcast();
      mockService = MockWebSocketService();
      when(() => mockService.requestSessionList()).thenReturn(null);
      when(() => mockService.messageStream)
          .thenAnswer((_) => messageController.stream);
    });

    tearDown(() {
      messageController.close();
    });

    Widget buildSubject({List<Override> additionalOverrides = const []}) {
      return ProviderScope(
        overrides: [
          webSocketServiceProvider.overrideWithValue(mockService),
          ...additionalOverrides,
        ],
        child: const MaterialApp(home: Scaffold(body: SessionListPage())),
      );
    }

    Future<void> sendMessage(
      WidgetTester tester,
      ServerMessage message,
    ) async {
      messageController.add(message);
      await tester.pump();
      await tester.pump();
    }

    // TC-35-01: 基本渲染 — 2 個專案顯示 2 個 Tab
    testWidgets('displays tabs for multiple projects', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage([
        createTestSession(id: 's1', projectPath: '/a/proj1'),
        createTestSession(id: 's2', projectPath: '/a/proj1'),
        createTestSession(id: 's3', projectPath: '/b/proj2'),
      ]));

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('proj1 (2)'), findsOneWidget);
      expect(find.text('proj2 (1)'), findsOneWidget);
    });

    // TC-35-02: Tab 標籤顯示正確的專案名稱和 session count
    testWidgets('tab labels show project name and session count',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage([
        createTestSession(id: 's1', projectPath: '/x/alpha'),
        createTestSession(id: 's2', projectPath: '/x/alpha'),
        createTestSession(id: 's3', projectPath: '/x/alpha'),
        createTestSession(id: 's4', projectPath: '/y/beta'),
      ]));

      expect(find.text('alpha (3)'), findsOneWidget);
      expect(find.text('beta (1)'), findsOneWidget);
    });

    // TC-35-03: 空 projectPath 顯示 "Other"
    testWidgets('empty projectPath displays as Other tab', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage([
        createTestSession(id: 's1', projectPath: '/a/proj1'),
        createTestSession(id: 's2', projectPath: ''),
      ]));

      expect(find.text('Other (1)'), findsOneWidget);

      // Other tab should be last
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      final tooltips = tabBar.tabs.cast<Tooltip>();
      final lastTab = (tooltips.last.child! as ConstrainedBox).child! as Tab;
      expect((lastTab.child! as Text).data, 'Other (1)');
    });

    // TC-35-04: Tab 切換後顯示對應專案的 sessions
    testWidgets('switching tabs shows corresponding project sessions',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage([
        createTestSession(
          id: 's1',
          projectPath: '/a/alpha',
          summary: 'Alpha Task',
          status: SessionStatus.active,
        ),
        createTestSession(
          id: 's2',
          projectPath: '/b/beta',
          summary: 'Beta Task',
          status: SessionStatus.active,
        ),
      ]));

      // First tab (alpha) selected by default
      expect(find.text('Alpha Task'), findsOneWidget);

      // Switch to beta tab
      await tester.tap(find.text('beta (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Beta Task'), findsOneWidget);
    });

    // TC-35-05: 搜尋跨 Tab 生效
    testWidgets('search filters apply across tabs', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
            overrides: [
              webSocketServiceProvider.overrideWithValue(mockService),
            ],
          ),
          child: const MaterialApp(home: Scaffold(body: SessionListPage())),
        ),
      );
      await tester.pump();

      messageController.add(createSessionListMessage([
        createTestSession(
          id: 's1',
          projectPath: '/a/alpha',
          summary: 'auth login',
          status: SessionStatus.active,
        ),
        createTestSession(
          id: 's2',
          projectPath: '/a/alpha',
          summary: 'dashboard',
          status: SessionStatus.active,
        ),
        createTestSession(
          id: 's3',
          projectPath: '/b/beta',
          summary: 'auth signup',
          status: SessionStatus.active,
        ),
      ]));
      await tester.pump();
      await tester.pump();

      // Set search query
      final searchNotifier =
          container.read(sessionListSearchNotifierProvider.notifier);
      searchNotifier.openSearch();
      searchNotifier.updateQuery('auth');
      await tester.pump();
      await tester.pump();

      // Force debounce to complete
      await tester.pump(const Duration(milliseconds: 350));

      // Alpha tab: only 'auth login' visible, not 'dashboard'
      expect(find.text('auth login'), findsOneWidget);
      expect(find.text('dashboard'), findsNothing);

      // Switch to beta tab (tab label shows unfiltered count)
      await tester.tap(find.text('beta (1)'));
      await tester.pumpAndSettle();

      // Beta tab: only 'auth signup' visible
      expect(find.text('auth signup'), findsOneWidget);

      container.dispose();
    });

    // TC-35-06: Tab 排序按字母排序，Other 排最後
    testWidgets('tabs sorted alphabetically with Other last', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage([
        createTestSession(id: 's1', projectPath: '/x/zoo'),
        createTestSession(id: 's2', projectPath: '/x/alpha'),
        createTestSession(id: 's3', projectPath: '/x/beta'),
        createTestSession(id: 's4', projectPath: ''),
      ]));

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      final tooltips = tabBar.tabs.cast<Tooltip>();
      expect(tooltips.length, 4);
      String tabText(int i) {
        final tab = (tooltips[i].child! as ConstrainedBox).child! as Tab;
        return (tab.child! as Text).data!;
      }
      expect(tabText(0), 'alpha (1)');
      expect(tabText(1), 'beta (1)');
      expect(tabText(2), 'zoo (1)');
      expect(tabText(3), 'Other (1)');
    });

    // TC-35-07: TabBar 可捲動（isScrollable: true）
    testWidgets('TabBar is scrollable', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage(
        List.generate(
          6,
          (i) => createTestSession(
            id: 's$i',
            projectPath: '/x/project$i',
          ),
        ),
      ));

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.isScrollable, isTrue);
    });

    // TC-35-08: 空 sessions 時不顯示 TabBar
    testWidgets('no TabBar when sessions list is empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await sendMessage(tester, createSessionListMessage([]));

      expect(find.byType(TabBar), findsNothing);
      expect(find.text('No sessions'), findsOneWidget);
    });
  });
}
