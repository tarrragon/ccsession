import 'package:ccsession/core/constants/search_constants.dart';
import 'package:ccsession/core/models/session_event.dart';

/// 需求：從 SessionEvent 提取可搜尋文字（Phase 1 4.3）
/// 約束：根據 event.type 決定搜尋哪些欄位，空欄位跳過
List<({String field, String text})> extractSearchableText(
  SessionEvent event,
) {
  return switch (event.type) {
    'user' || 'assistant' => _extractTextField(event),
    'thinking' => _extractThinkingField(event),
    'tool_use' => _extractToolUseFields(event),
    'tool_result' => _extractToolResultFields(event),
    _ => const [],
  };
}

List<({String field, String text})> _extractTextField(SessionEvent event) {
  return [(field: SearchConstants.fieldText, text: event.content.text)];
}

List<({String field, String text})> _extractThinkingField(SessionEvent event) {
  if (event.content.text.isEmpty) return const [];
  return [(field: SearchConstants.fieldText, text: event.content.text)];
}

List<({String field, String text})> _extractToolUseFields(SessionEvent event) {
  final results = <({String field, String text})>[];
  results.add(
    (field: SearchConstants.fieldToolName, text: event.content.toolName),
  );
  if (event.content.text.isNotEmpty) {
    results.add((field: SearchConstants.fieldText, text: event.content.text));
  }
  return results;
}

List<({String field, String text})> _extractToolResultFields(
  SessionEvent event,
) {
  final results = <({String field, String text})>[];
  if (event.content.output.isNotEmpty) {
    results.add(
      (field: SearchConstants.fieldOutput, text: event.content.output),
    );
  }
  if (event.content.text.isNotEmpty) {
    results.add((field: SearchConstants.fieldText, text: event.content.text));
  }
  return results;
}

/// 需求：在文字中找出所有匹配位置（Phase 1 4.3）
/// 約束：case-insensitive 子字串匹配，非重疊，query 為空回傳空列表
List<({int start, int end})> findAllMatches(String text, String query) {
  if (query.isEmpty) return const [];

  final results = <({int start, int end})>[];
  final lowerText = text.toLowerCase();
  final lowerQuery = query.toLowerCase();
  var searchFrom = 0;

  while (true) {
    final index = lowerText.indexOf(lowerQuery, searchFrom);
    if (index == -1) break;
    results.add((start: index, end: index + query.length));
    searchFrom = index + query.length;
  }

  return results;
}
