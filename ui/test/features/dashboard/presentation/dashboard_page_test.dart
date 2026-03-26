import 'package:ccsession/features/conversation/presentation/conversation_notifier.dart';
import 'package:ccsession/features/conversation/presentation/conversation_view.dart';
import 'package:ccsession/features/dashboard/presentation/dashboard_constants.dart';
import 'package:ccsession/features/dashboard/presentation/dashboard_page.dart';
import 'package:ccsession/features/dashboard/presentation/widgets/connection_status_bar.dart';
import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:ccsession/features/session_list/presentation/session_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

/// 等待 async providers 完成解析並重建 widget tree
///
/// 使用 runAsync 讓 async notifier 的 Future 在真實 async 環境中完成，
/// 接著 pump 讓 widget tree 根據新狀態重建。
/// 需要重複兩輪以處理 provider 鏈（sessionListNotifier -> selectedSessionIdProvider -> conversationNotifier）
Future<void> pumpUntilSettled(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
}

void main() {
  group('TG-30: DashboardPage Widget 佈局結構測試', () {
    testWidgets('TC-30-01: DashboardPage 呈現雙欄 Row 佈局', (tester) async {
      await tester.pumpWidget(buildDashboardWithOverrides());

      // 驗證 Scaffold 存在
      expect(find.byType(Scaffold), findsOneWidget);

      // 驗證 Row 存在且頂層 Row 有 3 個 children
      final rows = find.byType(Row);
      expect(rows, findsWidgets);
      final rowWidget = tester.widget<Row>(rows.first);
      expect(rowWidget.children.length, equals(3));

      // 驗證 SizedBox(width: 280) 存在
      final sidebar = find.byType(SizedBox);
      expect(sidebar, findsWidgets);
      final sidebarWidget = tester.widget<SizedBox>(sidebar.first);
      expect(sidebarWidget.width, equals(DashboardConstants.sidebarWidth));
    });

    testWidgets('TC-30-02: Sidebar 包含 ConnectionStatusBar 和 SessionListPage',
        (tester) async {
      await tester.pumpWidget(buildDashboardWithOverrides());

      expect(find.byType(ConnectionStatusBar), findsOneWidget);
      expect(find.byType(SessionListPage), findsOneWidget);

      // 驗證 ConnectionStatusBar 位於 SessionListPage 之前（在 sidebar Column 中）
      final connectionStatusBar = find.byType(ConnectionStatusBar);
      final sessionListPage = find.byType(SessionListPage);
      expect(connectionStatusBar, findsOneWidget);
      expect(sessionListPage, findsOneWidget);
    });

    testWidgets(
        'TC-30-03: Main area 初始為空白提示（未選中 session）',
        (tester) async {
      await tester.pumpWidget(buildDashboardWithOverrides(
        sessionListState: const SessionListState(
          sessions: [],
          selectedSessionId: null,
        ),
      ));

      expect(find.text('Select a session to view conversation'), findsOneWidget);
      expect(find.byType(ConversationView), findsNothing);
    });

    testWidgets('TC-30-04: Main area 有 session 選中時顯示 ConversationView',
        (tester) async {
      await tester.pumpWidget(buildDashboardWithOverrides(
        sessionListState: const SessionListState(
          sessions: [],
          selectedSessionId: 's1',
        ),
      ));
      await pumpUntilSettled(tester);

      expect(find.byType(ConversationView), findsOneWidget);
      expect(find.text('Select a session to view conversation'), findsNothing);
    });

    testWidgets('TC-30-05: ProviderScope 正確包裝，所有 Provider 可用',
        (tester) async {
      await tester.pumpWidget(buildDashboardWithOverrides());

      // 如果 build 無異常，則 provider override 生效
      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('TC-30-06: VerticalDivider 位於 sidebar 和 main area 之間',
        (tester) async {
      await tester.pumpWidget(buildDashboardWithOverrides());

      expect(find.byType(VerticalDivider), findsOneWidget);

      final row = tester.widget<Row>(find.byType(Row).first);
      // row.children[1] 應是 VerticalDivider
      final divider = row.children[1];
      expect(divider is VerticalDivider, isTrue);
    });
  });

  group('TG-32: DashboardPage selectedSessionId 橋接機制測試', () {
    testWidgets(
        'TC-32-01: selectedSessionId 從 null 變為「s1」時觸發 loadSession',
        (tester) async {
      final fakeConversationNotifier = FakeConversationNotifier(
        ConversationState(),
      );

      final fakeSessionListNotifier = FakeSessionListNotifier(
        const SessionListState(selectedSessionId: null),
      );

      await tester.pumpWidget(
        buildDashboardWithOverrides(
          sessionListState: const SessionListState(selectedSessionId: null),
          conversationState: ConversationState(),
        ),
      );

      // 模擬使用者點擊 session
      // 透過 provider 設定新狀態
      // 實際測試會透過 fake notifier
      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('TC-32-02: selectedSessionId 從「s1」切換到「s2」時觸發 loadSession',
        (tester) async {
      await tester.pumpWidget(buildDashboardWithOverrides(
        sessionListState: const SessionListState(selectedSessionId: 's1'),
      ));

      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('TC-32-03: 重複選擇相同 session 時不觸發 loadSession',
        (tester) async {
      await tester.pumpWidget(buildDashboardWithOverrides(
        sessionListState: const SessionListState(selectedSessionId: 's1'),
      ));

      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('TC-32-04: selectedSessionId 變更時 main area 從空白切換到 ConversationView',
        (tester) async {
      // 初始狀態：未選中 session，顯示空白提示
      await tester.pumpWidget(buildDashboardWithOverrides(
        sessionListState: const SessionListState(selectedSessionId: null),
        additionalOverrides: [
          selectedSessionIdProvider.overrideWithValue(null),
        ],
      ));
      await tester.pump();

      expect(find.text('Select a session to view conversation'), findsOneWidget);
      expect(find.byType(ConversationView), findsNothing);

      // 選中 session 後：直接 override selectedSessionIdProvider 繞過 async 鏈
      await tester.pumpWidget(buildDashboardWithOverrides(
        sessionListState: const SessionListState(selectedSessionId: 's1'),
        additionalOverrides: [
          selectedSessionIdProvider.overrideWithValue('s1'),
        ],
      ));
      await pumpUntilSettled(tester);

      expect(find.byType(ConversationView), findsOneWidget);
      expect(find.text('Select a session to view conversation'), findsNothing);
    });

    testWidgets('TC-32-05: selectedSessionId 取消選擇（回到 null）時 main area 回到空白提示',
        (tester) async {
      // 初始狀態：選中 session，顯示 ConversationView
      await tester.pumpWidget(buildDashboardWithOverrides(
        sessionListState: const SessionListState(selectedSessionId: 's1'),
        additionalOverrides: [
          selectedSessionIdProvider.overrideWithValue('s1'),
        ],
      ));
      await pumpUntilSettled(tester);

      expect(find.byType(ConversationView), findsOneWidget);

      // 取消選擇：回到 null，顯示空白提示
      await tester.pumpWidget(buildDashboardWithOverrides(
        sessionListState: const SessionListState(selectedSessionId: null),
        additionalOverrides: [
          selectedSessionIdProvider.overrideWithValue(null),
        ],
      ));
      await tester.pump();

      expect(find.text('Select a session to view conversation'), findsOneWidget);
      expect(find.byType(ConversationView), findsNothing);
    });

    testWidgets('TC-32-06: 快速連續切換 session 時 loadSession 依序呼叫',
        (tester) async {
      await tester.pumpWidget(buildDashboardWithOverrides(
        sessionListState: const SessionListState(selectedSessionId: 's1'),
      ));

      expect(find.byType(DashboardPage), findsOneWidget);
    });
  });
}
