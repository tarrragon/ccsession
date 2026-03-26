import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/core/models/session_info.dart';

part 'server_message.g.dart';

/// 需求：Server -> Client 訊息信封
/// 約束：data 為 raw Map，消費端依 type 選擇 payload 類別解析
@JsonSerializable()
class ServerMessage extends Equatable {
  const ServerMessage({
    required this.type,
    required this.data,
  });

  final String type;
  final Map<String, dynamic> data;

  factory ServerMessage.fromJson(Map<String, dynamic> json) =>
      _$ServerMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ServerMessageToJson(this);

  @override
  List<Object?> get props => [type, data];
}

/// session_list payload
@JsonSerializable()
class SessionListData extends Equatable {
  const SessionListData({
    required this.sessions,
  });

  final List<SessionInfo> sessions;

  factory SessionListData.fromJson(Map<String, dynamic> json) =>
      _$SessionListDataFromJson(json);

  Map<String, dynamic> toJson() => _$SessionListDataToJson(this);

  @override
  List<Object?> get props => [sessions];
}

/// session_event payload
@JsonSerializable()
class SessionEventData extends Equatable {
  const SessionEventData({
    required this.sessionId,
    this.agentId = '',
  });

  final String sessionId;
  final String agentId;

  factory SessionEventData.fromJson(Map<String, dynamic> json) =>
      _$SessionEventDataFromJson(json);

  Map<String, dynamic> toJson() => _$SessionEventDataToJson(this);

  @override
  List<Object?> get props => [sessionId, agentId];
}

/// session_status_change payload
@JsonSerializable()
class SessionStatusChangeData extends Equatable {
  const SessionStatusChangeData({
    required this.sessionId,
    required this.status,
  });

  final String sessionId;
  final SessionStatus status;

  factory SessionStatusChangeData.fromJson(Map<String, dynamic> json) =>
      _$SessionStatusChangeDataFromJson(json);

  Map<String, dynamic> toJson() => _$SessionStatusChangeDataToJson(this);

  @override
  List<Object?> get props => [sessionId, status];
}

/// session_history payload
@JsonSerializable()
class SessionHistoryData extends Equatable {
  const SessionHistoryData({
    required this.sessionId,
    required this.events,
    this.hasMore = false,
  });

  final String sessionId;
  final List<SessionEvent> events;
  final bool hasMore;

  factory SessionHistoryData.fromJson(Map<String, dynamic> json) =>
      _$SessionHistoryDataFromJson(json);

  Map<String, dynamic> toJson() => _$SessionHistoryDataToJson(this);

  @override
  List<Object?> get props => [sessionId, events, hasMore];
}

/// error payload
@JsonSerializable()
class ErrorData extends Equatable {
  const ErrorData({
    required this.code,
  });

  final String code;

  factory ErrorData.fromJson(Map<String, dynamic> json) =>
      _$ErrorDataFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorDataToJson(this);

  @override
  List<Object?> get props => [code];
}
