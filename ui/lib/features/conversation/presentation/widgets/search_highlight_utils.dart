import 'package:ccsession/core/constants/search_constants.dart';
import 'package:flutter/material.dart';

/// 需求：高亮範圍定義（Phase 1 5.2）
/// 約束：start/end 為文字偏移量，isCurrent 標記當前聚焦匹配
typedef HighlightRange = ({int start, int end, bool isCurrent, String field});

/// 需求：依欄位名稱過濾高亮範圍（0.2.0-W2-011）
/// 約束：避免將不同欄位的 offset 套用到錯誤的文字上，防止 RangeError
List<HighlightRange>? filterRangesByField(
  List<HighlightRange>? ranges,
  String field,
) {
  if (ranges == null || ranges.isEmpty) return null;
  final filtered = ranges.where((r) => r.field == field).toList();
  return filtered.isEmpty ? null : filtered;
}

/// 需求：將純文字 + 高亮範圍轉換為 TextSpan 列表（Phase 1 5.2）
/// 約束：non-overlapping ranges，按 start 排序
List<TextSpan> buildHighlightedSpans(
  String text,
  List<HighlightRange> ranges,
  TextStyle baseStyle,
) {
  if (ranges.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  final sortedRanges = List<HighlightRange>.of(ranges)
    ..sort((a, b) => a.start.compareTo(b.start));

  final spans = <TextSpan>[];
  var cursor = 0;

  for (final range in sortedRanges) {
    if (cursor < range.start) {
      spans.add(TextSpan(text: text.substring(cursor, range.start), style: baseStyle));
    }
    final highlightColor = range.isCurrent
        ? SearchConstants.currentHighlightColor
        : SearchConstants.highlightColor;
    spans.add(
      TextSpan(
        text: text.substring(range.start, range.end),
        style: baseStyle.copyWith(backgroundColor: highlightColor),
      ),
    );
    cursor = range.end;
  }

  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }

  return spans;
}
