import 'dart:async';

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
    final service = ref.read(webSocketServiceProvider);

    _subscription?.cancel();
    _subscription = service.messageStream.listen(_handleMessage);

    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
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
      events: newEvents,
      hasMore: data.hasMore,
      isLoadingHistory: false,
    ));
  }

  /// 需求：session_event 即時事件處理（Phase 1 流程 4.2）
  /// 約束：sessionId 不匹配則忽略；fallback 格式（無 type/content）靜默忽略
  void _handleSessionEvent(ServerMessage message) {
    final event = SessionEvent.fromJson(message.data);
    if (!event.isComplete) return;
    if (event.sessionId != _currentState.sessionId) return;

    state = AsyncData(_currentState.copyWith(
      events: [..._currentState.events, event],
    ));
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
