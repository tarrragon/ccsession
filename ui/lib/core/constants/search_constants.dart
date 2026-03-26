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
}
