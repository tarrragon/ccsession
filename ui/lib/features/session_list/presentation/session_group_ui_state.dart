import 'package:ccsession/core/models/session_info.dart';
import 'package:equatable/equatable.dart';

/// 需求：[0.2.1-W2-002] 管理分頁索引和摺疊狀態的 UI 狀態
/// 約束：不可變（Equatable），active/idle 預設展開，completed 預設摺疊
class SessionGroupUiState extends Equatable {
  const SessionGroupUiState({
    this.currentPages = defaultPages,
    this.expandedGroups = defaultExpandedGroups,
  });

  /// 需求：所有分組頁碼預設為第 0 頁
  static const defaultPages = <SessionStatus, int>{
    SessionStatus.active: 0,
    SessionStatus.idle: 0,
    SessionStatus.completed: 0,
  };

  /// 需求：active/idle 預設展開，completed 預設摺疊
  static const defaultExpandedGroups = <SessionStatus, bool>{
    SessionStatus.active: true,
    SessionStatus.idle: true,
    SessionStatus.completed: false,
  };

  /// 每個分組的當前頁碼（從 0 開始）
  final Map<SessionStatus, int> currentPages;

  /// 每個分組的展開/摺疊狀態
  final Map<SessionStatus, bool> expandedGroups;

  SessionGroupUiState copyWith({
    Map<SessionStatus, int>? currentPages,
    Map<SessionStatus, bool>? expandedGroups,
  }) {
    return SessionGroupUiState(
      currentPages: currentPages ?? this.currentPages,
      expandedGroups: expandedGroups ?? this.expandedGroups,
    );
  }

  @override
  List<Object?> get props => [currentPages, expandedGroups];
}
