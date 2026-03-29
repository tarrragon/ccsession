import 'dart:convert';

/// 需求：[0.2.1-W6-004] JSON 內容格式化輔助函式
/// 約束：嘗試解析 JSON，成功則 pretty-print，失敗則回傳原始字串
/// 維護：tool_result_bubble 使用此函式（output 為 String）
String formatJsonContent(String content) {
  try {
    final decoded = json.decode(content);
    return const JsonEncoder.withIndent('  ').convert(decoded);
  } on FormatException {
    return content;
  }
}

/// 需求：[0.2.1-W6-004] 已解析 JSON 物件格式化
/// 約束：toolInput 是 Object?（通常為 Map），直接 convert 避免 toString() 產生非法 JSON
/// 維護：tool_use_bubble 使用此函式（toolInput 為 Object?）
String formatJsonObject(Object? value) {
  if (value == null) return '';
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } on JsonUnsupportedObjectError {
    return value.toString();
  }
}
