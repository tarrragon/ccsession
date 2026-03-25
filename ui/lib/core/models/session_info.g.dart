// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionInfo _$SessionInfoFromJson(Map<String, dynamic> json) => _SessionInfo(
  id: json['id'] as String,
  projectPath: json['projectPath'] as String,
  summary: json['summary'] as String? ?? '',
  status: $enumDecode(_$SessionStatusEnumMap, json['status']),
  firstEventAt: DateTime.parse(json['firstEventAt'] as String),
  lastEventAt: DateTime.parse(json['lastEventAt'] as String),
  firstUserMessageAt: json['firstUserMessageAt'] == null
      ? null
      : DateTime.parse(json['firstUserMessageAt'] as String),
  eventCount: (json['eventCount'] as num?)?.toInt() ?? 0,
  agentId: json['agentId'] as String? ?? '',
  agentType: json['agentType'] as String? ?? '',
  lastMessage: json['lastMessage'] as String? ?? '',
  parentAgentId: json['parentAgentId'] as String? ?? '',
  agentName: json['agentName'] as String? ?? '',
);

Map<String, dynamic> _$SessionInfoToJson(_SessionInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectPath': instance.projectPath,
      'summary': instance.summary,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'firstEventAt': instance.firstEventAt.toIso8601String(),
      'lastEventAt': instance.lastEventAt.toIso8601String(),
      'firstUserMessageAt': instance.firstUserMessageAt?.toIso8601String(),
      'eventCount': instance.eventCount,
      'agentId': instance.agentId,
      'agentType': instance.agentType,
      'lastMessage': instance.lastMessage,
      'parentAgentId': instance.parentAgentId,
      'agentName': instance.agentName,
    };

const _$SessionStatusEnumMap = {
  SessionStatus.active: 'active',
  SessionStatus.idle: 'idle',
  SessionStatus.completed: 'completed',
};
