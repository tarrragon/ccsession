import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_info.g.dart';

/// 需求：對應 Go SessionInfo struct（session_registry_models.go）
/// 約束：JSON key 必須與 Go json tag 完全一致（camelCase）
@JsonSerializable()
class SessionInfo extends Equatable {
  const SessionInfo({
    required this.id,
    required this.projectPath,
    this.summary = '',
    required this.status,
    required this.firstEventAt,
    required this.lastEventAt,
    this.firstUserMessageAt,
    this.eventCount = 0,
    this.agentId = '',
    this.agentType = '',
    this.lastMessage = '',
    this.parentAgentId = '',
    this.agentName = '',
  });

  final String id;
  final String projectPath;
  final String summary;
  final SessionStatus status;
  final DateTime firstEventAt;
  final DateTime lastEventAt;
  final DateTime? firstUserMessageAt;
  final int eventCount;
  final String agentId;
  final String agentType;
  final String lastMessage;
  final String parentAgentId;
  final String agentName;

  factory SessionInfo.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SessionInfoToJson(this);

  SessionInfo copyWith({
    String? id,
    String? projectPath,
    String? summary,
    SessionStatus? status,
    DateTime? firstEventAt,
    DateTime? lastEventAt,
    DateTime? firstUserMessageAt,
    int? eventCount,
    String? agentId,
    String? agentType,
    String? lastMessage,
    String? parentAgentId,
    String? agentName,
  }) {
    return SessionInfo(
      id: id ?? this.id,
      projectPath: projectPath ?? this.projectPath,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      firstEventAt: firstEventAt ?? this.firstEventAt,
      lastEventAt: lastEventAt ?? this.lastEventAt,
      firstUserMessageAt: firstUserMessageAt ?? this.firstUserMessageAt,
      eventCount: eventCount ?? this.eventCount,
      agentId: agentId ?? this.agentId,
      agentType: agentType ?? this.agentType,
      lastMessage: lastMessage ?? this.lastMessage,
      parentAgentId: parentAgentId ?? this.parentAgentId,
      agentName: agentName ?? this.agentName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectPath,
        summary,
        status,
        firstEventAt,
        lastEventAt,
        firstUserMessageAt,
        eventCount,
        agentId,
        agentType,
        lastMessage,
        parentAgentId,
        agentName,
      ];
}

/// 對應 Go SessionStatus（session_registry_constants.go）
enum SessionStatus {
  @JsonValue('active')
  active,

  @JsonValue('idle')
  idle,

  @JsonValue('completed')
  completed,
}
