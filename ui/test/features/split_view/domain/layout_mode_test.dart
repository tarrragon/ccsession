import 'package:ccsession/features/split_view/domain/layout_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LayoutMode', () {
    test('single has panelCount 1', () {
      expect(LayoutMode.single.panelCount, 1);
    });

    test('splitHorizontal has panelCount 2', () {
      expect(LayoutMode.splitHorizontal.panelCount, 2);
    });

    test('splitVertical has panelCount 2', () {
      expect(LayoutMode.splitVertical.panelCount, 2);
    });

    test('grid2x2 has panelCount 4', () {
      expect(LayoutMode.grid2x2.panelCount, 4);
    });

    test('has exactly 4 values', () {
      expect(LayoutMode.values.length, 4);
    });
  });
}
