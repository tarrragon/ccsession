import 'package:flutter/material.dart';

/// 需求：Dashboard 相關尺寸和樣式常數
abstract final class DashboardConstants {
  /// Sidebar 固定寬度（邏輯像素）
  static const double sidebarWidth = 280.0;

  /// ConnectionStatusBar 圓點尺寸
  static const double connectionDotSize = 10.0;

  /// ConnectionStatusBar 內距
  static const EdgeInsets connectionBarPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  /// Sidebar 和 main area 之間的 divider 寬度
  static const double dividerWidth = 1.0;

  /// ConnectionStatusBar 中圓點和文字之間的間距
  static const double connectionDotTextSpacing = 8.0;
}
