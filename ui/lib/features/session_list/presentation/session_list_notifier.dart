import 'dart:async';

import 'package:ccsession/core/constants/session_list_constants.dart';
import 'package:ccsession/core/models/server_message.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/features/session_list/presentation/session_group_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_list_notifier.g.dart';

/// 需求：Session List Sidebar 的完整 UI 狀態
/// 約束：不可變（Equatable），包含列表和選擇狀態
class SessionListState extends Equatable {
  const SessionListState({
    /// 完整 session 列表（來自 WebSocket session_list 訊息）
    this.sessions = const [],

    /// 當前選中的 session ID（null 表示未選擇）
    this.selectedSessionId,
  });

  final List<SessionInfo> sessions;
  final String? selectedSessionId;

  SessionListState copyWith({
    List<SessionInfo>? sessions,
    String? selectedSessionId,
  }) {
    return SessionListState(
      sessions: sessions ?? this.sessions,
      selectedSessionId: selectedSessionId ?? this.selectedSessionId,
    );
  }

  @override
  List<Object?> get props => [sessions, selectedSessionId];
}

/// 需求：管理 session 列表狀態，消費 WebSocket 訊息
/// 約束：使用 @riverpod code generation
@riverpod
class SessionListNotifier extends _$SessionListNotifier {
  StreamSubscription<ServerMessage>? _subscription;

  /// 需求：安全取得當前狀態，初始化前 fallback 為預設值
  SessionListState get _currentState =>
      state.valueOrNull ?? const SessionListState();

  /// 需求：初始建構，訂閱 serverMessageProvider 並請求列表
  @override
  Future<SessionListState> build() async {
    final service = ref.watch(webSocketServiceProvider);

    // 訂閱 message stream
    _subscription?.cancel();
    _subscription = service.messageStream.listen(_handleMessage);

    // dispose 時清理訂閱
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });

    // 發送初始請求
    service.requestSessionList();

    return const SessionListState();
  }

  /// 需求：處理 Server 推送的訊息
  /// 維護：新增訊息類型時需擴充此 switch
  /// 約束：異常不可中斷 stream，log 後繼續處理後續訊息
  void _handleMessage(ServerMessage message) {
    debugPrint('[SessionList] handleMessage: type=${message.type}');
    try {
      switch (message.type) {
        case 'session_list':
          _handleSessionList(message);
        case 'session_status_change':
          _handleStatusChange(message);
        case 'session_event':
        case 'session_history':
        case 'error':
          break; // 由 ConversationNotifier 處理
        default:
          debugPrint(
            'SessionListNotifier: unknown message type: ${message.type}',
          );
      }
    } on Object catch (error, stackTrace) {
      // 需求：反序列化失敗不可取消 StreamSubscription
      // 維護：目前 log 至 debugPrint，待 AppLogger 建立後遷移
      debugPrint(
        'SessionListNotifier: failed to handle ${message.type}: '
        '$error\n$stackTrace',
      );
    }
  }

  /// 需求：session_list 訊息替換整個列表
  void _handleSessionList(ServerMessage message) {
    final data = SessionListData.fromJson(message.data);
    debugPrint('[SessionList] sessions updated: ${data.sessions.length} total');
    final sessions = _trimSessions(data.sessions);
    state = AsyncData(_currentState.copyWith(sessions: sessions));
  }

  /// 需求：[0.2.1-W4-002] session_status_change 更新 status 及 lastEventAt
  /// 約束：lastEventAt 為 null 時保留原值（向後相容舊版 backend）
  /// 邊界：未知 sessionId 靜默忽略
  void _handleStatusChange(ServerMessage message) {
    final data = SessionStatusChangeData.fromJson(message.data);
    final updatedSessions = _currentState.sessions.map((session) {
      if (session.id == data.sessionId) {
        return _applyStatusChange(session, data);
      }
      return session;
    }).toList();
    state = AsyncData(_currentState.copyWith(sessions: updatedSessions));
  }

  /// 需求：[0.2.1-W4-002] 套用狀態變更，有 lastEventAt 時同時更新
  SessionInfo _applyStatusChange(
    SessionInfo session,
    SessionStatusChangeData data,
  ) {
    if (data.lastEventAt != null) {
      return session.copyWith(
        status: data.status,
        lastEventAt: data.lastEventAt,
      );
    }
    return session.copyWith(status: data.status);
  }

  /// 需求：[0.2.1-W5-004] 裁剪 session 列表至上限，保留最新的 session
  /// 約束：以 lastEventAt 降序排列後取前 N 筆
  List<SessionInfo> _trimSessions(List<SessionInfo> sessions) {
    const max = SessionListConstants.maxDisplaySessions;
    if (sessions.length <= max) return sessions;
    final sorted = [...sessions]
      ..sort((a, b) => (b.lastEventAt ?? DateTime(0))
          .compareTo(a.lastEventAt ?? DateTime(0)));
    debugPrint(
      '[SessionListNotifier] sessions trimmed: ${sessions.length} → $max',
    );
    return sorted.sublist(0, max);
  }

  /// 需求：使用者點擊 session 時更新選中狀態
  void selectSession(String sessionId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    state = AsyncData(currentState.copyWith(selectedSessionId: sessionId));
  }

  /// 需求：按狀態分組的 session 列表（計算屬性）
  /// 約束：key 順序固定 active/idle/completed，空組不含
  /// 每組內按 lastEventAt 降序排列
  /// 維護：生產程式碼已遷移至 filteredGroupedSessionsProvider，
  /// 此 getter 僅供測試直接驗證分組邏輯使用
  @visibleForTesting
  Map<SessionStatus, List<SessionInfo>> get groupedSessions {
    final currentState = state.valueOrNull;
    if (currentState == null) return {};
    return groupSessionsByStatus(currentState.sessions);
  }
}

/// 需求：暴露當前選中的 session ID 供其他模組消費
@riverpod
String? selectedSessionId(SelectedSessionIdRef ref) {
  final state = ref.watch(sessionListNotifierProvider).valueOrNull;
  return state?.selectedSessionId;
}
