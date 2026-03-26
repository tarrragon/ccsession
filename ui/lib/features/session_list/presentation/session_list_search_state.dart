import 'package:equatable/equatable.dart';

/// 需求：[0.2.0-W4-003] Session 列表篩選的 UI 狀態
/// 約束：不可變（Equatable），僅包含搜尋可見性和查詢字串
class SessionListSearchState extends Equatable {
  const SessionListSearchState({
    this.isSearchVisible = false,
    this.query = '',
  });

  /// 搜尋列是否可見
  final bool isSearchVisible;

  /// 當前篩選字串
  final String query;

  /// 需求：是否有有效篩選條件（非空 query）
  bool get hasActiveFilter => query.isNotEmpty;

  SessionListSearchState copyWith({
    bool? isSearchVisible,
    String? query,
  }) {
    return SessionListSearchState(
      isSearchVisible: isSearchVisible ?? this.isSearchVisible,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [isSearchVisible, query];
}
