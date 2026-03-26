import 'package:ccsession/features/split_view/domain/layout_mode.dart';
import 'package:ccsession/features/split_view/domain/panel_state.dart';
import 'package:ccsession/features/split_view/domain/split_view_state.dart';
import 'package:ccsession/features/split_view/presentation/widgets/panel_header.dart';
import 'package:ccsession/features/split_view/presentation/widgets/session_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/split_view_test_helpers.dart';

/// 測試用 contentBuilder，回傳帶 key 的 Text Widget
Widget _testContentBuilder(int panelIndex) =>
    Text('TestContent-$panelIndex', key: Key('test_content_$panelIndex'));

void main() {
  group('SessionPanel', () {
    // C-SP01
    testWidgets('empty panel shows placeholder', (tester) async {
      await tester.pumpWidget(buildSplitViewTestWidget(
        const SplitViewState(
          layoutMode: LayoutMode.splitHorizontal,
          panels: [PanelState(panelIndex: 0), PanelState(panelIndex: 1)],
        ),
        child: SessionPanel(panelIndex: 0, contentBuilder: _testContentBuilder),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty_panel_placeholder')), findsOneWidget);
      expect(find.text('TestContent-0'), findsNothing);
    });

    // C-SP02
    testWidgets('panel with session shows ConversationView', (tester) async {
      await tester.pumpWidget(buildSplitViewTestWidget(
        const SplitViewState(
          layoutMode: LayoutMode.splitHorizontal,
          panels: [
            PanelState(panelIndex: 0, sessionId: 'session-A'),
            PanelState(panelIndex: 1),
          ],
        ),
        child: SessionPanel(panelIndex: 0, contentBuilder: _testContentBuilder),
        conversationFactory: () =>
            FakeConversationNotifier(initialSessionId: 'test'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PanelHeader), findsOneWidget);
      expect(find.text('TestContent-0'), findsOneWidget);
    });

    // C-SP03
    testWidgets('single mode does not show PanelHeader', (tester) async {
      await tester.pumpWidget(buildSplitViewTestWidget(
        const SplitViewState(
          layoutMode: LayoutMode.single,
          panels: [PanelState(panelIndex: 0, sessionId: 'session-A')],
        ),
        child: SessionPanel(panelIndex: 0, contentBuilder: _testContentBuilder),
        panelCount: 1,
        conversationFactory: () =>
            FakeConversationNotifier(initialSessionId: 'test'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PanelHeader), findsNothing);
      expect(find.text('TestContent-0'), findsOneWidget);
    });
  });
}
