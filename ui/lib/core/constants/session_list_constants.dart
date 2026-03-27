import 'package:ccsession/core/models/session_info.dart';
import 'package:flutter/material.dart';

/// 需求：Session List Sidebar 相關常數
/// 約束：所有數值和字串集中管理，禁止硬編碼
abstract final class SessionListConstants {
  /// 分組標題內距
  static const groupHeaderPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);


  /// 摘要 fallback 截取長度上限
  static const summaryFallbackMaxLength = 50;

  /// session ID fallback 截取長度
  static const sessionIdFallbackLength = 8;

  /// Agent session 標題前綴
  static const agentTitlePrefix = '[Agent]';

  /// 每頁最多顯示的 session 數量
  static const maxItemsPerPage = 10;

  /// 分組標題展開/摺疊圖示尺寸（邏輯像素）
  static const groupHeaderIconSize = 20.0;

  /// 分組標題圖示與文字間距（邏輯像素）
  static const groupHeaderIconSpacing = 4.0;

  /// 狀態指示燈尺寸（直徑，邏輯像素）
  static const statusIndicatorSize = 10.0;

  /// 需求：SessionStatus -> 指示燈顏色對應
  /// 約束：與 spec 4.1 一致
  static Color statusColor(SessionStatus status) {
    return switch (status) {
      SessionStatus.active => Colors.green,
      SessionStatus.idle => Colors.amber,
      SessionStatus.completed => Colors.grey,
    };
  }

  /// 需求：SessionStatus -> 顯示名稱
  /// 維護：待 l10n 系統建立後遷移至 ARB
  static String statusDisplayName(SessionStatus status) {
    return switch (status) {
      SessionStatus.active => 'Active',
      SessionStatus.idle => 'Idle',
      SessionStatus.completed => 'Completed',
    };
  }
}
