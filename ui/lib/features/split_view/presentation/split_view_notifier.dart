import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:ccsession/features/split_view/data/split_view_storage.dart';
import 'package:ccsession/features/split_view/domain/layout_mode.dart';
import 'package:ccsession/features/split_view/domain/panel_state.dart';
import 'package:ccsession/features/split_view/domain/split_view_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'split_view_notifier.g.dart';

/// 需求：UC-004 管理分割畫面狀態
/// 約束：@riverpod code generation，從 SplitViewStorage 讀取/寫入持久化狀態
@riverpod
class SplitViewNotifier extends _$SplitViewNotifier {
  SplitViewStorage get _storage => ref.read(splitViewStorageProvider);

  /// 需求：UC-004 初始建構，從持久化讀取狀態
  /// 約束：讀取失敗時 fallback 為 single 模式（場景 13、14）
  @override
  Future<SplitViewState> build() async {
    final loaded = await _storage.load();
    if (loaded == null) {
      return _defaultState();
    }
    return _reconcilePanels(loaded);
  }

  /// 需求：UC-004 切換佈局模式（場景 1-3）
  /// 約束：保留可延續面板 sessionId，切換後立即持久化
  void switchLayout(LayoutMode mode) {
    debugPrint('[SplitView] switchLayout: $mode');
    final current = state.valueOrNull;
    if (current == null || current.layoutMode == mode) return;

    final newPanels = _buildPanelsForSwitch(current, mode);
    final newActiveIndex = min(current.activePanelIndex, newPanels.length - 1);

    final newState = SplitViewState(
      layoutMode: mode,
      panels: newPanels,
      activePanelIndex: newActiveIndex,
    );
    state = AsyncData(newState);
    _storage.save(newState);
  }

  /// 需求：UC-004 為指定面板選擇 session（場景 4）
  /// 約束：同時設定 activePanelIndex，選擇後立即持久化
  void selectSession({required int panelIndex, required String sessionId}) {
    debugPrint('[SplitView] selectSession: panel=$panelIndex, sessionId=$sessionId');
    final current = _validStateForPanel(panelIndex);
    if (current == null) return;

    final newPanels = [
      for (var i = 0; i < current.panels.length; i++)
        if (i == panelIndex)
          PanelState(panelIndex: i, sessionId: sessionId)
        else
          current.panels[i],
    ];

    final newState = current.copyWith(
      panels: newPanels,
      activePanelIndex: panelIndex,
    );
    state = AsyncData(newState);
    _storage.save(newState);
  }

  /// 需求：UC-004 最大化指定面板（場景 7）
  /// 約束：不持久化
  void maximizePanel(int panelIndex) {
    final current = _validStateForPanel(panelIndex);
    if (current == null) return;

    state = AsyncData(current.copyWith(maximizedPanelIndex: panelIndex));
  }

