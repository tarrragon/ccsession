import 'dart:math';

import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/session_group_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_group_ui_notifier.g.dart';

/// 需求：[0.2.1-W2-002] 管理分頁索引和摺疊狀態
/// 約束：@riverpod Notifier，狀態不持久化（記憶體即可）
@riverpod
class SessionGroupUiNotifier extends _$SessionGroupUiNotifier {
  @override
  SessionGroupUiState build(String projectPath) {
    return const SessionGroupUiState();
  }

  /// 需求：切換指定分組的頁碼
  /// 約束：pageIndex 下界 clamp 到 0，上界由 flattenGroups 的 safePage 處理
  void setPage(SessionStatus status, int pageIndex) {
    final clampedPage = max(pageIndex, 0);
    final newPages = {...state.currentPages, status: clampedPage};
    state = state.copyWith(currentPages: newPages);
  }

  /// 需求：切換指定分組的展開/摺疊狀態
  void toggleExpanded(SessionStatus status) {
    final currentValue = state.expandedGroups[status] ?? true;
    final newExpanded = {...state.expandedGroups, status: !currentValue};
    state = state.copyWith(expandedGroups: newExpanded);
  }

  /// 需求：重置所有分組的頁碼到第 0 頁
  /// 觸發時機：搜尋條件變化
  void resetAllPages() {
    state = state.copyWith(
      currentPages: SessionGroupUiState.defaultPages,
    );
  }
}
