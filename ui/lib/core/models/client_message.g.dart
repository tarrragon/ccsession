// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClientMessage _$ClientMessageFromJson(Map<String, dynamic> json) =>
    _ClientMessage(
      action: json['action'] as String,
      sessionId: json['sessionId'] as String? ?? '',
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      before: json['before'] as String? ?? '',
    );

Map<String, dynamic> _$ClientMessageToJson(_ClientMessage instance) =>
    <String, dynamic>{
      'action': instance.action,
      'sessionId': instance.sessionId,
      'limit': instance.limit,
      'before': instance.before,
    };
