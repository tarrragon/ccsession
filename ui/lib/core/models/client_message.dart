import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'client_message.g.dart';

/// 需求：Client -> Server 訊息，對應 Go ClientMessage struct
/// 約束：JSON key 與 Go json tag 一致
@JsonSerializable()
class ClientMessage extends Equatable {
  const ClientMessage({
    required this.action,
    this.sessionId = '',
    this.limit = 0,
    this.before = '',
  });

  final String action;
  final String sessionId;
  final int limit;
  final String before;

  factory ClientMessage.fromJson(Map<String, dynamic> json) =>
      _$ClientMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ClientMessageToJson(this);

  @override
  List<Object?> get props => [action, sessionId, limit, before];
}
