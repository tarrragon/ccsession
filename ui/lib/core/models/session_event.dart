import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_event.g.dart';

/// 需求：對應 Go SessionEvent struct（models.go）
/// 約束：JSON key 與 Go json tag 一致
@JsonSerializable()
class SessionEvent extends Equatable {
  const SessionEvent({
    required this.sessionId,
    this.projectPath = '',
    required this.type,
    required this.timestamp,
    this.messageId = '',
    this.contentIndex = -1,
    this.isLastContent = false,
    required this.content,
    this.toolName = '',
  });

  final String sessionId;
  final String projectPath;
  final String type;
  final DateTime timestamp;
  final String messageId;
  final int contentIndex;
  final bool isLastContent;
  final EventContent content;
  final String toolName;

  factory SessionEvent.fromJson(Map<String, dynamic> json) =>
      _$SessionEventFromJson(json);

  Map<String, dynamic> toJson() => _$SessionEventToJson(this);

  @override
  List<Object?> get props => [
        sessionId,
        projectPath,
        type,
        timestamp,
        messageId,
        contentIndex,
        isLastContent,
        content,
        toolName,
      ];
}

/// 需求：對應 Go EventContent struct（models.go）
/// 約束：toolInput 在 Go 側為 any，Dart 側對應 Object?
@JsonSerializable()
class EventContent extends Equatable {
  const EventContent({
    this.text = '',
    this.toolName = '',
    this.toolInput,
    this.toolUseId = '',
    this.output = '',
    this.isError = false,
  });

  final String text;
  final String toolName;
  final Object? toolInput;
  final String toolUseId;
  final String output;
  final bool isError;

  factory EventContent.fromJson(Map<String, dynamic> json) =>
      _$EventContentFromJson(json);

  Map<String, dynamic> toJson() => _$EventContentToJson(this);

  @override
  List<Object?> get props => [text, toolName, toolInput, toolUseId, output, isError];
}
