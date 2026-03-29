import 'dart:async';

import 'package:ccsession/core/constants/conversation_constants.dart';
import 'package:ccsession/core/models/connection_state.dart';
import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_notifier.g.dart';

/// Sentinel 值，用於 copyWith 中區分「未傳入」和「明確傳入 null」
const _sentinel = Object();

/// 需求：Session 對話的完整 UI 狀態
/// 約束：不可變（Equatable），包含事件列表和捲動控制狀態
class ConversationState extends Equatable {
  const ConversationState({
    /// 當前載入的 session ID
    this.sessionId,

    /// 對話事件列表（按 timestamp 升序）
    this.events = const [],

    /// 是否正在載入歷史事件
    this.isLoadingHistory = false,

    /// 是否還有更早的歷史事件可載入
    this.hasMore = false,

    /// 是否處於自動捲動模式（使用者未手動上捲）
    this.isAutoScrollEnabled = true,

    /// 錯誤訊息（載入失敗時）
    this.errorMessage,
  });

  final String? sessionId;
  final List<SessionEvent> events;
  final bool isLoadingHistory;
  final bool hasMore;
  final bool isAutoScrollEnabled;
  final String? errorMessage;

  /// 約束：sessionId 和 errorMessage 為 nullable，使用 sentinel 區分
  /// 「未傳入」（保留原值）和「明確傳入 null」（設為 null）
  ConversationState copyWith({
    Object? sessionId = _sentinel,
    List<SessionEvent>? events,
    bool? isLoadingHistory,
    bool? hasMore,
    bool? isAutoScrollEnabled,
    Object? errorMessage = _sentinel,
  }) {
    return ConversationState(
      sessionId:
          sessionId == _sentinel ? this.sessionId : sessionId as String?,
      events: events ?? this.events,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      hasMore: hasMore ?? this.hasMore,
      isAutoScrollEnabled: isAutoScrollEnabled ?? this.isAutoScrollEnabled,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        events,
        isLoadingHistory,
        hasMore,
        isAutoScrollEnabled,
        errorMessage,
      ];
}

/// 需求：管理 session 對話狀態，消費 WebSocket 訊息
/// 約束：使用 @riverpod code generation，與 SessionListNotifier 模式一致
@riverpod
class ConversationNotifier extends _$ConversationNotifier {
  StreamSubscription<ServerMessage>? _subscription;

  /// 需求：安全取得當前狀態，初始化前 fallback 為預設值
  ConversationState get _currentState =>
      state.valueOrNull ?? const ConversationState();

  /// 需求：初始建構，訂閱 WebSocket messageStream
  @override
  Future<ConversationState> build(int panelIndex) async {
    // 需求：[0.4.0-W2-004] ref.watch 確保 WebSocketService 重建時自動重訂閱
    // 約束：service 變更時 build() 重新執行，舊 _subscription 自動取消
    final service = ref.watch(webSocketServiceProvider);

    _subscription?.cancel();
    _subscription = service.messageStream.listen(_handleMessage);

    // 需求：[0.2.1-W4-006] WebSocket 重連後自動重新訂閱當前 session
    // 約束：重連會建立新的後端 Client，舊訂閱丟失
    ref.listen<AsyncValue<WsConnectionState>>(connectionStateProvider,
        (previous, next) {
      final prevState = previous?.valueOrNull;
      final nextState = next.valueOrNull;
      if (nextState == WsConnectionState.connected &&
          prevState != WsConnectionState.connected) {
        _resubscribeCurrentSession();
      }
    });

    // 需求：[0.4.0-W2-004] 面板 dispose 時向後端發送 unsubscribe
    // 約束：防止後端持續推送已關閉面板的 session 事件
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
      final currentSessionId = state.valueOrNull?.sessionId;
      if (currentSessionId != null) {
        service.unsubscribeSession(currentSessionId);
      }
    });

