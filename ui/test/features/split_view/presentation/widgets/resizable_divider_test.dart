import 'package:ccsession/features/split_view/presentation/widgets/resizable_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResizableDivider', () {
    // C-RD01
    testWidgets('horizontal drag triggers onDrag callback', (tester) async {
      double? dragDelta;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ResizableDivider(
            axis: Axis.horizontal,
            onDrag: (delta) => dragDelta = delta,
          ),
        ),
      ));

      final divider = find.byType(ResizableDivider);
      expect(divider, findsOneWidget);

      await tester.drag(divider, const Offset(50, 0));
      expect(dragDelta, isNotNull);
    });

    // C-RD02
    testWidgets('vertical drag triggers onDrag callback', (tester) async {
      double? dragDelta;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ResizableDivider(
            axis: Axis.vertical,
            onDrag: (delta) => dragDelta = delta,
          ),
        ),
      ));

      final divider = find.byType(ResizableDivider);
      await tester.drag(divider, const Offset(0, 50));
      expect(dragDelta, isNotNull);
    });

    // C-RD03
    testWidgets('renders with correct dimensions', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ResizableDivider(
            axis: Axis.horizontal,
            onDrag: (_) {},
          ),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).last);
      expect(container.constraints?.maxWidth, ResizableDivider.thickness);
    });
  });
}
