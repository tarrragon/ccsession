import 'package:flutter/material.dart';

/// 需求：搜尋功能相關常數（Phase 1 4.4）
/// 約束：所有搜尋相關魔法數字和字串集中管理
abstract final class SearchConstants {
  /// 搜尋輸入 debounce 延遲（毫秒）
  static const int searchDebounceMilliseconds = 300;

  /// 搜尋欄位名稱常數
  static const String fieldText = 'text';
  static const String fieldOutput = 'output';
  static const String fieldToolName = 'toolName';

  /// 普通匹配高亮背景色
  static const Color highlightColor = Color.fromRGBO(255, 235, 59, 0.4);

  /// 當前聚焦匹配高亮背景色
  static const Color currentHighlightColor = Color.fromRGBO(255, 152, 0, 0.6);

  /// Session 列表篩選 hint 文字
  static const String sessionFilterHint = 'Filter sessions...';

  /// 對話搜尋 hint 文字
  static const String conversationSearchHint = 'Search...';

  // -- 搜尋列佈局常數 --

  /// 搜尋列水平內距
  static const double barHorizontalPadding = 8.0;

  /// 搜尋列垂直內距
  static const double barVerticalPadding = 4.0;

  /// 搜尋列內距
  static const EdgeInsets barPadding = EdgeInsets.symmetric(
    horizontal: barHorizontalPadding,
    vertical: barVerticalPadding,
  );

  /// 搜尋輸入框內容內距
  static const EdgeInsets inputContentPadding = EdgeInsets.symmetric(
    horizontal: 8.0,
    vertical: 8.0,
  );

  /// 搜尋列按鈕圖示大小
  static const double buttonIconSize = 20.0;

  /// 搜尋列按鈕最小觸控區域
  static const double buttonMinSize = 32.0;

  /// 搜尋列按鈕約束
  static const BoxConstraints buttonConstraints = BoxConstraints(
    minWidth: buttonMinSize,
    minHeight: buttonMinSize,
  );

  /// 匹配計數顯示水平間距
  static const double matchCountHorizontalPadding = 8.0;
}
