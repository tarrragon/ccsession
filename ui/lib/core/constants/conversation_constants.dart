import 'package:flutter/material.dart';

/// 需求：Conversation View 相關常數
/// 約束：所有數值和字串集中管理，禁止硬編碼
abstract final class ConversationConstants {
  /// 需求：工具結果錯誤時的邊框和文字顏色
  /// 來源：Phase 4c 常數化（0.2.0-W2-010）
  static const errorColor = Colors.red;

  /// 需求：等寬字型樣式，用於工具名稱、程式碼輸出等技術內容
  /// 來源：Bubble 魔法數字常數化（0.2.0-W3-027）
  static const monospaceStyle = TextStyle(fontFamily: 'monospace');

  /// 需求：Bubble 元件外層間距，確保各 Bubble 間有一致的視覺間隔
  /// 來源：Bubble 魔法數字常數化（0.2.0-W3-027）
  static const bubbleMargin = EdgeInsets.symmetric(vertical: 4, horizontal: 8);

  /// 需求：Bubble 內容區域內距，確保文字與邊框間有一致的留白
  /// 來源：Bubble 魔法數字常數化（0.2.0-W3-027）
  static const bubbleContentPadding = EdgeInsets.all(12);
}
