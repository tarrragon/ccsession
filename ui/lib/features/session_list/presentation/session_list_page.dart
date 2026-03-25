import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:ccsession/features/session_list/presentation/widgets/session_group_header.dart';
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
  final grouped = notifier.groupedSessions;

  if (grouped.isEmpty) {
    // TODO: i18n — 遷移至 ARB
    return const Center(child: Text('No sessions'));
  }

  return _SessionGroupListView(
    grouped: grouped,
    selectedSessionId: state.selectedSessionId,
    onSelectSession: notifier.selectSession,
  );
}

/// 需求：渲染分組列表（SessionGroupHeader + SessionListTile）
/// 約束：使用 ListView.builder 懶載入
class _SessionGroupListView extends StatelessWidget {
  const _SessionGroupListView({
    required this.grouped,
    required this.selectedSessionId,
    required this.onSelectSession,
  });

  final Map<SessionStatus, List<SessionInfo>> grouped;
  final String? selectedSessionId;
  final void Function(String) onSelectSession;

  @override
  Widget build(BuildContext context) {
    // 展平分組為 widget 列表
    final items = <_ListItem>[];
    for (final entry in grouped.entries) {
      items.add(_ListItem.header(entry.key, entry.value.length));
      for (final session in entry.value) {
        items.add(_ListItem.tile(session));
      }
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isHeader) {
          return SessionGroupHeader(
            status: item.status!,
            count: item.count!,
          );
        }
        final session = item.session!;
        return SessionListTile(
          session: session,
          isSelected: session.id == selectedSessionId,
          onTap: () => onSelectSession(session.id),
        );
      },
    );
  }
}

/// 內部輔助：ListView 項目（header 或 tile）
class _ListItem {
  _ListItem.header(this.status, this.count)
      : session = null,
        isHeader = true;

  _ListItem.tile(this.session)
      : status = null,
        count = null,
        isHeader = false;

  final bool isHeader;
  final SessionStatus? status;
  final int? count;
  final SessionInfo? session;
}
