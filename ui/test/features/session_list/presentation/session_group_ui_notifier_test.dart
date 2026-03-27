import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/session_group_ui_notifier.dart';
import 'package:ccsession/features/session_list/presentation/session_group_ui_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-20: SessionGroupUiNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    SessionGroupUiState readState() {
      return container.read(sessionGroupUiNotifierProvider);
    }

    SessionGroupUiNotifier readNotifier() {
      return container.read(sessionGroupUiNotifierProvider.notifier);
    }

    // TC-20-01: 初始狀態 — 預設值
    test('initial state has correct defaults', () {
      final state = readState();

      expect(state, isNotNull);
      expect(state.currentPages, {
        SessionStatus.active: 0,
        SessionStatus.idle: 0,
        SessionStatus.completed: 0,
      });
      expect(state.expandedGroups, {
        SessionStatus.active: true,
        SessionStatus.idle: true,
        SessionStatus.completed: false,
      });
    });

    // TC-20-02: setPage — 正常設定頁碼
    test('setPage updates page for specified status only', () {
      expect(readState().currentPages[SessionStatus.active], 0);

      readNotifier().setPage(SessionStatus.active, 1);

      expect(readState().currentPages[SessionStatus.active], 1);
      expect(readState().currentPages[SessionStatus.idle], 0);
      expect(readState().currentPages[SessionStatus.completed], 0);
    });

    // TC-20-03: setPage — 負數頁碼 clamp 到 0
    test('setPage clamps negative page index to 0', () {
      readNotifier().setPage(SessionStatus.active, -1);

      expect(readState().currentPages[SessionStatus.active], 0);
    });

    // TC-20-04: toggleExpanded — 展開變摺疊
    test('toggleExpanded collapses an expanded group', () {
      expect(readState().expandedGroups[SessionStatus.active], true);

      readNotifier().toggleExpanded(SessionStatus.active);

      expect(readState().expandedGroups[SessionStatus.active], false);
    });

    // TC-20-05: toggleExpanded — 摺疊變展開
    test('toggleExpanded expands a collapsed group', () {
      expect(readState().expandedGroups[SessionStatus.completed], false);

      readNotifier().toggleExpanded(SessionStatus.completed);

      expect(readState().expandedGroups[SessionStatus.completed], true);
    });

    // TC-20-06: toggleExpanded — 不影響其他分組
    test('toggleExpanded does not affect other groups', () {
      readNotifier().toggleExpanded(SessionStatus.active);

      expect(readState().expandedGroups[SessionStatus.active], false);
      expect(readState().expandedGroups[SessionStatus.completed], false);
      expect(readState().expandedGroups[SessionStatus.idle], true);
    });

    // TC-20-07: resetAllPages — 所有頁碼歸零
    test('resetAllPages resets all pages to 0', () {
      readNotifier().setPage(SessionStatus.active, 2);
      readNotifier().setPage(SessionStatus.idle, 1);
      expect(readState().currentPages[SessionStatus.active], 2);

      readNotifier().resetAllPages();

      expect(readState().currentPages[SessionStatus.active], 0);
      expect(readState().currentPages[SessionStatus.idle], 0);
      expect(readState().currentPages[SessionStatus.completed], 0);
      // expandedGroups not affected
      expect(readState().expandedGroups[SessionStatus.completed], false);
    });

    // TC-20-08: setPage — 不影響展開/摺疊狀態
    test('setPage does not affect expanded groups', () {
      readNotifier().setPage(SessionStatus.completed, 1);

      expect(readState().currentPages[SessionStatus.completed], 1);
      expect(readState().expandedGroups[SessionStatus.completed], false);
    });
  });
}
