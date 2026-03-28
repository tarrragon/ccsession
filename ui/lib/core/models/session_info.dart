import 'package:equatable/equatable.dart';

/// 需求：對應 Go SessionInfo struct（session_registry_models.go）
/// 約束：JSON key 必須與 Go json tag 完全一致（camelCase）
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

  /// 需求：從 Go WebSocket JSON 反序列化為 SessionInfo
  /// 約束：可選欄位缺失時使用建構式預設值
  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      id: json['id'] as String,
      projectPath: json['projectPath'] as String,
      summary: json['summary'] as String? ?? '',
      status: SessionStatus.fromJson(json['status'] as String),
      firstEventAt: DateTime.parse(json['firstEventAt'] as String),
      lastEventAt: DateTime.parse(json['lastEventAt'] as String),
      firstUserMessageAt: json['firstUserMessageAt'] == null
          ? null
          : DateTime.parse(json['firstUserMessageAt'] as String),
      eventCount: json['eventCount'] as int? ?? 0,
      agentId: json['agentId'] as String? ?? '',
      agentType: json['agentType'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      parentAgentId: json['parentAgentId'] as String? ?? '',
      agentName: json['agentName'] as String? ?? '',
    );
  }

  /// 需求：序列化為 JSON，與 Go json tag 一致
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectPath': projectPath,
      'summary': summary,
      'status': status.toJson(),
      'firstEventAt': firstEventAt.toIso8601String(),
      'lastEventAt': lastEventAt.toIso8601String(),
      'firstUserMessageAt': firstUserMessageAt?.toIso8601String(),
      'eventCount': eventCount,
      'agentId': agentId,
      'agentType': agentType,
      'lastMessage': lastMessage,
      'parentAgentId': parentAgentId,
      'agentName': agentName,
    };
  }

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
  active,
  idle,
  completed;

  /// 從 JSON 字串轉換為 enum
  static SessionStatus fromJson(String value) {
    return SessionStatus.values.firstWhere((e) => e.name == value);
  }

  /// 轉換為 JSON 字串
  String toJson() => name;
}
