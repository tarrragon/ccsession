import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/widgets/session_group_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-13: SessionGroupHeader', () {
    Widget buildSubject(SessionStatus status, int count) {
      return MaterialApp(
        home: Scaffold(
          body: SessionGroupHeader(status: status, count: count),
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
      // Active
      await tester.pumpWidget(buildSubject(SessionStatus.active, 1));
      expect(find.text('Active (1)'), findsOneWidget);

      // Idle
      await tester.pumpWidget(buildSubject(SessionStatus.idle, 2));
      expect(find.text('Idle (2)'), findsOneWidget);

      // Completed
      await tester.pumpWidget(buildSubject(SessionStatus.completed, 5));
      expect(find.text('Completed (5)'), findsOneWidget);
    });
  });
}
