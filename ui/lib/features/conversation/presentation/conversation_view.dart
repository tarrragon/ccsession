import 'package:ccsession/features/conversation/presentation/conversation_notifier.dart';
import 'package:ccsession/features/conversation/presentation/widgets/message_bubble_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 需求：Session 對話內容 View（Phase 1 3.2）
/// 約束：ConsumerWidget，從 conversationNotifierProvider 讀取狀態
/// 維護：空狀態/錯誤提示文字待 l10n 後遷移至 ARB
class ConversationView extends ConsumerWidget {
  const ConversationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(conversationNotifierProvider);
    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(error.toString()),
      data: (state) => _buildContent(context, ref, state),
    );
  }
}

Widget _buildContent(
  BuildContext context,
  WidgetRef ref,
  ConversationState state,
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

  return _buildMessageListWithFab(ref, state);
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

Widget _buildMessageListWithFab(WidgetRef ref, ConversationState state) {
  return Stack(
    children: [
      _buildMessageList(ref, state),
      if (!state.isAutoScrollEnabled)
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            key: const Key('conversation_jump_to_latest'),
            onPressed: () {
              ref.read(conversationNotifierProvider.notifier).setAutoScroll(true);
            },
            child: const Icon(Icons.arrow_downward),
          ),
        ),
    ],
  );
}

Widget _buildMessageList(WidgetRef ref, ConversationState state) {
  final hasLoadMore = state.hasMore;
  final itemCount = state.events.length + (hasLoadMore ? 1 : 0);

  return ListView.builder(
    itemCount: itemCount,
    itemBuilder: (context, index) {
      if (hasLoadMore && index == 0) {
        return _buildLoadMoreButton(ref);
      }
      final eventIndex = hasLoadMore ? index - 1 : index;
      return MessageBubbleFactory.build(state.events[eventIndex]);
    },
  );
}

Widget _buildLoadMoreButton(WidgetRef ref) {
  // TODO: i18n — 遷移至 ARB
  return Center(
    child: TextButton(
      key: const Key('conversation_load_more_button'),
      onPressed: () {
        ref.read(conversationNotifierProvider.notifier).loadMoreHistory();
      },
      child: const Text('Load earlier messages'),
    ),
  );
}
