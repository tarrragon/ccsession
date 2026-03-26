import 'package:ccsession/features/conversation/presentation/conversation_view.dart';
import 'package:ccsession/features/split_view/domain/layout_mode.dart';
import 'package:ccsession/features/split_view/presentation/split_view_notifier.dart';
import 'package:ccsession/features/split_view/presentation/widgets/panel_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 需求：UC-004 單一面板容器，包含標題列和對話內容
/// 約束：接收 panelIndex，傳遞給 ConversationView
class SessionPanel extends ConsumerWidget {
  const SessionPanel({required this.panelIndex, super.key});

  /// 面板位置索引
  final int panelIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitState = ref.watch(splitViewNotifierProvider).valueOrNull;
    if (splitState == null) return const SizedBox.shrink();

    if (panelIndex >= splitState.panels.length) {
      return const SizedBox.shrink();
    }

    final panel = splitState.panels[panelIndex];
    final isActive = splitState.activePanelIndex == panelIndex;
    final showHeader = splitState.layoutMode != LayoutMode.single;

    return GestureDetector(
      onTap: () =>
          ref.read(splitViewNotifierProvider.notifier).setActivePanel(panelIndex),
      child: Container(
        decoration: BoxDecoration(
          border: isActive && showHeader
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          children: [
            if (showHeader) PanelHeader(panelIndex: panelIndex),
            Expanded(
              child: panel.sessionId == null
                  ? const _EmptyPanelPlaceholder()
                  : ConversationView(panelIndex: panelIndex),
            ),
          ],
        ),
      ),
    );
  }
}

/// 需求：UC-004 空面板提示
class _EmptyPanelPlaceholder extends StatelessWidget {
  const _EmptyPanelPlaceholder();

  @override
  Widget build(BuildContext context) {
    // TODO: i18n
    return const Center(
      key: Key('empty_panel_placeholder'),
      child: Text('Select a session'),
    );
  }
}
