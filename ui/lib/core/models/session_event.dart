import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_event.freezed.dart';
part 'session_event.g.dart';

/// 需求：對應 Go SessionEvent struct（models.go）
/// 約束：JSON key 與 Go json tag 一致
@freezed
abstract class SessionEvent with _$SessionEvent {
  const factory SessionEvent({
    required String sessionId,
    @Default('') String projectPath,
    required String type,
    required DateTime timestamp,
    @Default('') String messageId,
    @Default(-1) int contentIndex,
    @Default(false) bool isLastContent,
    required EventContent content,
    @Default('') String toolName,
  }) = _SessionEvent;

  factory SessionEvent.fromJson(Map<String, dynamic> json) =>
      _$SessionEventFromJson(json);
}

/// 需求：對應 Go EventContent struct（models.go）
/// 約束：toolInput 在 Go 側為 any，Dart 側對應 Object?
@freezed
abstract class EventContent with _$EventContent {
  const factory EventContent({
    @Default('') String text,
    @Default('') String toolName,
    Object? toolInput,
    @Default('') String toolUseId,
    @Default('') String output,
    @Default(false) bool isError,
  }) = _EventContent;

  factory EventContent.fromJson(Map<String, dynamic> json) =>
      _$EventContentFromJson(json);
}
