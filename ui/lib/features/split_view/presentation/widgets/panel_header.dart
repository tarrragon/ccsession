import 'package:ccsession/core/constants/split_view_constants.dart';
import 'package:ccsession/features/split_view/presentation/session_name_provider.dart';
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
    final sessionName = ref.watch(sessionNameProvider(sessionId: panel.sessionId));
    final notifier = ref.read(splitViewNotifierProvider.notifier);

    return GestureDetector(
      onDoubleTap: () => _toggleMaximize(notifier, isMaximized),
      child: Container(
        padding: SplitViewConstants.headerPadding,
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
              iconSize: SplitViewConstants.headerIconSize,
              constraints: SplitViewConstants.headerButtonConstraints,
              padding: EdgeInsets.zero,
              onPressed: () => _toggleMaximize(notifier, isMaximized),
            ),
            IconButton(
              key: Key('panel_${panelIndex}_close'),
              icon: const Icon(Icons.close),
              iconSize: SplitViewConstants.headerIconSize,
              constraints: SplitViewConstants.headerButtonConstraints,
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

}
