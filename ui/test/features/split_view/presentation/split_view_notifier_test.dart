import 'package:ccsession/features/split_view/data/split_view_storage.dart';
import 'package:ccsession/features/split_view/domain/layout_mode.dart';
import 'package:ccsession/features/split_view/domain/panel_state.dart';
import 'package:ccsession/features/split_view/presentation/split_view_notifier.dart';
import 'package:ccsession/features/split_view/domain/split_view_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_split_view_storage.dart';

Future<void> _pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  group('SplitViewNotifier', () {
    late ProviderContainer container;
    late FakeSplitViewStorage fakeStorage;

    setUp(() {
      fakeStorage = FakeSplitViewStorage();
      container = ProviderContainer(
        overrides: [
          splitViewStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
    });

    tearDown(() => container.dispose());

    Future<void> initNotifier() async {
      container.listen(splitViewNotifierProvider, (_, __) {});
      await _pump();
    }

    SplitViewState getState() {
      return container.read(splitViewNotifierProvider).requireValue;
    }

    SplitViewNotifier getNotifier() {
      return container.read(splitViewNotifierProvider.notifier);
    }

    // --- build ---

    // A-N51
    test('build — fallback to default when no persisted state', () async {
      await initNotifier();
      final state = getState();
      expect(state.layoutMode, LayoutMode.single);
      expect(state.panels.length, 1);
      expect(state.panels[0].panelIndex, 0);
    });

    // A-N50
    test('build — loads persisted state', () async {
      fakeStorage.loadResult = const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
        ],
      );
      await initNotifier();
      final state = getState();
      expect(state.layoutMode, LayoutMode.splitHorizontal);
      expect(state.panels[0].sessionId, 'A');
      expect(state.panels[1].sessionId, 'B');
    });

    // A-N52
    test('build — fallback when storage returns null (corrupt)', () async {
      // loadResult defaults to null
      await initNotifier();
      expect(getState().layoutMode, LayoutMode.single);
    });

    // A-N53
    test('build — pads panels when fewer than layoutMode expects', () async {
      fakeStorage.loadResult = const SplitViewState(
        layoutMode: LayoutMode.grid2x2,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
        ],
      );
      await initNotifier();
      final state = getState();
      expect(state.panels.length, 4);
      expect(state.panels[0].sessionId, 'A');
      expect(state.panels[1].sessionId, 'B');
      expect(state.panels[2].sessionId, isNull);
      expect(state.panels[3].sessionId, isNull);
    });

    // A-N54
    test('build — trims panels when more than layoutMode expects', () async {
      fakeStorage.loadResult = const SplitViewState(
        layoutMode: LayoutMode.single,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
          PanelState(panelIndex: 2, sessionId: 'C'),
          PanelState(panelIndex: 3, sessionId: 'D'),
        ],
      );
      await initNotifier();
      final state = getState();
      expect(state.panels.length, 1);
      expect(state.panels[0].sessionId, 'A');
    });

    // --- switchLayout ---

    Future<void> initWithState(SplitViewState s) async {
      fakeStorage.loadResult = s;
      await initNotifier();
      fakeStorage.saveCallCount = 0; // reset
    }

    // A-N01
    test('switchLayout: single -> splitHorizontal', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.single,
        panels: [PanelState(panelIndex: 0, sessionId: 'session-A')],
      ));
      expect(getState().layoutMode, LayoutMode.single);

      getNotifier().switchLayout(LayoutMode.splitHorizontal);
      final state = getState();
      expect(state.layoutMode, LayoutMode.splitHorizontal);
      expect(state.panels.length, 2);
      expect(state.panels[0].sessionId, 'session-A');
      expect(state.panels[1].sessionId, isNull);
      expect(fakeStorage.saveCallCount, 1);
    });

    // A-N02
    test('switchLayout: single -> grid2x2', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.single,
        panels: [PanelState(panelIndex: 0, sessionId: 'session-A')],
      ));
      getNotifier().switchLayout(LayoutMode.grid2x2);
      final state = getState();
      expect(state.layoutMode, LayoutMode.grid2x2);
      expect(state.panels.length, 4);
      expect(state.panels[0].sessionId, 'session-A');
      expect(state.panels[1].sessionId, isNull);
      expect(state.panels[2].sessionId, isNull);
      expect(state.panels[3].sessionId, isNull);
    });

    // A-N03
    test('switchLayout: splitHorizontal -> single preserves activePanel',
        () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'session-A'),
          PanelState(panelIndex: 1, sessionId: 'session-B'),
        ],
      ));
      getNotifier().setActivePanel(1);
      getNotifier().switchLayout(LayoutMode.single);
      final state = getState();
      expect(state.layoutMode, LayoutMode.single);
      expect(state.panels.length, 1);
      expect(state.panels[0].sessionId, 'session-B');
    });

    // A-N04
    test('switchLayout: grid2x2 -> single preserves activePanel', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.grid2x2,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
          PanelState(panelIndex: 2, sessionId: 'C'),
          PanelState(panelIndex: 3, sessionId: 'D'),
        ],
      ));
      getNotifier().setActivePanel(2);
      getNotifier().switchLayout(LayoutMode.single);
      expect(getState().panels[0].sessionId, 'C');
    });

    // A-N05
    test('switchLayout: grid2x2 -> splitHorizontal keeps first 2', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.grid2x2,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
          PanelState(panelIndex: 2, sessionId: 'C'),
          PanelState(panelIndex: 3, sessionId: 'D'),
        ],
      ));
      getNotifier().switchLayout(LayoutMode.splitHorizontal);
      final state = getState();
      expect(state.panels.length, 2);
      expect(state.panels[0].sessionId, 'A');
      expect(state.panels[1].sessionId, 'B');
    });

    // A-N06
    test('switchLayout: splitHorizontal -> grid2x2', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
        ],
      ));
      getNotifier().switchLayout(LayoutMode.grid2x2);
      final state = getState();
      expect(state.panels.length, 4);
      expect(state.panels[0].sessionId, 'A');
      expect(state.panels[1].sessionId, 'B');
      expect(state.panels[2].sessionId, isNull);
      expect(state.panels[3].sessionId, isNull);
    });

    // A-N07
    test('switchLayout: same mode is no-op', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [
          PanelState(panelIndex: 0),
          PanelState(panelIndex: 1),
        ],
      ));
      getNotifier().switchLayout(LayoutMode.splitHorizontal);
      expect(fakeStorage.saveCallCount, 0);
    });

    // A-N08
    test('switchLayout: splitVertical -> splitHorizontal preserves panels',
        () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitVertical,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
        ],
      ));
      getNotifier().switchLayout(LayoutMode.splitHorizontal);
      final state = getState();
      expect(state.layoutMode, LayoutMode.splitHorizontal);
      expect(state.panels[0].sessionId, 'A');
      expect(state.panels[1].sessionId, 'B');
    });

    // --- selectSession ---

    // A-N10
    test('selectSession assigns sessionId to panel', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [PanelState(panelIndex: 0), PanelState(panelIndex: 1)],
      ));
      getNotifier().selectSession(panelIndex: 0, sessionId: 'session-A');
      expect(getState().panels[0].sessionId, 'session-A');
      expect(getState().activePanelIndex, 0);
      expect(fakeStorage.saveCallCount, 1);
    });

    // A-N11
    test('selectSession updates activePanelIndex', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [PanelState(panelIndex: 0), PanelState(panelIndex: 1)],
        activePanelIndex: 0,
      ));
      getNotifier().selectSession(panelIndex: 1, sessionId: 'session-B');
      expect(getState().activePanelIndex, 1);
    });

    // A-N12
    test('selectSession overwrites existing sessionId', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'session-A'),
          PanelState(panelIndex: 1),
        ],
      ));
      getNotifier().selectSession(panelIndex: 0, sessionId: 'session-C');
      expect(getState().panels[0].sessionId, 'session-C');
    });

    // A-N13
    test('selectSession with out-of-range index is no-op', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [PanelState(panelIndex: 0), PanelState(panelIndex: 1)],
      ));
      getNotifier().selectSession(panelIndex: 5, sessionId: 'x');
      expect(fakeStorage.saveCallCount, 0);
    });

    // --- maximizePanel / restorePanel ---

    // A-N20
    test('maximizePanel sets maximizedPanelIndex', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [PanelState(panelIndex: 0), PanelState(panelIndex: 1)],
      ));
      getNotifier().maximizePanel(0);
      expect(getState().maximizedPanelIndex, 0);
      expect(getState().layoutMode, LayoutMode.splitHorizontal);
      expect(fakeStorage.saveCallCount, 0);
    });

    // A-N21
    test('restorePanel clears maximizedPanelIndex', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [PanelState(panelIndex: 0), PanelState(panelIndex: 1)],
        maximizedPanelIndex: 0,
      ));
      getNotifier().restorePanel();
      expect(getState().maximizedPanelIndex, isNull);
      expect(fakeStorage.saveCallCount, 0);
    });

    // A-N22
    test('maximizePanel with out-of-range index is no-op', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [PanelState(panelIndex: 0), PanelState(panelIndex: 1)],
      ));
      getNotifier().maximizePanel(5);
      expect(getState().maximizedPanelIndex, isNull);
    });

    // --- closePanel ---

    // A-N30
    test('closePanel: 2 panels -> single', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'session-A'),
          PanelState(panelIndex: 1, sessionId: 'session-B'),
        ],
      ));
      getNotifier().closePanel(1);
      final state = getState();
      expect(state.layoutMode, LayoutMode.single);
      expect(state.panels.length, 1);
      expect(state.panels[0].sessionId, 'session-A');
      expect(fakeStorage.saveCallCount, 1);
    });

    // A-N31
    test('closePanel: closing active panel resets to index 0', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
        ],
      ));
      getNotifier().setActivePanel(1);
      getNotifier().closePanel(1);
      expect(getState().activePanelIndex, 0);
    });

    // A-N32 (design decision: grid2x2 close 1 -> splitHorizontal keep first 2)
    test('closePanel: grid2x2 close 1 downgrades to splitHorizontal',
        () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.grid2x2,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
          PanelState(panelIndex: 2, sessionId: 'C'),
          PanelState(panelIndex: 3, sessionId: 'D'),
        ],
      ));
      getNotifier().closePanel(3);
      final state = getState();
      expect(state.layoutMode, LayoutMode.splitHorizontal);
      expect(state.panels.length, 2);
      expect(state.panels[0].sessionId, 'A');
      expect(state.panels[1].sessionId, 'B');
    });

    // A-N33
    test('closePanel: clears maximizedPanelIndex', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
        ],
        maximizedPanelIndex: 0,
      ));
      getNotifier().closePanel(1);
      expect(getState().maximizedPanelIndex, isNull);
    });

    // single mode close is no-op
    test('closePanel: single mode is no-op', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.single,
        panels: [PanelState(panelIndex: 0)],
      ));
      getNotifier().closePanel(0);
      expect(getState().panels.length, 1);
    });

    // A-N34
    test('closePanel: negative panelIndex is no-op', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
        ],
      ));
      getNotifier().closePanel(-1);
      expect(getState().panels.length, 2);
      expect(fakeStorage.saveCallCount, 0);
    });

    // A-N35
    test('closePanel: out-of-range panelIndex is no-op', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
        ],
      ));
      getNotifier().closePanel(5);
      expect(getState().panels.length, 2);
      expect(fakeStorage.saveCallCount, 0);
    });

    // A-N36
    test('closePanel: closing maximized panel clears maximizedPanelIndex',
        () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.grid2x2,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
          PanelState(panelIndex: 2, sessionId: 'C'),
          PanelState(panelIndex: 3, sessionId: 'D'),
        ],
      ));
      getNotifier().maximizePanel(1);
      expect(getState().maximizedPanelIndex, 1);
      getNotifier().closePanel(1);
      expect(getState().maximizedPanelIndex, isNull);
    });

    // A-N37
    test(
        'closePanel: closing panel before maximized decrements '
        'maximizedPanelIndex', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.grid2x2,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
          PanelState(panelIndex: 2, sessionId: 'C'),
          PanelState(panelIndex: 3, sessionId: 'D'),
        ],
      ));
      getNotifier().maximizePanel(2);
      expect(getState().maximizedPanelIndex, 2);
      getNotifier().closePanel(0);
      expect(getState().maximizedPanelIndex, 1);
    });

    test('closePanel: closing panel before active decrements activePanelIndex',
        () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.grid2x2,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
          PanelState(panelIndex: 2, sessionId: 'C'),
          PanelState(panelIndex: 3, sessionId: 'D'),
        ],
      ));
      getNotifier().setActivePanel(2);
      getNotifier().closePanel(0);
      expect(getState().activePanelIndex, 1);
    });

    test('closePanel: closing panel after active keeps activePanelIndex',
        () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.grid2x2,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
          PanelState(panelIndex: 2, sessionId: 'C'),
          PanelState(panelIndex: 3, sessionId: 'D'),
        ],
      ));
      getNotifier().setActivePanel(1);
      getNotifier().closePanel(3);
      expect(getState().activePanelIndex, 1);
    });

    test('closePanel: closing active panel itself resets to 0', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
        ],
      ));
      getNotifier().setActivePanel(1);
      getNotifier().closePanel(1);
      expect(getState().activePanelIndex, 0);
    });

    test('closePanel: 2 panels closing panel before active decrements index',
        () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [
          PanelState(panelIndex: 0, sessionId: 'A'),
          PanelState(panelIndex: 1, sessionId: 'B'),
        ],
      ));
      getNotifier().setActivePanel(1);
      getNotifier().closePanel(0);
      expect(getState().activePanelIndex, 0);
      expect(getState().panels.length, 1);
    });

    // --- setActivePanel ---

    // A-N40
    test('setActivePanel updates index', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [PanelState(panelIndex: 0), PanelState(panelIndex: 1)],
        activePanelIndex: 0,
      ));
      getNotifier().setActivePanel(1);
      expect(getState().activePanelIndex, 1);
      expect(fakeStorage.saveCallCount, 0);
    });

    // A-N41
    test('setActivePanel with out-of-range index is no-op', () async {
      await initWithState(const SplitViewState(
        layoutMode: LayoutMode.splitHorizontal,
        panels: [PanelState(panelIndex: 0), PanelState(panelIndex: 1)],
        activePanelIndex: 0,
      ));
      getNotifier().setActivePanel(5);
      expect(getState().activePanelIndex, 0);
    });
  });
}
