import 'package:flutter/material.dart';

/// 需求：UC-004 SplitView 面板佈局相關常數
/// 約束：所有數值集中管理，禁止硬編碼
abstract final class SplitViewConstants {
  // -- Flex 比例 --

  /// 面板 flex 預設值（等分）
  static const double defaultFlex = 100.0;

  /// 面板 flex 最小值（防止面板被拖到消失）
  static const double minFlex = 20.0;

  /// 面板 flex 最大值（防止單一面板佔滿）
  static const double maxFlex = 280.0;

  // -- ResizableDivider --

  /// 分隔線粗細（像素）
  static const double dividerThickness = 8.0;

  // -- PanelHeader --

  /// 標題列水平內距
  static const double headerHorizontalPadding = 8.0;

  /// 標題列垂直內距
  static const double headerVerticalPadding = 4.0;

  /// 標題列內距
  static const EdgeInsets headerPadding = EdgeInsets.symmetric(
    horizontal: headerHorizontalPadding,
    vertical: headerVerticalPadding,
  );

  /// 操作按鈕圖示大小
  static const double headerIconSize = 18.0;

  /// 操作按鈕最小觸控區域
  static const double headerButtonMinSize = 28.0;

  /// 操作按鈕約束
  static const BoxConstraints headerButtonConstraints = BoxConstraints(
    minWidth: headerButtonMinSize,
    minHeight: headerButtonMinSize,
  );
}
