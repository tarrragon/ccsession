// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServerMessage _$ServerMessageFromJson(Map<String, dynamic> json) =>
    _ServerMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$ServerMessageToJson(_ServerMessage instance) =>
    <String, dynamic>{'type': instance.type, 'data': instance.data};

_SessionListData _$SessionListDataFromJson(Map<String, dynamic> json) =>
    _SessionListData(
      sessions: (json['sessions'] as List<dynamic>)
          .map((e) => SessionInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SessionListDataToJson(_SessionListData instance) =>
    <String, dynamic>{
      'sessions': instance.sessions.map((e) => e.toJson()).toList(),
    };

_SessionEventData _$SessionEventDataFromJson(Map<String, dynamic> json) =>
    _SessionEventData(
      sessionId: json['sessionId'] as String,
      agentId: json['agentId'] as String? ?? '',
    );

Map<String, dynamic> _$SessionEventDataToJson(_SessionEventData instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'agentId': instance.agentId,
    };

_SessionStatusChangeData _$SessionStatusChangeDataFromJson(
  Map<String, dynamic> json,
) => _SessionStatusChangeData(
  sessionId: json['sessionId'] as String,
  status: $enumDecode(_$SessionStatusEnumMap, json['status']),
);

Map<String, dynamic> _$SessionStatusChangeDataToJson(
  _SessionStatusChangeData instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'status': _$SessionStatusEnumMap[instance.status]!,
};

const _$SessionStatusEnumMap = {
  SessionStatus.active: 'active',
  SessionStatus.idle: 'idle',
  SessionStatus.completed: 'completed',
};

_SessionHistoryData _$SessionHistoryDataFromJson(Map<String, dynamic> json) =>
    _SessionHistoryData(
      sessionId: json['sessionId'] as String,
      events: (json['events'] as List<dynamic>)
          .map((e) => SessionEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['hasMore'] as bool? ?? false,
    );

Map<String, dynamic> _$SessionHistoryDataToJson(_SessionHistoryData instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'events': instance.events.map((e) => e.toJson()).toList(),
      'hasMore': instance.hasMore,
    };

_ErrorData _$ErrorDataFromJson(Map<String, dynamic> json) =>
    _ErrorData(code: json['code'] as String);

Map<String, dynamic> _$ErrorDataToJson(_ErrorData instance) =>
    <String, dynamic>{'code': instance.code};
