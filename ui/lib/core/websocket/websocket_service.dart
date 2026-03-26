import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:ccsession/core/constants/duration_constants.dart';
import 'package:ccsession/core/constants/websocket_constants.dart';
import 'package:ccsession/core/models/client_message.dart';
import 'package:ccsession/core/models/connection_state.dart';
import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/websocket/reconnect_strategy.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 需求：WebSocket 連線管理服務介面（spec 4.4）
/// 約束：與 UI 層完全解耦，連線狀態透過 stream 暴露
abstract class WebSocketService {
  /// 當前連線狀態
  WsConnectionState get connectionState;

  /// 連線狀態 stream（UI 訂閱用）
  Stream<WsConnectionState> get connectionStateStream;

  /// Server -> Client 訊息 stream（已解析為強型別）
  Stream<ServerMessage> get messageStream;

  /// 連線到 WebSocket server
  Future<void> connect({Uri? uri});

  /// 手動斷線（不觸發重連）
  Future<void> disconnect();

  /// 送出 Client -> Server 訊息
  void send(ClientMessage message);

  /// 便捷方法：請求 session 列表
  void requestSessionList();

  /// 便捷方法：請求指定 session 歷史事件
  void requestSessionHistory(
    String sessionId, {
    int? limit,
    String? before,
  });

  /// 便捷方法：訂閱 session 即時事件
  void subscribeSession(String sessionId);

  /// 便捷方法：取消訂閱
  void unsubscribeSession(String sessionId);

  /// 釋放資源
  void dispose();
}

/// WebSocketChannel 建構工廠型別（可注入，測試替換用）
typedef WebSocketChannelFactory = WebSocketChannel Function(Uri uri);

/// 需求：WebSocket 連線管理服務實作
/// 約束：重連策略透明、心跳偵測 35s、dispose 後靜默忽略
class WebSocketServiceImpl implements WebSocketService {
  /// [channelFactory] 可注入以供測試替換
  WebSocketServiceImpl({
    WebSocketChannelFactory? channelFactory,
    ReconnectStrategy? reconnectStrategy,
  })  : _channelFactory = channelFactory ?? _defaultChannelFactory,
        _reconnectStrategy = reconnectStrategy ?? ReconnectStrategy();

  static WebSocketChannel _defaultChannelFactory(Uri uri) =>
      WebSocketChannel.connect(uri);

  final WebSocketChannelFactory _channelFactory;
  final ReconnectStrategy _reconnectStrategy;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  Uri? _currentUri;
  bool _isManualDisconnect = false;
  bool _isDisposed = false;
  Timer? _reconnectTimer;
  Timer? _inactivityTimer;

  final StreamController<WsConnectionState> _connectionStateController =
      StreamController<WsConnectionState>.broadcast();
  final StreamController<ServerMessage> _messageController =
      StreamController<ServerMessage>.broadcast();

  WsConnectionState _connectionState = WsConnectionState.disconnected;

  @override
  WsConnectionState get connectionState => _connectionState;

  @override
  Stream<WsConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  Stream<ServerMessage> get messageStream => _messageController.stream;

  @override
  Future<void> connect({Uri? uri}) async {
    if (_isDisposed) return;

    _cancelReconnectTimer();
    _currentUri = uri ?? _buildDefaultUri();
    _isManualDisconnect = false;
    _setConnectionState(WsConnectionState.connecting);

    try {
      _channel = _channelFactory(_currentUri!);
      _setConnectionState(WsConnectionState.connected);
      _reconnectStrategy.reset();
      _startInactivityTimer();
      _listenToChannel();
      requestSessionList();
    } on Object {
      _scheduleReconnect();
    }
  }

  @override
  Future<void> disconnect() async {
    _isManualDisconnect = true;
    _cancelReconnectTimer();
    _cancelInactivityTimer();
    _closeChannel();
    _setConnectionState(WsConnectionState.disconnected);
  }

  @override
  void send(ClientMessage message) {
    if (_isDisposed) return;
    if (_channel == null) return;

    final jsonString = jsonEncode(message.toJson());
    _channel!.sink.add(jsonString);
  }

  @override
  void requestSessionList() {
    send(const ClientMessage(
      action: WebSocketConstants.actionGetSessionList,
    ));
  }

  @override
  void requestSessionHistory(
    String sessionId, {
    int? limit,
    String? before,
  }) {
    send(ClientMessage(
      action: WebSocketConstants.actionGetSessionHistory,
      sessionId: sessionId,
      limit: limit ?? 0,
      before: before ?? '',
    ));
  }

  @override
  void subscribeSession(String sessionId) {
    send(ClientMessage(
      action: WebSocketConstants.actionSubscribeSession,
      sessionId: sessionId,
    ));
  }

  @override
  void unsubscribeSession(String sessionId) {
    send(ClientMessage(
      action: WebSocketConstants.actionUnsubscribeSession,
      sessionId: sessionId,
    ));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isManualDisconnect = true;
    _cancelReconnectTimer();
    _cancelInactivityTimer();
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _connectionStateController.close();
    _messageController.close();
  }

  // -- 私有方法 --

  void _setConnectionState(WsConnectionState state) {
    _connectionState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  void _listenToChannel() {
    _channelSubscription = _channel!.stream.listen(
      _onData,
      onDone: _handleDisconnection,
      onError: (_) => _handleDisconnection(),
    );
  }

  void _onData(dynamic raw) {
    _resetInactivityTimer();
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final message = ServerMessage.fromJson(map);
      _messageController.add(message);
    } on Object catch (e) {
      // 需求：JSON 解析失敗時 log ERROR，丟棄該訊息，不中斷連線
      debugPrint('WebSocketService: _onData error: $e');
    }
  }

  void _handleDisconnection() {
    if (_isManualDisconnect || _isDisposed) return;
    _cancelInactivityTimer();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isManualDisconnect || _isDisposed) return;
    _setConnectionState(WsConnectionState.reconnecting);
    final delay = _reconnectStrategy.nextDelay();
    _reconnectTimer = Timer(delay, () => connect(uri: _currentUri));
  }

  void _startInactivityTimer() {
    _cancelInactivityTimer();
    _inactivityTimer = Timer(
      DurationConstants.pongTimeout,
      _onInactivityTimeout,
    );
  }

  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  void _onInactivityTimeout() {
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _handleDisconnection();
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _closeChannel() {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  Uri _buildDefaultUri() {
    return Uri(
      scheme: 'ws',
      host: WebSocketConstants.defaultHost,
      port: WebSocketConstants.defaultPort,
      path: WebSocketConstants.wsPath,
    );
  }
}
