import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/models/session_event.dart';

final _baseTime = DateTime(2026, 3, 26, 10, 0);
int _counter = 0;

/// 需求：建構各類型 SessionEvent 的測試工廠
/// 約束：每次呼叫產生唯一 timestamp（遞增），確保排序一致
SessionEvent createTestEvent({
  String type = 'user',
  String sessionId = 'session-1',
  String messageId = '',
  int contentIndex = -1,
  String text = '',
  String toolName = '',
  Object? toolInput,
  String toolUseId = '',
  String output = '',
  bool isError = false,
  DateTime? timestamp,
}) {
  _counter++;
  return SessionEvent(
    sessionId: sessionId,
    type: type,
    messageId: messageId,
    contentIndex: contentIndex,
    timestamp: timestamp ?? _baseTime.add(Duration(seconds: _counter)),
    content: EventContent(
      text: text,
      toolName: toolName,
      toolInput: toolInput,
      toolUseId: toolUseId,
      output: output,
      isError: isError,
    ),
  );
}

SessionEvent createUserEvent(String text, {String sessionId = 'session-1'}) {
  return createTestEvent(type: 'user', text: text, sessionId: sessionId);
}

SessionEvent createAssistantEvent(
  String text, {
  String sessionId = 'session-1',
}) {
  return createTestEvent(type: 'assistant', text: text, sessionId: sessionId);
}

SessionEvent createToolUseEvent(
  String toolName, {
  Object? input,
  String sessionId = 'session-1',
  String messageId = '',
  int contentIndex = -1,
}) {
  return createTestEvent(
    type: 'tool_use',
    toolName: toolName,
    toolInput: input,
    sessionId: sessionId,
    messageId: messageId,
    contentIndex: contentIndex,
  );
}

SessionEvent createToolResultEvent({
  String output = '',
  bool isError = false,
  String sessionId = 'session-1',
  String messageId = '',
  int contentIndex = -1,
}) {
  return createTestEvent(
    type: 'tool_result',
    output: output,
    isError: isError,
    sessionId: sessionId,
    messageId: messageId,
    contentIndex: contentIndex,
  );
}

SessionEvent createThinkingEvent(
  String text, {
  String sessionId = 'session-1',
}) {
  return createTestEvent(type: 'thinking', text: text, sessionId: sessionId);
}

/// 需求：建構 session_history ServerMessage
ServerMessage createSessionHistoryMessage(
  String sessionId,
  List<SessionEvent> events, {
  bool hasMore = false,
}) {
  return ServerMessage(
    type: 'session_history',
    data: {
      'sessionId': sessionId,
      'events': events.map((e) => e.toJson()).toList(),
      'hasMore': hasMore,
    },
  );
}

/// 需求：建構 session_event ServerMessage
ServerMessage createSessionEventMessage(SessionEvent event) {
  return ServerMessage(
    type: 'session_event',
    data: event.toJson(),
  );
}

/// 需求：建構 error ServerMessage
ServerMessage createErrorMessage(String code) {
  return ServerMessage(
    type: 'error',
    data: {'code': code},
  );
}
