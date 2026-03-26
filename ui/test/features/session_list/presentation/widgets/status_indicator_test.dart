import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/widgets/status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-15: StatusIndicator', () {
    Widget buildSubject(SessionStatus status) {
      return MaterialApp(
        home: Scaffold(body: StatusIndicator(status: status)),
      );
    }

    Container findIndicatorContainer(WidgetTester tester) {
      return tester.widget<Container>(find.byType(Container).last);
    }

    // TC-15-01: active 狀態顯示綠色
    testWidgets('active status shows green', (tester) async {
      await tester.pumpWidget(buildSubject(SessionStatus.active));

      final container = findIndicatorContainer(tester);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, equals(Colors.green));
    });

    // TC-15-02: idle 狀態顯示琥珀色
    testWidgets('idle status shows amber', (tester) async {
      await tester.pumpWidget(buildSubject(SessionStatus.idle));

      final container = findIndicatorContainer(tester);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, equals(Colors.amber));
    });

    // TC-15-03: completed 狀態顯示灰色
    testWidgets('completed status shows grey', (tester) async {
      await tester.pumpWidget(buildSubject(SessionStatus.completed));

      final container = findIndicatorContainer(tester);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, equals(Colors.grey));
    });
  });
}
