import 'dart:async';
import 'dart:convert';

import 'package:ccsession/core/constants/websocket_constants.dart';
import 'package:ccsession/core/models/client_message.dart';
import 'package:ccsession/core/models/connection_state.dart';
import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/websocket/websocket_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// -- Mock / Fake --

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

class FakeWebSocketSink extends Fake implements WebSocketSink {
  final List<dynamic> addedMessages = [];
  bool isClosed = false;

  @override
  void add(dynamic data) => addedMessages.add(data);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    isClosed = true;
  }
}

// -- 測試常數 --

const _sessionListJson = '{"type":"session_list","data":{"sessions":[]}}';
const _errorJson =
    '{"type":"error","data":{"code":"SESSION_NOT_FOUND"}}';
const _invalidJson = '{not valid json}';

// -- Helper --

/// 建立一組 mock channel + sink + streamController
({
  MockWebSocketChannel channel,
  FakeWebSocketSink sink,
  StreamController<dynamic> streamController,
}) _createMockChannel() {
  final channel = MockWebSocketChannel();
  final sink = FakeWebSocketSink();
  final streamController = StreamController<dynamic>();
  when(() => channel.sink).thenReturn(sink);
  when(() => channel.stream).thenAnswer((_) => streamController.stream);
  return (channel: channel, sink: sink, streamController: streamController);
}

/// 解析 sink 中最後一筆 JSON
Map<String, dynamic> _lastSentJson(FakeWebSocketSink sink) {
  return jsonDecode(sink.addedMessages.last as String) as Map<String, dynamic>;
}

