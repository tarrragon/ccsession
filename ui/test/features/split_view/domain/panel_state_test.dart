import 'package:ccsession/features/split_view/domain/panel_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PanelState', () {
    // A-P01
    test('empty panel has null sessionId', () {
      const panel = PanelState(panelIndex: 0);
      expect(panel.panelIndex, 0);
      expect(panel.sessionId, isNull);
    });

    // A-P02
    test('panel with session stores sessionId', () {
      const panel = PanelState(panelIndex: 1, sessionId: 'abc-123');
      expect(panel.panelIndex, 1);
      expect(panel.sessionId, 'abc-123');
    });

    // A-P03
    test('equal panels are equal', () {
      const a = PanelState(panelIndex: 0, sessionId: 'abc');
      const b = PanelState(panelIndex: 0, sessionId: 'abc');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different panels are not equal', () {
      const a = PanelState(panelIndex: 0, sessionId: 'abc');
      const b = PanelState(panelIndex: 1, sessionId: 'abc');
      expect(a, isNot(equals(b)));
    });
  });
}
