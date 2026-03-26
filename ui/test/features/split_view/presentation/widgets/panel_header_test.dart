import 'package:ccsession/features/split_view/domain/layout_mode.dart';
import 'package:ccsession/features/split_view/domain/panel_state.dart';
import 'package:ccsession/features/split_view/presentation/split_view_state.dart';
import 'package:ccsession/features/split_view/presentation/widgets/panel_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/split_view_test_helpers.dart';

void main() {
  group('PanelHeader', () {
    // C-PH01
    testWidgets('displays session id as fallback name', (tester) async {
      await tester.pumpWidget(buildSplitViewTestWidget(
        const SplitViewState(
          layoutMode: LayoutMode.splitHorizontal,
          panels: [
            PanelState(panelIndex: 0, sessionId: 'session-A'),
            PanelState(panelIndex: 1),
          ],
        ),
        child: const PanelHeader(panelIndex: 0),
      ));
      await tester.pumpAndSettle();

      expect(find.text('session-A'), findsOneWidget);
    });

    // C-PH02
    testWidgets('maximize button exists with correct icon', (tester) async {
      await tester.pumpWidget(buildSplitViewTestWidget(
        const SplitViewState(
          layoutMode: LayoutMode.splitHorizontal,
          panels: [
            PanelState(panelIndex: 0, sessionId: 'A'),
            PanelState(panelIndex: 1),
          ],
        ),
        child: const PanelHeader(panelIndex: 0),
      ));
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('panel_0_maximize'));
      expect(button, findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    });

    // C-PH04
    testWidgets('close button exists and is tappable', (tester) async {
      await tester.pumpWidget(buildSplitViewTestWidget(
        const SplitViewState(
          layoutMode: LayoutMode.splitHorizontal,
          panels: [
            PanelState(panelIndex: 0, sessionId: 'A'),
            PanelState(panelIndex: 1),
          ],
        ),
        child: const PanelHeader(panelIndex: 0),
      ));
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('panel_0_close'));
      expect(button, findsOneWidget);
    });

    // C-PH05
    testWidgets('double tap triggers maximize', (tester) async {
      await tester.pumpWidget(buildSplitViewTestWidget(
        const SplitViewState(
          layoutMode: LayoutMode.splitHorizontal,
          panels: [
            PanelState(panelIndex: 0, sessionId: 'A'),
            PanelState(panelIndex: 1),
          ],
        ),
        child: const PanelHeader(panelIndex: 0),
      ));
      await tester.pumpAndSettle();

      // Find header area (the Container with the Row)
      final header = find.byType(PanelHeader);
      expect(header, findsOneWidget);

      // Double tap on the header area
      await tester.tap(header);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(header);
      await tester.pumpAndSettle();
    });
  });
}
