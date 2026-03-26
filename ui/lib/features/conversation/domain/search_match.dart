import 'package:equatable/equatable.dart';

/// 需求：單一搜尋匹配項值物件（Phase 1 3.1）
/// 約束：不可變，支援相等比較，eventIndex 對應 ConversationState.events 索引
class SearchMatch extends Equatable {
  const SearchMatch({
    required this.eventIndex,
    required this.startOffset,
    required this.endOffset,
    required this.field,
  });

  /// 在 ConversationState.events 中的索引
  final int eventIndex;

  /// 匹配文字在該欄位中的起始偏移量
  final int startOffset;

  /// 匹配文字在該欄位中的結束偏移量
  final int endOffset;

  /// 匹配發生的欄位名稱（"text", "output", "toolName"）
  final String field;

  @override
  List<Object?> get props => [eventIndex, startOffset, endOffset, field];
}
