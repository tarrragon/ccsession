import 'package:ccsession/features/split_view/data/split_view_storage.dart';
import 'package:ccsession/features/split_view/domain/layout_mode.dart';
import 'package:ccsession/features/split_view/domain/panel_state.dart';
import 'package:ccsession/features/split_view/domain/split_view_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPrefsSplitViewStorage', () {
    late SharedPrefsSplitViewStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = SharedPrefsSplitViewStorage(prefs);
    });

    // A-ST01
    test('save then load returns same state', () async {
      const state = SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'session-A'),
          PanelState(panelIndex: 1, sessionId: 'session-B'),
        ],
      );
      await storage.save(state);
      final loaded = await storage.load();

      expect(loaded, isNotNull);
      expect(loaded!.layoutMode, LayoutMode.splitHorizontal);
      expect(loaded.panels[0].sessionId, 'session-A');
      expect(loaded.panels[1].sessionId, 'session-B');
    });

    // A-ST02
    test('save only persists layoutMode and panels.sessionId', () async {
      const state = SplitViewState(
        layoutMode: LayoutMode.grid2x2,
        panels: [PanelState(panelIndex: 0)],
        activePanelIndex: 2,
        maximizedPanelIndex: 1,
      );
      await storage.save(state);
      final loaded = await storage.load();

      expect(loaded!.activePanelIndex, 0);
      expect(loaded.maximizedPanelIndex, isNull);
    });

    // A-ST03
    test('load returns null when key does not exist', () async {
      final loaded = await storage.load();
      expect(loaded, isNull);
    });

    // A-ST04
    test('load returns null for invalid JSON', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsSplitViewStorage.storageKey: '{{invalid json',
      });
      final prefs = await SharedPreferences.getInstance();
      final s = SharedPrefsSplitViewStorage(prefs);
      final loaded = await s.load();
      expect(loaded, isNull);
    });

    // A-ST05
    test('clear then load returns null', () async {
      const state = SplitViewState(
        layoutMode: LayoutMode.single,
        panels: [PanelState(panelIndex: 0)],
      );
      await storage.save(state);
      await storage.clear();
      final loaded = await storage.load();
      expect(loaded, isNull);
    });

    // W6-004: 錯誤的 layoutMode 值回傳 null
    test('load returns null for invalid layoutMode value', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsSplitViewStorage.storageKey:
            '{"layoutMode":"nonExistent","panels":[]}',
      });
      final prefs = await SharedPreferences.getInstance();
      final s = SharedPrefsSplitViewStorage(prefs);
      final loaded = await s.load();
      expect(loaded, isNull);
    });

    // W6-004: 缺少必要欄位回傳 null
    test('load returns null when required fields are missing', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsSplitViewStorage.storageKey: '{"unrelated":"data"}',
      });
      final prefs = await SharedPreferences.getInstance();
      final s = SharedPrefsSplitViewStorage(prefs);
      final loaded = await s.load();
      expect(loaded, isNull);
    });

    // A-ST06
    test('save and load empty panels list', () async {
      const state = SplitViewState(
        layoutMode: LayoutMode.single,
        panels: [],
      );
      await storage.save(state);
      final loaded = await storage.load();
      expect(loaded!.panels, isEmpty);
    });
  });
}
