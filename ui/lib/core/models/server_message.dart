import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/core/models/session_info.dart';

part 'server_message.freezed.dart';
part 'server_message.g.dart';

/// 需求：Server -> Client 訊息信封
/// 約束：data 為 raw Map，消費端依 type 選擇 payload 類別解析
@freezed
abstract class ServerMessage with _$ServerMessage {
  const factory ServerMessage({
    required String type,
    required Map<String, dynamic> data,
  }) = _ServerMessage;

  factory ServerMessage.fromJson(Map<String, dynamic> json) =>
      _$ServerMessageFromJson(json);
}

/// session_list payload
@freezed
abstract class SessionListData with _$SessionListData {
  const factory SessionListData({
    required List<SessionInfo> sessions,
  }) = _SessionListData;

  factory SessionListData.fromJson(Map<String, dynamic> json) =>
      _$SessionListDataFromJson(json);
}

/// session_event payload
@freezed
abstract class SessionEventData with _$SessionEventData {
  const factory SessionEventData({
    required String sessionId,
    @Default('') String agentId,
  }) = _SessionEventData;

  factory SessionEventData.fromJson(Map<String, dynamic> json) =>
      _$SessionEventDataFromJson(json);
}

/// session_status_change payload
@freezed
abstract class SessionStatusChangeData with _$SessionStatusChangeData {
  const factory SessionStatusChangeData({
    required String sessionId,
    required SessionStatus status,
  }) = _SessionStatusChangeData;

  factory SessionStatusChangeData.fromJson(Map<String, dynamic> json) =>
      _$SessionStatusChangeDataFromJson(json);
}

/// session_history payload
@freezed
abstract class SessionHistoryData with _$SessionHistoryData {
  const factory SessionHistoryData({
    required String sessionId,
    required List<SessionEvent> events,
    @Default(false) bool hasMore,
  }) = _SessionHistoryData;

  factory SessionHistoryData.fromJson(Map<String, dynamic> json) =>
      _$SessionHistoryDataFromJson(json);
}

/// error payload
@freezed
abstract class ErrorData with _$ErrorData {
  const factory ErrorData({
    required String code,
  }) = _ErrorData;

  factory ErrorData.fromJson(Map<String, dynamic> json) =>
      _$ErrorDataFromJson(json);
}
