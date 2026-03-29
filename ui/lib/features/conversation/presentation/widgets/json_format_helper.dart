import 'dart:convert';

/// 需求：[0.2.1-W6-004] JSON 內容格式化輔助函式
/// 約束：嘗試解析 JSON，成功則 pretty-print，失敗則回傳原始字串
/// 維護：tool_use_bubble 和 tool_result_bubble 共用此函式
String formatJsonContent(String content) {
  try {
    final decoded = json.decode(content);
    return const JsonEncoder.withIndent('  ').convert(decoded);
  } on FormatException {
    return content;
  }
}
