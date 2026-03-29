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
/// 約束：toolInput 為 Object?，可能是 Map/List（已解析）或 String（未解析 JSON 字串）
/// 維護：tool_use_bubble 使用此函式（toolInput 為 Object?）
String formatJsonObject(Object? value) {
  if (value == null) return '';
  try {
    final object = value is String ? json.decode(value) : value;
    return const JsonEncoder.withIndent('  ').convert(object);
  } on FormatException {
    return value.toString();
  } on JsonUnsupportedObjectError {
    return value.toString();
  }
}
