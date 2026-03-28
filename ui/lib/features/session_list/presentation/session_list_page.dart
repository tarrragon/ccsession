import 'package:ccsession/core/constants/session_list_constants.dart';
import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/filtered_grouped_sessions_provider.dart';
import 'package:ccsession/features/session_list/presentation/session_group_ui_notifier.dart';
import 'package:ccsession/features/session_list/presentation/session_group_utils.dart';
import 'package:ccsession/features/session_list/presentation/session_list_helpers.dart';
import 'package:ccsession/features/session_list/presentation/session_list_items.dart';
import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
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
  return const Center(child: Text(SessionListConstants.loadFailedMessage));
}

Widget _buildData(BuildContext context, WidgetRef ref, SessionListState state) {
  final notifier = ref.read(sessionListNotifierProvider.notifier);

  if (state.sessions.isEmpty) {
    // TODO: i18n — 遷移至 ARB
    return const Center(child: Text(SessionListConstants.noSessionsMessage));
  }

  return Column(
    children: [
      const SessionListSearchBar(),
      Expanded(
        child: _ProjectTabbedView(
          sessions: state.sessions,
          selectedSessionId: state.selectedSessionId,
          onSelectSession: notifier.selectSession,
        ),
      ),
    ],
  );
}

/// 需求：[0.2.1-W2-001] 按專案分組的 Tab 頁籤檢視
/// 約束：ConsumerStatefulWidget + TickerProviderStateMixin（DefaultTabController 需要）
/// 約束：Tab 數量變化時重建 TabController
class _ProjectTabbedView extends ConsumerStatefulWidget {
  const _ProjectTabbedView({
    required this.sessions,
    required this.selectedSessionId,
    required this.onSelectSession,
  });

  final List<SessionInfo> sessions;
  final String? selectedSessionId;
  final void Function(String) onSelectSession;

  @override
  ConsumerState<_ProjectTabbedView> createState() =>
      _ProjectTabbedViewState();
}

class _ProjectTabbedViewState extends ConsumerState<_ProjectTabbedView>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectGroups = groupSessionsByProject(widget.sessions);
    final activeProjectGroups = _filterActiveProjects(projectGroups);
    final paths = sortedProjectPaths(activeProjectGroups);
    final tabCount = paths.length;

    if (tabCount == 0) {
      return const Center(
        child: Text(SessionListConstants.noActiveSessionsMessage),
      );
    }

    _rebuildTabControllerIfNeeded(tabCount);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            for (final path in paths)
              _buildConstrainedTab(path, projectGroups[path]!.length),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              for (final path in paths)
                _SessionGroupListView(
                  selectedSessionId: widget.selectedSessionId,
                  onSelectSession: widget.onSelectSession,
                  projectPath: path,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 需求：Tab 數量變化時重建 TabController，clamp 索引到有效範圍
  void _rebuildTabControllerIfNeeded(int tabCount) {
    if (_tabController?.length == tabCount) return;
    final previousIndex = _tabController?.index ?? 0;
    _tabController?.dispose();
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: previousIndex.clamp(0, tabCount - 1),
    );
  }

  /// 需求：過濾只保留包含 active session 的專案
  Map<String, List<SessionInfo>> _filterActiveProjects(
    Map<String, List<SessionInfo>> groups,
  ) {
    return Map.fromEntries(
      groups.entries.where(
        (entry) => entry.value.any((s) => s.status == SessionStatus.active),
      ),
    );
  }

  /// 需求：Tab 標籤格式 — 專案名稱 + session 數量
  /// 約束：空 projectPath 顯示 "Other"
  String _buildTabLabel(String path, int count) {
    // TODO: i18n — "Other" 遷移至 ARB
    final name = path.isEmpty
        ? SessionListConstants.otherProjectLabel
        : extractProjectName(path);
    return '$name ($count)';
  }

  /// 需求：[0.2.1-W4-001] 寬度約束的專案頁籤，防止長名稱溢出
  /// 約束：maxWidth 160px + ellipsis 截斷 + Tooltip 顯示完整路徑
  Widget _buildConstrainedTab(String path, int count) {
    final label = _buildTabLabel(path, count);
    final fullPath = path.isEmpty
        ? SessionListConstants.otherProjectLabel
        : path;
    return Tooltip(
      message: fullPath,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: SessionListConstants.tabMaxWidth,
        ),
        child: Tab(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

/// 需求：[0.2.1-W2-002] 渲染分組列表（含分頁和摺疊）
/// 約束：ConsumerWidget，監聽搜尋狀態變化以重置分頁
/// 維護：projectPath 用於 family provider 隔離各專案的 UI 狀態
/// 維護：grouped 由內部從 filteredGroupedSessions 計算，確保搜尋變化時自動重算
class _SessionGroupListView extends ConsumerWidget {
  const _SessionGroupListView({
    required this.selectedSessionId,
    required this.onSelectSession,
    this.projectPath = '',
  });

  final String? selectedSessionId;
  final void Function(String) onSelectSession;
  final String projectPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(
      filteredGroupedSessionsProvider(projectPath: projectPath),
    );
    final uiState = ref.watch(sessionGroupUiNotifierProvider(projectPath));
    final uiNotifier =
        ref.read(sessionGroupUiNotifierProvider(projectPath).notifier);
    final items = flattenGroups(grouped, uiState);

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItem(items[index], uiNotifier),
    );
  }

  /// 需求：根據 SessionListItem 類型建立對應 Widget
  Widget _buildItem(
    SessionListItem item,
    SessionGroupUiNotifier uiNotifier,
  ) {
    return switch (item) {
      HeaderItem(:final status, :final count, :final isExpanded) =>
        SessionGroupHeader(
          status: status,
          count: count,
          isExpanded: isExpanded,
          onToggleExpand: () => uiNotifier.toggleExpanded(status),
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
          onPageChanged: (page) => uiNotifier.setPage(status, page),
        ),
    };
  }
}