  /// 需求：UC-004 還原最大化面板（場景 8）
  /// 約束：不持久化
  void restorePanel() {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(maximizedPanelIndex: null));
  }

  /// 需求：UC-004 關閉指定面板（場景 9）
  /// 約束：剩餘 1 面板自動降級 single，grid2x2 關閉降級 splitHorizontal 保留前 2
  void closePanel(int panelIndex) {
    final current = state.valueOrNull;
    if (current == null || current.panels.length <= 1) return;
    if (panelIndex < 0 || panelIndex >= current.panels.length) return;

    final remaining = _adjustPanelsAfterClose(current.panels, panelIndex);
    final newMode = _determineLayoutAfterClose(remaining.length);
    final newPanels = _reindexPanels(remaining);
    final newActiveIndex = _adjustActiveIndexAfterClose(
      current.activePanelIndex,
      panelIndex,
      newPanels.length,
    );

    final newMaximizedIndex = _adjustMaximizedIndexAfterClose(
      current.maximizedPanelIndex,
      panelIndex,
    );

    final newState = SplitViewState(
      layoutMode: newMode,
      panels: newPanels,
      activePanelIndex: newActiveIndex,
      maximizedPanelIndex: newMaximizedIndex,
    );
    state = AsyncData(newState);
    _storage.save(newState);
  }

  /// 需求：UC-004 關閉面板後調整 activePanelIndex
  /// 約束：關閉 active 本身歸零，關閉前方面板遞減，關閉後方面板不變
  int _adjustActiveIndexAfterClose(int activeIndex, int closedIndex, int newLength) {
    if (closedIndex == activeIndex) return 0;
    final adjusted = closedIndex < activeIndex ? activeIndex - 1 : activeIndex;
    return min(adjusted, newLength - 1);
  }

  /// 需求：UC-004 關閉面板後調整 maximizedPanelIndex
  /// 約束：關閉最大化面板則清除，關閉前方面板則遞減
  int? _adjustMaximizedIndexAfterClose(int? maximizedIndex, int closedIndex) {
    if (maximizedIndex == null) return null;
    if (maximizedIndex == closedIndex) return null;
    if (maximizedIndex > closedIndex) return maximizedIndex - 1;
    return maximizedIndex;
  }

  /// 需求：UC-004 關閉面板後決定新佈局模式
  LayoutMode _determineLayoutAfterClose(int remainingCount) {
    return remainingCount <= 1 ? LayoutMode.single : LayoutMode.splitHorizontal;
  }

  /// 需求：UC-004 關閉面板後調整面板列表
  /// 約束：剩 3 面板時取前 2 個（grid2x2 降級場景 9）
  List<PanelState> _adjustPanelsAfterClose(
    List<PanelState> panels,
    int closedIndex,
  ) {
    final remaining = panels.where((p) => p.panelIndex != closedIndex).toList();
    return remaining.length > 2 ? remaining.take(2).toList() : remaining;
  }

  /// 需求：UC-004 設定焦點面板
  /// 約束：不持久化
  void setActivePanel(int panelIndex) {
    final current = _validStateForPanel(panelIndex);
    if (current == null) return;

    state = AsyncData(current.copyWith(activePanelIndex: panelIndex));
  }

  /// 需求：UC-004 驗證 state 已載入且 panelIndex 有效
  /// 約束：回傳 null 表示無效，呼叫端應提前返回
  SplitViewState? _validStateForPanel(int panelIndex) {
    final current = state.valueOrNull;
    if (current == null || panelIndex < 0 || panelIndex >= current.panels.length) {
      return null;
    }
    return current;
  }

  // -- Private helpers --

  SplitViewState _defaultState() {
    return const SplitViewState(
      layoutMode: LayoutMode.single,
      panels: [PanelState(panelIndex: 0)],
    );
  }

  /// 需求：UC-004 驗證面板數與 layoutMode 一致性（場景 15）
  SplitViewState _reconcilePanels(SplitViewState loaded) {
    final expectedCount = loaded.layoutMode.panelCount;
    var panels = loaded.panels.toList();

    if (panels.length < expectedCount) {
      for (var i = panels.length; i < expectedCount; i++) {
        panels.add(PanelState(panelIndex: i));
      }
    } else if (panels.length > expectedCount) {
      panels = panels.take(expectedCount).toList();
    }

    return SplitViewState(
      layoutMode: loaded.layoutMode,
      panels: _reindexPanels(panels),
      activePanelIndex: 0,
    );
  }

  List<PanelState> _buildPanelsForSwitch(
    SplitViewState current,
    LayoutMode newMode,
  ) {
    final newCount = newMode.panelCount;

    if (newCount == 1) {
      final activeSession =
          current.panels[current.activePanelIndex].sessionId;
      return [PanelState(panelIndex: 0, sessionId: activeSession)];
    }

    final result = <PanelState>[];
    for (var i = 0; i < newCount; i++) {
      if (i < current.panels.length) {
        result.add(PanelState(
          panelIndex: i,
          sessionId: current.panels[i].sessionId,
        ));
      } else {
        result.add(PanelState(panelIndex: i));
      }
    }
    return result;
  }

  List<PanelState> _reindexPanels(List<PanelState> panels) {
    return [
      for (var i = 0; i < panels.length; i++)
        PanelState(panelIndex: i, sessionId: panels[i].sessionId),
    ];
  }
}
