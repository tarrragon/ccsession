import 'dart:async';

import 'package:ccsession/core/constants/search_constants.dart';
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

}
