import 'dart:async';

import 'package:ccsession/core/constants/search_constants.dart';
import 'package:ccsession/features/conversation/domain/search_helpers.dart';
import 'package:ccsession/features/conversation/domain/search_match.dart';
import 'package:ccsession/features/conversation/presentation/conversation_notifier.dart';
import 'package:ccsession/features/conversation/presentation/conversation_search_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_search_notifier.g.dart';

/// 需求：管理對話搜尋狀態（Phase 1 4.1）
/// 約束：監聽 conversationNotifierProvider，events 變化時自動重新搜尋
/// 維護：debounce 使用簡單 Timer，不引入 RxDart
/// 維護：_currentSearch 用於跨 build() 重建保留搜尋狀態
@riverpod
class ConversationSearchNotifier extends _$ConversationSearchNotifier {
  Timer? _debounceTimer;

  /// 需求：跨 build() 保留搜尋狀態
  /// 約束：Riverpod build() 重建時 state 會被覆寫，需額外保留
  ConversationSearchState _currentSearch = const ConversationSearchState();

  @override
  ConversationSearchState build(int panelIndex) {
    final asyncConversation = ref.watch(conversationNotifierProvider(panelIndex));
    final conversationState = asyncConversation.valueOrNull;

    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    // 需求：session 切換（events 被清空）時重置搜尋（Phase 1 場景 12）
    if (conversationState != null &&
        conversationState.events.isEmpty &&
        _currentSearch.isSearchVisible) {
      _currentSearch = const ConversationSearchState();
      return _currentSearch;
    }

    // 需求：events 變化且搜尋開啟中自動重新搜尋（Phase 1 場景 10）
    if (_currentSearch.isSearchVisible && _currentSearch.query.isNotEmpty) {
      final events = conversationState?.events ?? [];
      final allMatches = _collectMatches(events, _currentSearch.query);
      final newIndex = allMatches.isEmpty
          ? -1
          : _clampIndex(_currentSearch.currentMatchIndex, allMatches.length);
      _currentSearch = _currentSearch.copyWith(
        matches: allMatches,
        currentMatchIndex: newIndex,
      );
      return _currentSearch;
    }

    return _currentSearch;
  }

  /// 需求：開啟搜尋列（Phase 1 4.1）
  void openSearch() {
    _currentSearch = _currentSearch.copyWith(isSearchVisible: true);
    state = _currentSearch;
  }

  /// 需求：關閉搜尋列並清除所有搜尋狀態（Phase 1 4.1）
  void closeSearch() {
    _debounceTimer?.cancel();
    _currentSearch = const ConversationSearchState();
    state = _currentSearch;
  }

  /// 需求：更新搜尋字串並觸發匹配（Phase 1 4.1）
  /// 約束：由 TextField.onChanged 呼叫，內部 debounce 300ms
  void updateQuery(String query) {
    _currentSearch = _currentSearch.copyWith(query: query);
    state = _currentSearch;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: SearchConstants.searchDebounceMilliseconds),
      _performSearch,
    );
  }

  /// 需求：導航到下一個匹配項（Phase 1 4.1）
  /// 約束：到最後一個時循環回第一個
  void nextMatch() {
    if (_currentSearch.matches.isEmpty) return;
    final newIndex =
        (_currentSearch.currentMatchIndex + 1) % _currentSearch.matches.length;
    _currentSearch = _currentSearch.copyWith(currentMatchIndex: newIndex);
    state = _currentSearch;
  }

  /// 需求：導航到上一個匹配項（Phase 1 4.1）
  /// 約束：到第一個時循環回最後一個
  void previousMatch() {
    if (_currentSearch.matches.isEmpty) return;
    final newIndex =
        (_currentSearch.currentMatchIndex - 1 + _currentSearch.matches.length) %
        _currentSearch.matches.length;
    _currentSearch = _currentSearch.copyWith(currentMatchIndex: newIndex);
    state = _currentSearch;
  }

  void _performSearch() {
    if (_currentSearch.query.isEmpty) {
      _currentSearch = _currentSearch.copyWith(
        matches: const [],
        currentMatchIndex: -1,
      );
      state = _currentSearch;
      return;
    }

    final conversationState =
        ref.read(conversationNotifierProvider(panelIndex)).valueOrNull;
    final events = conversationState?.events ?? [];
    final allMatches = _collectMatches(events, _currentSearch.query);

    _currentSearch = _currentSearch.copyWith(
      matches: allMatches,
      currentMatchIndex: allMatches.isEmpty ? -1 : 0,
    );
    state = _currentSearch;
  }

  List<SearchMatch> _collectMatches(
    List<dynamic> events,
    String query,
  ) {
    final allMatches = <SearchMatch>[];
    for (var eventIndex = 0; eventIndex < events.length; eventIndex++) {
      final event = events[eventIndex];
      final searchableFields = extractSearchableText(event);
      for (final field in searchableFields) {
        final fieldMatches = findAllMatches(field.text, query);
        for (final match in fieldMatches) {
          allMatches.add(SearchMatch(
            eventIndex: eventIndex,
            startOffset: match.start,
            endOffset: match.end,
            field: field.field,
          ));
        }
      }
    }
    return allMatches;
  }

  int _clampIndex(int previousIndex, int matchesLength) {
    if (previousIndex < 0) return 0;
    if (previousIndex >= matchesLength) return matchesLength - 1;
    return previousIndex;
  }
}
