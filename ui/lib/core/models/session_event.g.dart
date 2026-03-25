// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionEvent _$SessionEventFromJson(Map<String, dynamic> json) =>
    _SessionEvent(
      sessionId: json['sessionId'] as String,
      projectPath: json['projectPath'] as String? ?? '',
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      messageId: json['messageId'] as String? ?? '',
      contentIndex: (json['contentIndex'] as num?)?.toInt() ?? -1,
      isLastContent: json['isLastContent'] as bool? ?? false,
      content: EventContent.fromJson(json['content'] as Map<String, dynamic>),
      toolName: json['toolName'] as String? ?? '',
    );

Map<String, dynamic> _$SessionEventToJson(_SessionEvent instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'projectPath': instance.projectPath,
      'type': instance.type,
      'timestamp': instance.timestamp.toIso8601String(),
      'messageId': instance.messageId,
      'contentIndex': instance.contentIndex,
      'isLastContent': instance.isLastContent,
      'content': instance.content.toJson(),
      'toolName': instance.toolName,
    };

_EventContent _$EventContentFromJson(Map<String, dynamic> json) =>
    _EventContent(
      text: json['text'] as String? ?? '',
      toolName: json['toolName'] as String? ?? '',
      toolInput: json['toolInput'],
      toolUseId: json['toolUseId'] as String? ?? '',
      output: json['output'] as String? ?? '',
      isError: json['isError'] as bool? ?? false,
    );

Map<String, dynamic> _$EventContentToJson(_EventContent instance) =>
    <String, dynamic>{
      'text': instance.text,
      'toolName': instance.toolName,
      'toolInput': instance.toolInput,
      'toolUseId': instance.toolUseId,
      'output': instance.output,
      'isError': instance.isError,
    };
