import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/session_group_ui_notifier.dart';
import 'package:ccsession/features/session_list/presentation/session_list_items.dart';
import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:ccsession/features/session_list/presentation/session_list_search_notifier.dart';
import 'package:ccsession/features/session_list/presentation/widgets/pagination_controls.dart';
import 'package:ccsession/features/session_list/presentation/widgets/session_group_header.dart';
import 'package:ccsession/features/session_list/presentation/widgets/session_list_search_bar.dart';
import 'package:ccsession/features/session_list/presentation/widgets/session_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 需求：Sidebar 根 Widget，顯示按狀態分組的 session 列表
/// 約束：ConsumerWidget，從 sessionListNotifierProvider 讀取狀態
/// 維護：空列表提示和錯誤訊息待 l10n 後遷移至 ARB
class SessionListPage extends ConsumerWidget {
  const SessionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(sessionListNotifierProvider);
    return asyncState.when(
      loading: _buildLoading,
      error: (error, _) => _buildError(error),
      data: (state) => _buildData(context, ref, state),
    );
  }
}

Widget _buildLoading() {
  return const Center(child: CircularProgressIndicator());
}

Widget _buildError(Object error) {
  // TODO: i18n — 遷移至 ARB
  return const Center(child: Text('Failed to load sessions'));
}

Widget _buildData(BuildContext context, WidgetRef ref, SessionListState state) {
  final notifier = ref.read(sessionListNotifierProvider.notifier);
  final searchNotifier = ref.read(sessionListSearchNotifierProvider.notifier);
  final grouped = searchNotifier.filteredGroupedSessions();

  if (grouped.isEmpty) {
    // TODO: i18n — 遷移至 ARB
    return const Center(child: Text('No sessions'));
  }

  return Column(
    children: [
      const SessionListSearchBar(),
      Expanded(
        child: _SessionGroupListView(
          grouped: grouped,
          selectedSessionId: state.selectedSessionId,
          onSelectSession: notifier.selectSession,
        ),
      ),
    ],
  );
}

/// 需求：[0.2.1-W2-002] 渲染分組列表（含分頁和摺疊）
/// 約束：ConsumerWidget，監聽搜尋狀態變化以重置分頁
class _SessionGroupListView extends ConsumerWidget {
  const _SessionGroupListView({
    required this.grouped,
    required this.selectedSessionId,
    required this.onSelectSession,
  });

  final Map<SessionStatus, List<SessionInfo>> grouped;
  final String? selectedSessionId;
  final void Function(String) onSelectSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 需求：搜尋狀態變化時重置所有分頁
    ref.listen(sessionListSearchNotifierProvider, (prev, next) {
      ref.read(sessionGroupUiNotifierProvider.notifier).resetAllPages();
    });

    final uiState = ref.watch(sessionGroupUiNotifierProvider);
    final items = flattenGroups(grouped, uiState);

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => switch (items[index]) {
        HeaderItem(:final status, :final count, :final isExpanded) =>
          SessionGroupHeader(
            status: status,
            count: count,
            isExpanded: isExpanded,
            onToggleExpand: () => ref
                .read(sessionGroupUiNotifierProvider.notifier)
                .toggleExpanded(status),
          ),
        TileItem(:final session) => SessionListTile(
            session: session,
            isSelected: session.id == selectedSessionId,
            onTap: () => onSelectSession(session.id),
          ),
        PaginationItem(:final status, :final currentPage, :final totalPages) =>
          PaginationControls(
            currentPage: currentPage,
            totalPages: totalPages,
            onPageChanged: (page) => ref
                .read(sessionGroupUiNotifierProvider.notifier)
                .setPage(status, page),
          ),
      },
    );
  }
}
