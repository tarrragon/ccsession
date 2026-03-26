import 'package:ccsession/features/split_view/domain/layout_mode.dart';
import 'package:ccsession/features/split_view/domain/panel_state.dart';
import 'package:equatable/equatable.dart';

/// Sentinel 值，用於 copyWith 中區分「未傳入」和「明確傳入 null」
const _sentinel = Object();

/// 需求：UC-004 分割畫面的完整 UI 狀態
/// 約束：不可變（Equatable），panels 長度由 layoutMode 決定
class SplitViewState extends Equatable {
  const SplitViewState({
    this.layoutMode = LayoutMode.single,
    this.panels = const [],
    this.activePanelIndex = 0,
    this.maximizedPanelIndex,
  });

  /// 當前佈局模式
  final LayoutMode layoutMode;

  /// 各面板狀態（長度由 layoutMode 決定）
  final List<PanelState> panels;

  /// 當前焦點面板索引（用於 sidebar 點擊時確定目標面板）
  final int activePanelIndex;

  /// 最大化的面板索引，null 表示無面板最大化
  final int? maximizedPanelIndex;

  /// 需求：UC-004 copyWith 支援 nullable 欄位
  /// 約束：maximizedPanelIndex 需 sentinel 區分「未傳入」和「明確傳 null」
  SplitViewState copyWith({
    LayoutMode? layoutMode,
    List<PanelState>? panels,
    int? activePanelIndex,
    Object? maximizedPanelIndex = _sentinel,
  }) {
    return SplitViewState(
      layoutMode: layoutMode ?? this.layoutMode,
      panels: panels ?? this.panels,
      activePanelIndex: activePanelIndex ?? this.activePanelIndex,
      maximizedPanelIndex: maximizedPanelIndex == _sentinel
          ? this.maximizedPanelIndex
          : maximizedPanelIndex as int?,
    );
  }

  @override
  List<Object?> get props => [
        layoutMode,
        panels,
        activePanelIndex,
        maximizedPanelIndex,
      ];
}
