import 'dart:async';

import 'package:ccsession/core/constants/search_constants.dart';
import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/session_group_utils.dart';
import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:ccsession/features/session_list/presentation/session_list_search_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_list_search_notifier.g.dart';

/// 需求：[0.2.0-W4-003] 管理 session 列表篩選狀態
/// 約束：監聽 sessionListNotifierProvider，sessions 變化時自動重新篩選
/// 維護：debounce 延遲 state 更新，TextField 由 controller 管理輸入顯示
/// 維護：_currentSearch 用於跨 build() 重建保留篩選狀態
@riverpod
class SessionListSearchNotifier extends _$SessionListSearchNotifier {
  Timer? _debounceTimer;

  /// 需求：跨 build() 保留篩選狀態
  /// 約束：Riverpod build() 重建時 state 會被覆寫，需額外保留
  SessionListSearchState _currentSearch = const SessionListSearchState();

  @override
  SessionListSearchState build() {
    ref.watch(sessionListNotifierProvider);

    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return _currentSearch;
  }

  /// 需求：開啟搜尋列
  void openSearch() {
    _currentSearch = _currentSearch.copyWith(isSearchVisible: true);
    state = _currentSearch;
  }

  /// 需求：關閉搜尋列並清除所有篩選狀態
  void closeSearch() {
    _debounceTimer?.cancel();
    _currentSearch = const SessionListSearchState();
    state = _currentSearch;
  }

  /// 需求：更新篩選字串（由 TextField.onChanged 呼叫）
  /// 約束：debounce 延遲 state 更新，避免頻繁重算 filteredGroupedSessions
  void updateQuery(String query) {
    _debounceTimer?.cancel();
    _currentSearch = _currentSearch.copyWith(query: query);

    _debounceTimer = Timer(
      const Duration(milliseconds: SearchConstants.searchDebounceMilliseconds),
      () {
        state = _currentSearch;
      },
    );
  }

  /// 需求：取得篩選後的分組 session 列表
  /// 約束：空 query（trim 後）回傳完整列表；非空則對四個欄位做 case-insensitive contains
  /// 約束：分組順序固定 active/idle/completed，每組內按 lastEventAt 降序
  /// 約束：若指定 projectPath，先按 projectPath 過濾
  Map<SessionStatus, List<SessionInfo>> filteredGroupedSessions({
    String? projectPath,
  }) {
    final sessionListState =
        ref.read(sessionListNotifierProvider).valueOrNull;
    if (sessionListState == null) return {};

    var sessions = sessionListState.sessions;

    if (projectPath != null) {
      sessions = sessions
          .where((s) => s.projectPath == projectPath)
          .toList();
    }

    final trimmedQuery = state.query.trim();

    if (trimmedQuery.isEmpty) {
      return groupSessionsByStatus(sessions);
    }

    final normalizedQuery = trimmedQuery.toLowerCase();
    final filtered = sessions.where(
      (session) => _matchesQuery(session, normalizedQuery),
    ).toList();

    return groupSessionsByStatus(filtered);
  }

  /// 需求：檢查 session 是否匹配查詢字串（任一欄位匹配即可）
  bool _matchesQuery(SessionInfo session, String normalizedQuery) {
    final fields = [
      session.summary,
      session.projectPath,
      session.agentName,
      session.lastMessage,
    ];
    return fields.any(
      (field) => field.toLowerCase().contains(normalizedQuery),
    );
  }

}
