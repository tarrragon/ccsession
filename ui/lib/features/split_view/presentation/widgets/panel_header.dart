import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:ccsession/features/split_view/presentation/split_view_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 需求：UC-004 面板標題列，顯示 session 名稱和操作按鈕
/// 約束：layoutMode == single 時不顯示（由 SessionPanel 控制）
class PanelHeader extends ConsumerWidget {
  const PanelHeader({required this.panelIndex, super.key});

  /// 面板位置索引
  final int panelIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitState = ref.watch(splitViewNotifierProvider).valueOrNull;
    if (splitState == null || panelIndex >= splitState.panels.length) {
      return const SizedBox.shrink();
    }

    final panel = splitState.panels[panelIndex];
    final isMaximized = splitState.maximizedPanelIndex == panelIndex;
    final sessionName = _resolveSessionName(ref, panel.sessionId);
    final notifier = ref.read(splitViewNotifierProvider.notifier);

    return GestureDetector(
      onDoubleTap: () => _toggleMaximize(notifier, isMaximized),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            Expanded(
              child: Text(
                sessionName,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              key: Key('panel_${panelIndex}_maximize'),
              icon: Icon(isMaximized ? Icons.fullscreen_exit : Icons.fullscreen),
              iconSize: 18,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              onPressed: () => _toggleMaximize(notifier, isMaximized),
            ),
            IconButton(
              key: Key('panel_${panelIndex}_close'),
              icon: const Icon(Icons.close),
              iconSize: 18,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              onPressed: () => notifier.closePanel(panelIndex),
            ),
          ],
        ),
      ),
    );
  }

  /// 需求：UC-004 切換最大化/還原狀態
  void _toggleMaximize(SplitViewNotifier notifier, bool isMaximized) {
    if (isMaximized) {
      notifier.restorePanel();
    } else {
      notifier.maximizePanel(panelIndex);
    }
  }

  /// 需求：UC-004 從 session 列表中解析 session 名稱
  String _resolveSessionName(WidgetRef ref, String? sessionId) {
    if (sessionId == null) return '';
    final sessionListState =
        ref.watch(sessionListNotifierProvider).valueOrNull;
    if (sessionListState == null) return sessionId;
    final session = sessionListState.sessions.where(
      (s) => s.id == sessionId,
    );
    if (session.isEmpty) return sessionId;
    final name = session.first.agentName;
    return name.isNotEmpty ? name : sessionId;
  }
}
