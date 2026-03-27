import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'project_tab_notifier.g.dart';

/// 需求：[0.2.1-W2-001] 管理當前選中的專案 Tab 索引
@riverpod
class ProjectTabNotifier extends _$ProjectTabNotifier {
  @override
  int build() => 0;

  /// 需求：選擇指定 Tab
  void selectTab(int index) {
    state = index;
  }
}
