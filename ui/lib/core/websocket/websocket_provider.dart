import 'package:ccsession/core/models/connection_state.dart';
import 'package:ccsession/core/websocket/websocket_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'websocket_provider.g.dart';

/// 需求：WebSocketService 單例 provider
/// 約束：ref.onDispose 時釋放資源
@riverpod
WebSocketService webSocketService(WebSocketServiceRef ref) {
  final service = WebSocketServiceImpl();
  ref.onDispose(service.dispose);
  service.connect();
  return service;
}

/// 需求：連線狀態（reactive stream）
@riverpod
Stream<WsConnectionState> connectionState(ConnectionStateRef ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.connectionStateStream;
}

