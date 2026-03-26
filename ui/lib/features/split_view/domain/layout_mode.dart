/// 需求：UC-004 佈局模式，4 種分割方式
/// 約束：每個模式對應固定面板數量
enum LayoutMode {
  /// 單一面板，佔滿主區域
  single,

  /// 左右並列 2 面板
  splitHorizontal,

  /// 上下並列 2 面板
  splitVertical,

  /// 2x2 四格網格
  grid2x2,
}

/// 需求：UC-004 取得佈局模式對應的面板數量
/// 約束：single=1, splitHorizontal/splitVertical=2, grid2x2=4
extension LayoutModePanelCount on LayoutMode {
  int get panelCount {
    switch (this) {
      case LayoutMode.single:
        return 1;
      case LayoutMode.splitHorizontal:
      case LayoutMode.splitVertical:
        return 2;
      case LayoutMode.grid2x2:
        return 4;
    }
  }
}
