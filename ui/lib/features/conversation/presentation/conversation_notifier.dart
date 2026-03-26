import 'dart:async';

import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_notifier.freezed.dart';
part 'conversation_notifier.g.dart';

/// 需求：Session 對話的完整 UI 狀態
/// 約束：不可變（freezed），包含事件列表和捲動控制狀態
@freezed
abstract class ConversationState with _$ConversationState {
  const factory ConversationState({
    /// 當前載入的 session ID
    String? sessionId,

    /// 對話事件列表（按 timestamp 升序）
    @Default([]) List<SessionEvent> events,

    /// 是否正在載入歷史事件
    @Default(false) bool isLoadingHistory,

    /// 是否還有更早的歷史事件可載入
    @Default(false) bool hasMore,

    /// 是否處於自動捲動模式（使用者未手動上捲）
    @Default(true) bool isAutoScrollEnabled,

    /// 錯誤訊息（載入失敗時）
    String? errorMessage,
  }) = _ConversationState;
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
  Future<ConversationState> build() async {
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

    final before = current.events.first.timestamp.toIso8601String();
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
  /// 約束：sessionId 不匹配則忽略
  void _handleSessionEvent(ServerMessage message) {
    final event = SessionEvent.fromJson(message.data);
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
