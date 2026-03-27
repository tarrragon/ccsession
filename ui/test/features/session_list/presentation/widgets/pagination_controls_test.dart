import 'package:ccsession/features/session_list/presentation/widgets/pagination_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-22: PaginationControls', () {
    int? lastPage;

    Widget buildSubject({required int currentPage, required int totalPages}) {
      lastPage = null;
      return MaterialApp(
        home: Scaffold(
          body: PaginationControls(
            currentPage: currentPage,
            totalPages: totalPages,
            onPageChanged: (page) => lastPage = page,
          ),
        ),
      );
    }

    // TC-22-01: 顯示頁碼資訊
    testWidgets('displays page info text', (tester) async {
      await tester.pumpWidget(buildSubject(currentPage: 0, totalPages: 3));

      expect(find.text('1 / 3'), findsOneWidget);
    });

    // TC-22-02: 第一頁 — 上一頁按鈕禁用
    testWidgets('first page disables prev button', (tester) async {
      await tester.pumpWidget(buildSubject(currentPage: 0, totalPages: 3));

      final prevButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      expect(prevButton.onPressed, isNull);

      final nextButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(nextButton.onPressed, isNotNull);
    });

    // TC-22-03: 最後一頁 — 下一頁按鈕禁用
    testWidgets('last page disables next button', (tester) async {
      await tester.pumpWidget(buildSubject(currentPage: 2, totalPages: 3));

      final nextButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(nextButton.onPressed, isNull);

      final prevButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      expect(prevButton.onPressed, isNotNull);
    });

    // TC-22-04: 中間頁 — 兩個按鈕皆啟用
    testWidgets('middle page enables both buttons', (tester) async {
      await tester.pumpWidget(buildSubject(currentPage: 1, totalPages: 3));

      final prevButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      expect(prevButton.onPressed, isNotNull);

      final nextButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(nextButton.onPressed, isNotNull);
    });

    // TC-22-05: 點擊下一頁 — 觸發 onPageChanged
    testWidgets('tapping next calls onPageChanged with incremented page',
        (tester) async {
      await tester.pumpWidget(buildSubject(currentPage: 0, totalPages: 3));

      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(lastPage, 1);
    });

    // TC-22-06: 點擊上一頁 — 觸發 onPageChanged
    testWidgets('tapping prev calls onPageChanged with decremented page',
        (tester) async {
      await tester.pumpWidget(buildSubject(currentPage: 2, totalPages: 3));

      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(lastPage, 1);
    });

    // TC-22-07: 僅一頁 — 由 TG-21 保證不渲染
    // (PaginationControls 本身不需處理 totalPages=1，由 flattenGroups 決定)
    test('totalPages=1 case is handled by flattenGroups (TG-21-01)', () {
      // Documented: PaginationItem not added when totalPages <= 1
    });
  });
}
