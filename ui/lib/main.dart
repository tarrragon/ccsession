import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/features/dashboard/presentation/dashboard_page.dart';
import 'package:ccsession/features/split_view/data/split_view_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    overrides: [
      splitViewStorageProvider.overrideWithValue(
        SharedPrefsSplitViewStorage(prefs),
      ),
    ],
    child: const App(),
  ));
}

/// 需求：應用程式根 Widget，啟動 WebSocket 連線並顯示 DashboardPage
/// 約束：必須為 ConsumerWidget 以訂閱 connectionStateProvider 觸發連線
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 訂閱 connectionStateProvider 啟動 WebSocket stream
    ref.watch(connectionStateProvider);

    return MaterialApp(
      title: 'CC Session Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}
