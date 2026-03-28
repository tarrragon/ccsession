import 'package:ccsession/core/constants/duration_constants.dart';
import 'package:ccsession/features/conversation/presentation/conversation_notifier.dart';
import 'package:ccsession/features/conversation/presentation/conversation_search_notifier.dart';
import 'package:ccsession/features/conversation/presentation/conversation_search_state.dart';
import 'package:ccsession/features/conversation/presentation/widgets/conversation_search_bar.dart';
import 'package:ccsession/features/conversation/presentation/widgets/message_bubble_factory.dart';
import 'package:ccsession/features/conversation/presentation/widgets/search_highlight_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 需求：Session 對話內容 View（Phase 1 3.2）
/// 約束：ConsumerWidget，整合搜尋列和鍵盤快捷鍵（0.2.0-W2-005.2）
/// 維護：空狀態/錯誤提示文字待 l10n 後遷移至 ARB
class ConversationView extends ConsumerWidget {
  const ConversationView({required this.panelIndex, super.key});

  /// 需求：UC-004 面板索引，用於 family provider 區分
  final int panelIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(conversationNotifierProvider(panelIndex));
    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(error.toString()),
      data: (state) => _buildContentWithSearch(context, ref, state, panelIndex),
    );
  }
}

Widget _buildContentWithSearch(
  BuildContext context,
  WidgetRef ref,
  ConversationState state,
  int panelIndex,
) {
  return CallbackShortcuts(
    bindings: <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
          _openSearch(ref, panelIndex),
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () =>
          _openSearch(ref, panelIndex),
    },
    child: Focus(
      autofocus: true,
      child: Column(
        children: [
          ConversationSearchBar(panelIndex: panelIndex),
          Expanded(child: _buildContent(context, ref, state, panelIndex)),
        ],
      ),
    ),
  );
}

void _openSearch(WidgetRef ref, int panelIndex) {
  ref.read(conversationSearchNotifierProvider(panelIndex).notifier).openSearch();
}

Widget _buildContent(
  BuildContext context,
  WidgetRef ref,
  ConversationState state,
  int panelIndex,
) {
  if (state.isLoadingHistory && state.events.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  }

  if (state.errorMessage != null) {
    return _buildErrorState(state.errorMessage!);
  }

  if (state.events.isEmpty) {
    return _buildEmptyState();
  }

  return _buildMessageListWithFab(ref, state, panelIndex);
}

Widget _buildEmptyState() {
  // TODO: i18n — 遷移至 ARB
  return const Center(
    key: Key('conversation_empty_state'),
    child: Text('No messages yet'),
  );
}

Widget _buildErrorState(String message) {
  // TODO: i18n — 遷移至 ARB
  return Center(
    key: const Key('conversation_error_state'),
    child: Text(message),
  );
}

Widget _buildMessageListWithFab(
  WidgetRef ref,
  ConversationState state,
  int panelIndex,
) {
  return _AutoScrollMessageList(
    key: Key('auto_scroll_message_list_$panelIndex'),
    state: state,
    panelIndex: panelIndex,
  );
}

/// 需求：[0.2.0-W7-004.4] 自動捲動訊息列表
/// 約束：ConsumerStatefulWidget 管理 ScrollController 生命週期，
///       最新訊息在頂部，新事件到達且 isAutoScrollEnabled 時自動捲動到頂部
class _AutoScrollMessageList extends ConsumerStatefulWidget {
  const _AutoScrollMessageList({
    required this.state,
    required this.panelIndex,
    super.key,
  });

  final ConversationState state;
  final int panelIndex;

  @override
  ConsumerState<_AutoScrollMessageList> createState() =>
      _AutoScrollMessageListState();
}

class _AutoScrollMessageListState
    extends ConsumerState<_AutoScrollMessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 需求：[0.2.0-W7-004.4] 監聯 state 變更，自動捲動到最新訊息
  /// 約束：最新訊息在頂部，offset 0 即為最新
  void _scrollToTopIfEnabled() {
    if (!widget.state.isAutoScrollEnabled) return;
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: DurationConstants.autoScrollDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(covariant _AutoScrollMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.events.length > oldWidget.state.events.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToTopIfEnabled();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final panelIndex = widget.panelIndex;

    return Stack(
      children: [
        _buildMessageList(state, panelIndex),
        if (!state.isAutoScrollEnabled)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              key: const Key('conversation_scroll_to_top'),
              onPressed: () {
                ref
                    .read(conversationNotifierProvider(panelIndex).notifier)
                    .setAutoScroll(true);
                _scrollToTopIfEnabled();
              },
              child: const Icon(Icons.arrow_upward),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageList(ConversationState state, int panelIndex) {
    final hasLoadMore = state.hasMore;
    final itemCount = state.events.length + (hasLoadMore ? 1 : 0);
    final searchState =
        ref.watch(conversationSearchNotifierProvider(panelIndex));

    return ListView.builder(
      key: const Key('conversation_message_list'),
      controller: _scrollController,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (hasLoadMore && index == itemCount - 1) {
          return _buildLoadMoreButton(ref, panelIndex);
        }
        final eventIndex = state.events.length - 1 - index;
        final event = state.events[eventIndex];
        final highlightRanges = _computeHighlightRanges(
          searchState,
          eventIndex,
        );
        return MessageBubbleFactory.build(
          event,
          highlightRanges: highlightRanges,
        );
      },
    );
  }
}

/// 需求：計算特定 event 的高亮範圍（Phase 3a 4.8）
/// 約束：篩選該 event 的匹配，標記 currentMatch 為 isCurrent
List<HighlightRange>? _computeHighlightRanges(
  ConversationSearchState searchState,
  int eventIndex,
) {
  if (!searchState.isSearchVisible || searchState.matches.isEmpty) {
    return null;
  }

  final matchesForEvent = searchState.matches
      .where((match) => match.eventIndex == eventIndex)
      .toList();

  if (matchesForEvent.isEmpty) return null;

  final currentMatch = searchState.currentMatch;
  return matchesForEvent
      .map((match) => (
            start: match.startOffset,
            end: match.endOffset,
            isCurrent: match == currentMatch,
            field: match.field,
          ))
      .toList();
}

Widget _buildLoadMoreButton(WidgetRef ref, int panelIndex) {
  // TODO: i18n — 遷移至 ARB
  return Center(
    child: TextButton(
      key: const Key('conversation_load_more_button'),
      onPressed: () {
        ref
            .read(conversationNotifierProvider(panelIndex).notifier)
            .loadMoreHistory();
      },
      child: const Text('Load earlier messages'),
    ),
  );
}