    return const ConversationState();
  }

  /// 需求：載入指定 session 的對話（Phase 1 流程 4.1）
  /// 約束：先取消前 session 訂閱，再重置 state，再請求歷史和訂閱
  void loadSession(String sessionId) {
    final service = ref.read(webSocketServiceProvider);
    final oldSessionId = _currentState.sessionId;

    if (oldSessionId != null) {
      service.unsubscribeSession(oldSessionId);
    }

    state = AsyncData(_currentState.copyWith(
      sessionId: sessionId,
      events: [],
      isLoadingHistory: true,
      hasMore: false,
      errorMessage: null,
    ));

    service.requestSessionHistory(sessionId);
    service.subscribeSession(sessionId);
  }

  /// 需求：離開 session，取消訂閱並清空狀態
  void leaveSession() {
    final service = ref.read(webSocketServiceProvider);
    final currentSessionId = _currentState.sessionId;

    if (currentSessionId != null) {
      service.unsubscribeSession(currentSessionId);
    }

    state = AsyncData(const ConversationState());
  }

  /// 需求：設定自動捲動狀態（由 ConversationView 捲動偵測呼叫）
  void setAutoScroll(bool enabled) {
    state = AsyncData(
      _currentState.copyWith(isAutoScrollEnabled: enabled),
    );
  }

  /// 需求：載入更早的歷史事件（Phase 1 流程 4.3）
  /// 約束：hasMore 為 false 或正在載入時忽略
  void loadMoreHistory() {
    final current = _currentState;
    if (!current.hasMore || current.isLoadingHistory) return;
    if (current.events.isEmpty) return;

    state = AsyncData(current.copyWith(isLoadingHistory: true));

    final before = current.events.first.timestamp?.toIso8601String();
    if (before == null) return;
    ref.read(webSocketServiceProvider).requestSessionHistory(
          current.sessionId!,
          before: before,
        );
  }

  /// 需求：處理 Server 推送的訊息
  /// 約束：異常不可中斷 stream，log 後繼續
  void _handleMessage(ServerMessage message) {
    debugPrint('[Conv] handleMessage: type=${message.type}');
    try {
      switch (message.type) {
        case 'session_history':
          _handleSessionHistory(message);
        case 'session_event':
          _handleSessionEvent(message);
        case 'error':
          _handleError(message);
        default:
          break;
      }
    } on Object catch (error, stackTrace) {
      debugPrint(
        'ConversationNotifier: failed to handle ${message.type}: '
        '$error\n$stackTrace',
      );
    }
  }

  /// 需求：session_history 回應處理（首次載入或分頁 prepend）
  void _handleSessionHistory(ServerMessage message) {
    final data = SessionHistoryData.fromJson(message.data);
    debugPrint(
      '[Conv] history loaded: ${data.events.length} events, '
      'hasMore=${data.hasMore}',
    );
    if (data.sessionId != _currentState.sessionId) return;

    final current = _currentState;
    final List<SessionEvent> newEvents;

    if (current.events.isNotEmpty && current.isLoadingHistory) {
      // 分頁載入：prepend 歷史事件到前面
      newEvents = [...data.events, ...current.events];
    } else {
      // 首次載入
      newEvents = data.events;
    }

    state = AsyncData(current.copyWith(
      events: _trimEvents(newEvents),
      hasMore: data.hasMore,
      isLoadingHistory: false,
    ));
  }

  /// 需求：session_event 即時事件處理（Phase 1 流程 4.2）
  /// 約束：sessionId 不匹配則忽略；fallback 格式（無 type/content）觸發主動拉取
  void _handleSessionEvent(ServerMessage message) {
    final event = SessionEvent.fromJson(message.data);
    if (!event.isComplete) {
      _fetchHistoryForIncompleteEvent(event);
      return;
    }
    if (event.sessionId != _currentState.sessionId) return;

    final previousCount = _currentState.events.length;
    state = AsyncData(_currentState.copyWith(
      events: _trimEvents([..._currentState.events, event]),
    ));
    debugPrint(
      '[Conv] session_event: count $previousCount -> ${_currentState.events.length}, '
      'sessionId=${event.sessionId}',
    );
  }

  /// 需求：[0.2.1-W4-006] WebSocket 重連後重新訂閱當前 session
  /// 約束：僅在有正在查看的 session 時觸發
  void _resubscribeCurrentSession() {
    final sessionId = _currentState.sessionId;
    if (sessionId == null) return;

    debugPrint('[Conv] resubscribe after reconnect: $sessionId');
    final service = ref.read(webSocketServiceProvider);
    service.subscribeSession(sessionId);
    service.requestSessionHistory(sessionId);
  }

  /// 需求：[0.2.0-W7-004.3] incomplete event 時主動拉取最新歷史
  /// 約束：僅在 sessionId 匹配當前查看的 session 時觸發
  void _fetchHistoryForIncompleteEvent(SessionEvent event) {
    final currentSessionId = _currentState.sessionId;
    if (event.sessionId.isEmpty || event.sessionId != currentSessionId) {
      debugPrint('[Conv] skipped incomplete event (session mismatch)');
      return;
    }
    debugPrint('[Conv] incomplete event, fetching history for $currentSessionId');
    ref.read(webSocketServiceProvider).requestSessionHistory(currentSessionId!);
  }

  /// 需求：[0.2.1-W5-004] 裁剪 events 至上限，保留最新的事件
  List<SessionEvent> _trimEvents(List<SessionEvent> events) {
    const max = ConversationConstants.maxEventsPerConversation;
    if (events.length <= max) return events;
    final trimmed = events.sublist(events.length - max);
    debugPrint(
      '[ConversationNotifier] events trimmed: ${events.length} → $max',
    );
    return trimmed;
  }

  /// 需求：error 回應處理
  void _handleError(ServerMessage message) {
    final data = ErrorData.fromJson(message.data);
    state = AsyncData(_currentState.copyWith(
      errorMessage: data.code,
      isLoadingHistory: false,
    ));
  }
}
