import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_info.freezed.dart';
part 'session_info.g.dart';

/// 需求：對應 Go SessionInfo struct（session_registry_models.go）
/// 約束：JSON key 必須與 Go json tag 完全一致（camelCase）
@freezed
abstract class SessionInfo with _$SessionInfo {
  const factory SessionInfo({
    required String id,
    required String projectPath,
    @Default('') String summary,
    required SessionStatus status,
    required DateTime firstEventAt,
    required DateTime lastEventAt,
    DateTime? firstUserMessageAt,
    @Default(0) int eventCount,
    @Default('') String agentId,
    @Default('') String agentType,
    @Default('') String lastMessage,
    @Default('') String parentAgentId,
    @Default('') String agentName,
  }) = _SessionInfo;

  factory SessionInfo.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoFromJson(json);
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
