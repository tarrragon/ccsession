import 'dart:convert';

/// 需求：[0.2.1-W6-004] JSON 內容格式化輔助函式
/// 約束：嘗試解析 JSON，成功則 pretty-print，失敗則回傳原始字串
/// 維護：tool_result_bubble 使用此函式（output 為 String）
String formatJsonContent(String content) {
  try {
    final decoded = json.decode(content);
    final prettyJson = const JsonEncoder.withIndent('  ').convert(decoded);
    return unescapeForDisplay(prettyJson);
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
    return unescapeForDisplay(prettyJson);
  } on FormatException {
    return value.toString();
  } on JsonUnsupportedObjectError {
    return value.toString();
  }
}

/// 需求：[0.2.1-W6-005] UI 顯示用跳脫字元還原
/// 約束：將 JSON 字串值中的跳脫序列還原為實際字元，提升可讀性
/// 維護：替換順序重要 — 先處理 \\\\ 再處理其他，避免雙重替換
String unescapeForDisplay(String text) {
  return text
      .replaceAll('\\\\', '\x00')
      .replaceAll('\\"', '"')
      .replaceAll('\\n', '\n')
      .replaceAll('\\t', '\t')
      .replaceAll('\x00', '\\');
}

/// 需求：[0.2.1-W7-001] 將 JSON 物件轉換為 key-value 排版格式
/// 約束：Map → 逐 key 格式化；非 Map → fallback 為 formatJsonObject
/// 維護：tool_use_bubble 使用此函式取代 formatJsonObject
String formatKeyValue(Object? value) {
  if (value == null) return '';

  final object = _decodeToObject(value);
  if (object == null) return formatJsonObject(value);

  if (object is! Map) return formatJsonObject(value);
  if (object.isEmpty) return '';

  return _formatMapEntries(object);
}

/// 需求：[0.2.1-W7-001] 將輸入解碼為物件
/// 約束：String 嘗試 JSON 解碼，其他型別直接回傳
Object? _decodeToObject(Object value) {
  if (value is! String) return value;
  try {
    return json.decode(value);
  } on FormatException {
    return null;
  }
}

/// 需求：[0.2.1-W7-001] 逐 key 格式化 Map 項目
/// 約束：null 值顯示 (empty)，Map/List 顯示 compact JSON，其他經 unescape 處理
String _formatMapEntries(Map<dynamic, dynamic> map) {
  final lines = <String>[];
  for (final entry in map.entries) {
    lines.add(_formatSingleEntry(entry.key, entry.value));
  }
  return lines.join('\n');
}

/// 需求：[0.2.1-W7-001] 格式化單一 key-value 項目
String _formatSingleEntry(dynamic key, dynamic val) {
  if (val == null) return '$key: (empty)';
  if (val is Map || val is List) {
    return '$key: ${json.encode(val)}';
  }
  final display = unescapeForDisplay(val.toString());
  if (display.isEmpty) return '$key:';
  return '$key: $display';
}