void main() {
  group('TG-07: WebSocketService 連線管理', () {
    late WebSocketServiceImpl service;
    late MockWebSocketChannel mockChannel;
    late FakeWebSocketSink fakeSink;
    late StreamController<dynamic> serverStreamController;

    /// 建立 service + 成功連線的 channel factory
    void setUpWithSuccessfulConnection() {
      final mock = _createMockChannel();
      mockChannel = mock.channel;
      fakeSink = mock.sink;
      serverStreamController = mock.streamController;

      service = WebSocketServiceImpl(
        channelFactory: (_) => mockChannel,
      );
    }

    /// 建立 service，前 [failCount] 次 connect 失敗，之後成功
    ({
      List<StreamController<dynamic>> controllers,
      List<FakeWebSocketSink> sinks,
    }) setUpWithMultipleConnections({
      int failCount = 0,
    }) {
      final controllers = <StreamController<dynamic>>[];
      final sinks = <FakeWebSocketSink>[];
      var callCount = 0;

      service = WebSocketServiceImpl(
        channelFactory: (_) {
          callCount++;
          if (callCount <= failCount) {
            throw Exception('Connection failed');
          }
          final mock = _createMockChannel();
          controllers.add(mock.streamController);
          sinks.add(mock.sink);
          mockChannel = mock.channel;
          fakeSink = mock.sink;
          serverStreamController = mock.streamController;
          return mock.channel;
        },
      );

      return (controllers: controllers, sinks: sinks);
    }

    tearDown(() {
      service.dispose();
    });

    // === 場景 1: 成功連線 ===

    /// TC-07-01: connect 成功時狀態轉為 connected
    test('TC-07-01: connect 成功時狀態轉為 connected', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();

        expect(
          service.connectionState,
          WsConnectionState.disconnected,
        );

        final states = <WsConnectionState>[];
        service.connectionStateStream.listen(states.add);

        service.connect();
        async.flushMicrotasks();

        expect(states, [
          WsConnectionState.connecting,
          WsConnectionState.connected,
        ]);
        expect(service.connectionState, WsConnectionState.connected);
      });
    });

    /// TC-07-02: connect 成功後自動請求 session_list
    test('TC-07-02: connect 成功後自動請求 session_list', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();

        service.connect();
        async.flushMicrotasks();

        expect(fakeSink.addedMessages, isNotEmpty);
        final sent = _lastSentJson(fakeSink);
        expect(sent['action'], WebSocketConstants.actionGetSessionList);
      });
    });

    /// TC-07-03: connect 成功後重連策略被 reset
    test('TC-07-03: connect 成功後重連策略被 reset', () {
      fakeAsync((async) {
        // 第一次失敗，第二次成功
        setUpWithMultipleConnections(failCount: 1);

        service.connect();
        async.flushMicrotasks();
        // 失敗後 reconnecting
        expect(service.connectionState, WsConnectionState.reconnecting);

        // 1s 後重試 → 成功
        async.elapse(const Duration(seconds: 1));
        expect(service.connectionState, WsConnectionState.connected);
      });
    });

    // === 場景 2: 連線失敗自動重連 ===

    /// TC-07-04: connect 失敗時狀態轉為 reconnecting
    test('TC-07-04: connect 失敗時狀態轉為 reconnecting', () {
      fakeAsync((async) {
        service = WebSocketServiceImpl(
          channelFactory: (_) => throw Exception('fail'),
        );
        final states = <WsConnectionState>[];
        service.connectionStateStream.listen(states.add);

        service.connect();
        async.flushMicrotasks();

        expect(states, [
          WsConnectionState.connecting,
          WsConnectionState.reconnecting,
        ]);
      });
    });

    /// TC-07-05: 連線失敗後第一次重連延遲 1 秒
    test('TC-07-05: 連線失敗後第一次重連延遲 1 秒', () {
      fakeAsync((async) {
        var connectCount = 0;
        service = WebSocketServiceImpl(
          channelFactory: (_) {
            connectCount++;
            throw Exception('fail');
          },
        );

        service.connect();
        async.flushMicrotasks();
        expect(connectCount, 1);

        async.elapse(const Duration(milliseconds: 999));
        expect(connectCount, 1);

        async.elapse(const Duration(milliseconds: 1));
        expect(connectCount, 2);
      });
    });

    /// TC-07-06: 連續失敗時延遲遞增
    test('TC-07-06: 連續失敗時延遲遞增', () {
      fakeAsync((async) {
        var connectCount = 0;
        service = WebSocketServiceImpl(
          channelFactory: (_) {
            connectCount++;
            throw Exception('fail');
          },
        );

        service.connect();
        async.flushMicrotasks();
        expect(connectCount, 1);

        async.elapse(const Duration(seconds: 1)); // 2nd
        expect(connectCount, 2);

        async.elapse(const Duration(seconds: 2)); // 3rd
        expect(connectCount, 3);

        async.elapse(const Duration(seconds: 4)); // 4th
        expect(connectCount, 4);
      });
    });

    // === 場景 3: 指數退避觸頂 ===

    /// TC-07-07: 連續失敗 6 次後延遲固定 30 秒
    test('TC-07-07: 連續失敗 6 次後延遲固定 30 秒', () {
      fakeAsync((async) {
        var connectCount = 0;
        service = WebSocketServiceImpl(
          channelFactory: (_) {
            connectCount++;
            throw Exception('fail');
          },
        );

        service.connect();
        async.flushMicrotasks(); // 1st
        async.elapse(const Duration(seconds: 1)); // 2nd
        async.elapse(const Duration(seconds: 2)); // 3rd
        async.elapse(const Duration(seconds: 4)); // 4th
        async.elapse(const Duration(seconds: 8)); // 5th
        async.elapse(const Duration(seconds: 16)); // 6th
        async.elapse(const Duration(seconds: 30)); // 7th
        expect(connectCount, 7);

        async.elapse(const Duration(seconds: 30)); // 8th
        expect(connectCount, 8);

        async.elapse(const Duration(seconds: 30)); // 9th
        expect(connectCount, 9);
      });
    });

    // === 場景 4: 手動斷線不重連 ===

    /// TC-07-08: disconnect 後狀態轉為 disconnected 且不重連
    test('TC-07-08: disconnect 後狀態轉為 disconnected 且不重連', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();
        expect(service.connectionState, WsConnectionState.connected);

        service.disconnect();
        async.flushMicrotasks();

        expect(service.connectionState, WsConnectionState.disconnected);

        async.elapse(const Duration(seconds: 60));
        expect(service.connectionState, WsConnectionState.disconnected);
      });
    });

    /// TC-07-09: 重連過程中手動 disconnect 停止重連
    test('TC-07-09: 重連過程中手動 disconnect 停止重連', () {
      fakeAsync((async) {
        var connectCount = 0;
        service = WebSocketServiceImpl(
          channelFactory: (_) {
            connectCount++;
            throw Exception('fail');
          },
        );

        service.connect();
        async.flushMicrotasks();
        expect(service.connectionState, WsConnectionState.reconnecting);

        service.disconnect();
        async.flushMicrotasks();
        expect(service.connectionState, WsConnectionState.disconnected);

        async.elapse(const Duration(seconds: 60));
        expect(connectCount, 1);
      });
    });

    // === 場景 5: 重連成功重置退避 ===

    /// TC-07-10: 重連成功後退避重置
    test('TC-07-10: 重連成功後退避重置', () {
      fakeAsync((async) {
        final result = setUpWithMultipleConnections(failCount: 3);

        service.connect();
        async.flushMicrotasks(); // 1st fail
        async.elapse(const Duration(seconds: 1)); // 2nd fail
        async.elapse(const Duration(seconds: 2)); // 3rd fail
        async.elapse(const Duration(seconds: 4)); // 4th success

        expect(service.connectionState, WsConnectionState.connected);
        expect(result.sinks, isNotEmpty);

        final sent = _lastSentJson(result.sinks.last);
        expect(sent['action'], WebSocketConstants.actionGetSessionList);
      });
    });

    // === 場景 6: 訊息解析 ===

    /// TC-07-11: 收到有效 session_list JSON
    test('TC-07-11: 收到有效 session_list JSON', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();
        expect(service.connectionState, WsConnectionState.connected);

        final messages = <ServerMessage>[];
        service.messageStream.listen(messages.add);

        serverStreamController.add(_sessionListJson);
        async.flushMicrotasks();

        expect(messages, hasLength(1));
        expect(messages.first.type, 'session_list');
      });
    });

    /// TC-07-12: 收到有效 error JSON
    test('TC-07-12: 收到有效 error JSON', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();

        final messages = <ServerMessage>[];
        service.messageStream.listen(messages.add);

        serverStreamController.add(_errorJson);
        async.flushMicrotasks();

        expect(messages, hasLength(1));
        expect(messages.first.type, 'error');
        expect(messages.first.data['code'], 'SESSION_NOT_FOUND');
      });
    });

    // === 場景 7: JSON 解析失敗 ===

    /// TC-07-13: 收到無效 JSON 不中斷連線
    test('TC-07-13: 收到無效 JSON 不中斷連線', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();

        final messages = <ServerMessage>[];
        service.messageStream.listen(messages.add);

        serverStreamController.add(_invalidJson);
        async.flushMicrotasks();

        expect(messages, isEmpty);
        expect(service.connectionState, WsConnectionState.connected);
      });
    });

    /// TC-07-14: 無效 JSON 後仍可接收有效訊息
    test('TC-07-14: 無效 JSON 後仍可接收有效訊息', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();

        final messages = <ServerMessage>[];
        service.messageStream.listen(messages.add);

        serverStreamController.add(_invalidJson);
        async.flushMicrotasks();
        expect(messages, isEmpty);

        serverStreamController.add(_sessionListJson);
        async.flushMicrotasks();

        expect(messages, hasLength(1));
        expect(messages.first.type, 'session_list');
      });
    });

    // === 場景 8: 心跳超時偵測 ===

    /// TC-07-15: 35 秒無訊息觸發重連
    test('TC-07-15: 35 秒無訊息觸發重連', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();
        expect(service.connectionState, WsConnectionState.connected);

        async.elapse(const Duration(seconds: 35));

        expect(service.connectionState, WsConnectionState.reconnecting);
      });
    });

    /// TC-07-16: 收到訊息重置 inactivity timer
    test('TC-07-16: 收到訊息重置 inactivity timer', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();

        // 30 秒後收到訊息
        async.elapse(const Duration(seconds: 30));
        serverStreamController.add(_sessionListJson);
        async.flushMicrotasks();

        // 再等 34 秒（距離上次訊息 34s < 35s）
        async.elapse(const Duration(seconds: 34));

        expect(service.connectionState, WsConnectionState.connected);
      });
    });

    /// TC-07-17: 訊息恰好在 35 秒邊界到達
    test('TC-07-17: 訊息恰好在 35 秒邊界到達', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();

        async.elapse(
          const Duration(seconds: 34, milliseconds: 999),
        );
        serverStreamController.add(_sessionListJson);
        async.flushMicrotasks();

        async.elapse(
          const Duration(seconds: 34, milliseconds: 999),
        );

        expect(service.connectionState, WsConnectionState.connected);
      });
    });

    // === 場景 9: 連線狀態完整轉換序列 ===

    /// TC-07-18: 完整狀態轉換序列
    test('TC-07-18: 完整狀態轉換序列', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        final states = <WsConnectionState>[];
        service.connectionStateStream.listen(states.add);

        // 1. connect 成功
        service.connect();
        async.flushMicrotasks();

        // 2. 模擬斷線（stream done）
        serverStreamController.close();
        async.flushMicrotasks();

        // 3. disconnect 停止重連
        service.disconnect();
        async.flushMicrotasks();

        expect(states, [
          WsConnectionState.connecting,
          WsConnectionState.connected,
          WsConnectionState.reconnecting,
          WsConnectionState.disconnected,
        ]);
      });
    });

    // === 場景 10: Client 訊息發送 ===

    /// TC-07-19: subscribeSession 發送正確 JSON
    test('TC-07-19: subscribeSession 發送正確 JSON', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();
        expect(service.connectionState, WsConnectionState.connected);

        fakeSink.addedMessages.clear();
        service.subscribeSession('session-123');

        final sent = _lastSentJson(fakeSink);
        expect(sent['action'], WebSocketConstants.actionSubscribeSession);
        expect(sent['sessionId'], 'session-123');
      });
    });

    /// TC-07-20: unsubscribeSession 發送正確 JSON
    test('TC-07-20: unsubscribeSession 發送正確 JSON', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();

        fakeSink.addedMessages.clear();
        service.unsubscribeSession('session-456');

        final sent = _lastSentJson(fakeSink);
        expect(sent['action'], WebSocketConstants.actionUnsubscribeSession);
        expect(sent['sessionId'], 'session-456');
      });
    });

    /// TC-07-21: requestSessionHistory 含可選參數
    test('TC-07-21: requestSessionHistory 含可選參數', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();

        fakeSink.addedMessages.clear();
        service.requestSessionHistory('s1', limit: 50, before: 'cursor-1');

        final sent = _lastSentJson(fakeSink);
        expect(sent['action'], WebSocketConstants.actionGetSessionHistory);
        expect(sent['sessionId'], 's1');
        expect(sent['limit'], 50);
        expect(sent['before'], 'cursor-1');
      });
    });

    /// TC-07-22: requestSessionHistory 無可選參數時使用預設值
    test('TC-07-22: requestSessionHistory 無可選參數時使用預設值', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();

        fakeSink.addedMessages.clear();
        service.requestSessionHistory('s1');

        final sent = _lastSentJson(fakeSink);
        expect(sent['action'], WebSocketConstants.actionGetSessionHistory);
        expect(sent['sessionId'], 's1');
        expect(sent['limit'], 0);
        expect(sent['before'], '');
      });
    });

    /// TC-07-23: 未連線時 send 不拋例外
    test('TC-07-23: 未連線時 send 不拋例外', () {
      service = WebSocketServiceImpl(
        channelFactory: (_) => throw Exception('fail'),
      );

      expect(
        () => service.send(
          const ClientMessage(action: WebSocketConstants.actionGetSessionList),
        ),
        returnsNormally,
      );
    });

    // === 場景 11: dispose 後操作安全 ===

    /// TC-07-24: dispose 後 connect 被忽略
    test('TC-07-24: dispose 後 connect 被忽略', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.dispose();

        service.connect();
        async.flushMicrotasks();

        expect(service.connectionState, WsConnectionState.disconnected);
      });
    });

    /// TC-07-25: dispose 後 send 被忽略
    test('TC-07-25: dispose 後 send 被忽略', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();
        service.dispose();

        expect(
          () => service.send(
            const ClientMessage(
              action: WebSocketConstants.actionGetSessionList,
            ),
          ),
          returnsNormally,
        );
      });
    });

    /// TC-07-26: dispose 關閉所有 StreamController
    test('TC-07-26: dispose 關閉所有 StreamController', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();

        var stateStreamDone = false;
        var messageStreamDone = false;
        service.connectionStateStream.listen(
          null,
          onDone: () => stateStreamDone = true,
        );
        service.messageStream.listen(
          null,
          onDone: () => messageStreamDone = true,
        );

        service.dispose();
        async.flushMicrotasks();

        expect(stateStreamDone, isTrue);
        expect(messageStreamDone, isTrue);
      });
    });

    // === 額外邊界測試 ===

    /// TC-07-27: 重連過程中再次呼叫 connect 使用新 URI
    test('TC-07-27: 重連過程中再次呼叫 connect 使用新 URI', () {
      fakeAsync((async) {
        Uri? lastConnectedUri;
        var callCount = 0;

        service = WebSocketServiceImpl(
          channelFactory: (uri) {
            callCount++;
            lastConnectedUri = uri;
            if (callCount == 1) {
              throw Exception('fail');
            }
            final mock = _createMockChannel();
            mockChannel = mock.channel;
            fakeSink = mock.sink;
            serverStreamController = mock.streamController;
            return mock.channel;
          },
        );

        service.connect();
        async.flushMicrotasks();
        expect(service.connectionState, WsConnectionState.reconnecting);

        final newUri = Uri.parse('ws://other:9999/ws');
        service.connect(uri: newUri);
        async.flushMicrotasks();

        expect(lastConnectedUri, newUri);
        expect(service.connectionState, WsConnectionState.connected);
      });
    });

    /// TC-07-28: 連線中途斷開觸發重連
    test('TC-07-28: 連線中途斷開觸發重連', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();
        expect(service.connectionState, WsConnectionState.connected);

        serverStreamController.close();
        async.flushMicrotasks();

        expect(service.connectionState, WsConnectionState.reconnecting);
      });
    });

    /// TC-07-29: dispose 後不觸發重連
    test('TC-07-29: dispose 後不觸發重連', () {
      fakeAsync((async) {
        setUpWithSuccessfulConnection();
        service.connect();
        async.flushMicrotasks();

        service.dispose();
        serverStreamController.close();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 60));
        // 不應拋異常，不應有重連
      });
    });
  });
}
