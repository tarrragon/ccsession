import 'package:ccsession/features/conversation/domain/search_match.dart';
import 'package:equatable/equatable.dart';

/// 需求：搜尋功能的完整 UI 狀態（Phase 1 3.2）
/// 約束：不可變（Equatable），包含搜尋可見性、查詢字串、匹配結果、當前索引
class ConversationSearchState extends Equatable {
  const ConversationSearchState({
    this.isSearchVisible = false,
    this.query = '',
    this.matches = const [],
    this.currentMatchIndex = -1,
  });

  /// 搜尋列是否可見
  final bool isSearchVisible;

  /// 當前搜尋字串
  final String query;

  /// 所有匹配結果（按 event 順序 + 位置順序）
  final List<SearchMatch> matches;

  /// 當前聚焦的匹配項索引（-1 表示無聚焦）
  final int currentMatchIndex;

  /// 需求：是否有匹配結果
  bool get hasMatches => matches.isNotEmpty;

  /// 需求：顯示用計數文字（Phase 1 3.2）
  /// 約束：空 query 回傳空字串，無匹配回傳 "0/0"，有匹配回傳 "N/M"
  String get matchCountDisplay {
    if (query.isEmpty) return '';
    if (matches.isEmpty) return '0/0';
    return '${currentMatchIndex + 1}/${matches.length}';
  }

  /// 需求：當前聚焦的匹配項
  /// 約束：索引無效時回傳 null
  SearchMatch? get currentMatch {
    if (currentMatchIndex < 0 || currentMatchIndex >= matches.length) {
      return null;
    }
    return matches[currentMatchIndex];
  }

  ConversationSearchState copyWith({
    bool? isSearchVisible,
    String? query,
    List<SearchMatch>? matches,
    int? currentMatchIndex,
  }) {
    return ConversationSearchState(
      isSearchVisible: isSearchVisible ?? this.isSearchVisible,
      query: query ?? this.query,
      matches: matches ?? this.matches,
      currentMatchIndex: currentMatchIndex ?? this.currentMatchIndex,
    );
  }

  @override
  List<Object?> get props => [isSearchVisible, query, matches, currentMatchIndex];
}
