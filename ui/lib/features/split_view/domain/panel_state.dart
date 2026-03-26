import 'package:equatable/equatable.dart';

/// 需求：UC-004 單一面板的狀態
/// 約束：不可變（Equatable），panelIndex 為位置索引，sessionId 為綁定的 session
class PanelState extends Equatable {
  const PanelState({
    required this.panelIndex,
    this.sessionId,
  });

  /// 面板位置索引（0-based，對應 LayoutMode 的位置）
  final int panelIndex;

  /// 綁定的 session ID，null 表示空面板
  final String? sessionId;

  @override
  List<Object?> get props => [panelIndex, sessionId];
}
