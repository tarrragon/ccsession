import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_message.freezed.dart';
part 'client_message.g.dart';

/// 需求：Client -> Server 訊息，對應 Go ClientMessage struct
/// 約束：JSON key 與 Go json tag 一致
@freezed
abstract class ClientMessage with _$ClientMessage {
  const factory ClientMessage({
    required String action,
    @Default('') String sessionId,
    @Default(0) int limit,
    @Default('') String before,
  }) = _ClientMessage;

  factory ClientMessage.fromJson(Map<String, dynamic> json) =>
      _$ClientMessageFromJson(json);
}
