import 'dart:convert';

/// 需求：[0.2.1-W6-004] JSON 內容格式化輔助函式
/// 約束：嘗試解析 JSON，成功則 pretty-print，失敗則回傳原始字串
/// 維護：tool_result_bubble 使用此函式（output 為 String）
String formatJsonContent(String content) {
  try {
    final decoded = json.decode(content);
    final prettyJson = const JsonEncoder.withIndent('  ').convert(decoded);
    return _unescapeForDisplay(prettyJson);
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
    final prettyJson = const JsonEncoder.withIndent('  ').convert(object);
    return _unescapeForDisplay(prettyJson);
  } on FormatException {
    return value.toString();
  } on JsonUnsupportedObjectError {
    return value.toString();
  }
}

/// 需求：[0.2.1-W6-005] UI 顯示用跳脫字元還原
/// 約束：將 JSON 字串值中的跳脫序列還原為實際字元，提升可讀性
/// 維護：替換順序重要 — 先處理 \\\\ 再處理其他，避免雙重替換
String _unescapeForDisplay(String prettyJson) {
  return prettyJson
      .replaceAll('\\\\', '\x00')
      .replaceAll('\\"', '"')
      .replaceAll('\\n', '\n')
      .replaceAll('\\t', '\t')
      .replaceAll('\x00', '\\');
}
