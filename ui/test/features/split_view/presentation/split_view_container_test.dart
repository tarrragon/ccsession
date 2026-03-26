import 'package:flutter/material.dart';
import 'package:ccsession/features/split_view/domain/layout_mode.dart';
import 'package:ccsession/features/split_view/domain/panel_state.dart';
import 'package:ccsession/features/split_view/presentation/split_view_container.dart';
import 'package:ccsession/features/split_view/presentation/split_view_notifier.dart';
import 'package:ccsession/features/split_view/domain/split_view_state.dart';
import 'package:ccsession/features/split_view/presentation/widgets/resizable_divider.dart';
import 'package:ccsession/features/split_view/presentation/widgets/session_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/split_view_test_helpers.dart';

void main() {
  group('SplitViewContainer', () {
    // C-SC01
    testWidgets('single mode renders one SessionPanel', (tester) async {
      await tester.pumpWidget(buildSplitViewTestWidget(
        const SplitViewState(
          layoutMode: LayoutMode.single,
          panels: [PanelState(panelIndex: 0)],
        ),
        child: SplitViewContainer(
          contentBuilder: (index) => Text('Panel-$index'),
        ),
        panelCount: 1,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SessionPanel), findsOneWidget);
      expect(find.byType(ResizableDivider), findsNothing);
    });

    // C-SC02
    testWidgets('splitHorizontal renders two panels with divider',
        (tester) async {
      await tester.pumpWidget(buildSplitViewTestWidget(
        const SplitViewState(
          layoutMode: LayoutMode.splitHorizontal,
          panels: [PanelState(panelIndex: 0), PanelState(panelIndex: 1)],
        ),
        child: SplitViewContainer(
          contentBuilder: (index) => Text('Panel-$index'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SessionPanel), findsNWidgets(2));
      expect(find.byType(ResizableDivider), findsOneWidget);
    });

    // C-SC03
    testWidgets('splitVertical renders two panels with divider',
        (tester) async {
      await tester.pumpWidget(buildSplitViewTestWidget(
        const SplitViewState(
          layoutMode: LayoutMode.splitVertical,
          panels: [PanelState(panelIndex: 0), PanelState(panelIndex: 1)],
        ),
        child: SplitViewContainer(
          contentBuilder: (index) => Text('Panel-$index'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SessionPanel), findsNWidgets(2));
      expect(find.byType(ResizableDivider), findsOneWidget);
    });

    // C-SC04
    testWidgets('grid2x2 renders four panels', (tester) async {
      await tester.pumpWidget(buildSplitViewTestWidget(
        const SplitViewState(
          layoutMode: LayoutMode.grid2x2,
          panels: [
            PanelState(panelIndex: 0),
            PanelState(panelIndex: 1),
            PanelState(panelIndex: 2),
            PanelState(panelIndex: 3),
          ],
        ),
        child: SplitViewContainer(
          contentBuilder: (index) => Text('Panel-$index'),
        ),
        panelCount: 4,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SessionPanel), findsNWidgets(4));
      expect(find.byType(ResizableDivider), findsWidgets);
    });

    // C-SC05
    testWidgets('maximized state shows only one panel', (tester) async {
      await tester.pumpWidget(buildSplitViewTestWidget(
        const SplitViewState(
          layoutMode: LayoutMode.splitHorizontal,
          panels: [PanelState(panelIndex: 0), PanelState(panelIndex: 1)],
        ),
        child: SplitViewContainer(
          contentBuilder: (index) => Text('Panel-$index'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(SessionPanel), findsNWidgets(2));

      // Trigger maximize via notifier
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SplitViewContainer)),
      );
      container.read(splitViewNotifierProvider.notifier).maximizePanel(0);
      await tester.pumpAndSettle();

      expect(find.byType(SessionPanel), findsOneWidget);
      expect(find.byType(ResizableDivider), findsNothing);
    });
  });
}
