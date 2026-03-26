import 'package:ccsession/features/conversation/presentation/conversation_notifier.dart';
import 'package:ccsession/features/conversation/presentation/conversation_view.dart';
import 'package:ccsession/features/dashboard/presentation/dashboard_constants.dart';
import 'package:ccsession/features/dashboard/presentation/widgets/connection_status_bar.dart';
import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:ccsession/features/session_list/presentation/session_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 需求：主畫面根 Widget，組裝 sidebar + main area 雙欄佈局
/// 約束：ConsumerStatefulWidget，需要 ref.listen 橋接 selectedSessionId -> loadSession
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    /// 需求：監聽 selectedSessionId 變更，觸發 ConversationNotifier.loadSession
    /// 約束：只在 selectedSessionId 不為 null 時觸發；前一個 session 清理由 loadSession 內部處理
    ref.listen<String?>(selectedSessionIdProvider, (previous, next) {
      if (next != null && next != previous) {
        ref.read(conversationNotifierProvider.notifier).loadSession(next);
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
          const Expanded(child: _MainArea()),
        ],
      ),
    );
  }
}

/// 需求：main area，根據是否選中 session 顯示對話或空白提示
/// 約束：ConsumerWidget，watch selectedSessionIdProvider
class _MainArea extends ConsumerWidget {
  const _MainArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedSessionIdProvider);
    if (selectedId == null) {
      return const _EmptySelectionPlaceholder();
    }
    return const ConversationView();
  }
}

/// 需求：未選中 session 時的佔位提示
class _EmptySelectionPlaceholder extends StatelessWidget {
  const _EmptySelectionPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Select a session to view conversation'));
  }
}
