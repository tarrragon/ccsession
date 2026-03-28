import 'package:equatable/equatable.dart';

/// 需求：對應 Go SessionEvent struct（models.go）
/// 約束：JSON key 與 Go json tag 一致
class SessionEvent extends Equatable {
  const SessionEvent({
    required this.sessionId,
    this.projectPath = '',
    this.type = '',
    this.timestamp,
    this.messageId = '',
    this.contentIndex = -1,
    this.isLastContent = false,
    this.content = const EventContent(),
    this.toolName = '',
  });

  final String sessionId;
  final String projectPath;
  final String type;
  final DateTime? timestamp;
  final String messageId;
  final int contentIndex;
  final bool isLastContent;
  final EventContent content;
  final String toolName;

  /// 需求：判斷是否為完整的 SessionEvent（JSONL 來源）
  /// 約束：fallback 格式（Hook 來源）只有 sessionId/agentId，缺少 type/content
  bool get isComplete => type.isNotEmpty && timestamp != null;

  factory SessionEvent.fromJson(Map<String, dynamic> json) {
    return SessionEvent(
      sessionId: json['sessionId'] as String? ?? '',
      projectPath: json['projectPath'] as String? ?? '',
      type: json['type'] as String? ?? '',
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      messageId: json['messageId'] as String? ?? '',
      contentIndex: json['contentIndex'] as int? ?? -1,
      isLastContent: json['isLastContent'] as bool? ?? false,
      content: json['content'] == null
          ? const EventContent()
          : EventContent.fromJson(json['content'] as Map<String, dynamic>),
      toolName: json['toolName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'projectPath': projectPath,
        'type': type,
        'timestamp': timestamp?.toIso8601String(),
        'messageId': messageId,
        'contentIndex': contentIndex,
        'isLastContent': isLastContent,
        'content': content.toJson(),
        'toolName': toolName,
      };

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

  factory EventContent.fromJson(Map<String, dynamic> json) {
    return EventContent(
      text: json['text'] as String? ?? '',
      toolName: json['toolName'] as String? ?? '',
      toolInput: json['toolInput'],
      toolUseId: json['toolUseId'] as String? ?? '',
      output: json['output'] as String? ?? '',
      isError: json['isError'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'toolName': toolName,
        'toolInput': toolInput,
        'toolUseId': toolUseId,
        'output': output,
        'isError': isError,
      };

  @override
  List<Object?> get props =>
      [text, toolName, toolInput, toolUseId, output, isError];
}
