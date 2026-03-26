import 'package:ccsession/features/split_view/domain/layout_mode.dart';
import 'package:ccsession/features/split_view/domain/panel_state.dart';
import 'package:ccsession/features/split_view/presentation/split_view_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplitViewState', () {
    // A-S01
    test('default values', () {
      const state = SplitViewState();
      expect(state.layoutMode, LayoutMode.single);
      expect(state.panels, isEmpty);
      expect(state.activePanelIndex, 0);
      expect(state.maximizedPanelIndex, isNull);
    });

    // A-S02
    test('equal states are equal', () {
      const a = SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [PanelState(panelIndex: 0)],
        activePanelIndex: 0,
      );
      const b = SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [PanelState(panelIndex: 0)],
        activePanelIndex: 0,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    // A-S03
    test('different states are not equal', () {
      const a = SplitViewState(layoutMode: LayoutMode.single);
      const b = SplitViewState(layoutMode: LayoutMode.splitHorizontal);
      expect(a, isNot(equals(b)));
    });

    // A-S04
    test('copyWith preserves unchanged fields', () {
      const original = SplitViewState(
        layoutMode: LayoutMode.single,
        activePanelIndex: 0,
      );
      final copied = original.copyWith(
        layoutMode: LayoutMode.splitHorizontal,
      );
      expect(copied.layoutMode, LayoutMode.splitHorizontal);
      expect(copied.activePanelIndex, 0);
      expect(original.layoutMode, LayoutMode.single);
    });

    test('copyWith can set maximizedPanelIndex to null', () {
      const state = SplitViewState(maximizedPanelIndex: 1);
      final cleared = state.copyWith(maximizedPanelIndex: null);
      expect(cleared.maximizedPanelIndex, isNull);
    });

    test('copyWith preserves maximizedPanelIndex when not passed', () {
      const state = SplitViewState(maximizedPanelIndex: 1);
      final copied = state.copyWith(layoutMode: LayoutMode.grid2x2);
      expect(copied.maximizedPanelIndex, 1);
    });
  });
}
