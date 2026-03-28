import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/widgets/session_group_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-13: SessionGroupHeader', () {
    Widget buildSubject(
      SessionStatus status,
      int count, {
      bool isExpanded = true,
      VoidCallback? onToggleExpand,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SessionGroupHeader(
            status: status,
            count: count,
            isExpanded: isExpanded,
            onToggleExpand: onToggleExpand ?? () {},
          ),
        ),
      );
    }

    // TC-13-01: 顯示狀態名稱和計數
    testWidgets('displays status name and count', (tester) async {
      await tester.pumpWidget(buildSubject(SessionStatus.active, 3));

      expect(find.text('Active (3)'), findsOneWidget);
    });

    // TC-13-02: 各狀態名稱正確
    testWidgets('displays correct name for each status', (tester) async {
      await tester.pumpWidget(buildSubject(SessionStatus.active, 1));
      expect(find.text('Active (1)'), findsOneWidget);

      await tester.pumpWidget(buildSubject(SessionStatus.idle, 2));
      expect(find.text('Idle (2)'), findsOneWidget);

      await tester.pumpWidget(buildSubject(SessionStatus.completed, 5));
      expect(find.text('Completed (5)'), findsOneWidget);
    });

    // TC-13-03: 展開狀態 — 顯示展開圖示
    testWidgets('shows expand_less icon when expanded', (tester) async {
      await tester.pumpWidget(
        buildSubject(SessionStatus.active, 3, isExpanded: true),
      );

      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    // TC-13-04: 摺疊狀態 — 顯示摺疊圖示
    testWidgets('shows expand_more icon when collapsed', (tester) async {
      await tester.pumpWidget(
        buildSubject(SessionStatus.active, 3, isExpanded: false),
      );

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    // TC-13-05: 點擊 Header — 觸發 onToggleExpand
    testWidgets('tapping header calls onToggleExpand', (tester) async {
      var called = false;
      await tester.pumpWidget(
        buildSubject(
          SessionStatus.active,
          3,
          onToggleExpand: () => called = true,
        ),
      );

      await tester.tap(find.text('Active (3)'));
      expect(called, isTrue);
    });

    // TC-13-06: 向下相容 — 既有顯示不受影響
    testWidgets('backward compatible display with isExpanded=true',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(SessionStatus.active, 3, isExpanded: true),
      );

      expect(find.text('Active (3)'), findsOneWidget);
    });
  });
}
