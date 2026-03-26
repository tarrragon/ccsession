import 'package:ccsession/features/conversation/presentation/conversation_view.dart';
import 'package:ccsession/features/dashboard/presentation/dashboard_constants.dart';
import 'package:ccsession/features/dashboard/presentation/widgets/connection_status_bar.dart';
import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:ccsession/features/session_list/presentation/session_list_page.dart';
import 'package:ccsession/features/split_view/presentation/split_view_container.dart';
import 'package:ccsession/features/split_view/presentation/split_view_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 需求：UC-004 主畫面根 Widget，組裝 sidebar + main area 雙欄佈局
/// 約束：ConsumerStatefulWidget，ref.listen 橋接 selectedSessionId -> SplitViewNotifier
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    /// 需求：UC-004 監聽 selectedSessionId 變更，橋接到 SplitViewNotifier
    /// 約束：將 sessionId 指派給 activePanelIndex
    ref.listen<String?>(selectedSessionIdProvider, (previous, next) {
      if (next != null && next != previous) {
        final splitState =
            ref.read(splitViewNotifierProvider).valueOrNull;
        final activePanelIndex = splitState?.activePanelIndex ?? 0;
        ref.read(splitViewNotifierProvider.notifier).selectSession(
              panelIndex: activePanelIndex,
              sessionId: next,
            );
      }
    });

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: DashboardConstants.sidebarWidth,
            child: Column(
              children: [
                const ConnectionStatusBar(),
                const Expanded(child: SessionListPage()),
              ],
            ),
          ),
          const VerticalDivider(width: DashboardConstants.dividerWidth),
          Expanded(
            child: SplitViewContainer(
              contentBuilder: (panelIndex) =>
                  ConversationView(panelIndex: panelIndex),
            ),
          ),
        ],
      ),
    );
  }
}
