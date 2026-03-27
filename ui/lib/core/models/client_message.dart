import 'package:equatable/equatable.dart';

/// 需求：Client -> Server 訊息，對應 Go ClientMessage struct
/// 約束：JSON key 與 Go json tag 一致（camelCase）
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

  factory ClientMessage.fromJson(Map<String, dynamic> json) {
    return ClientMessage(
      action: json['action'] as String,
      sessionId: (json['sessionId'] as String?) ?? '',
      limit: (json['limit'] as int?) ?? 0,
      before: (json['before'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'action': action,
        'sessionId': sessionId,
        'limit': limit,
        'before': before,
      };

  @override
  List<Object?> get props => [action, sessionId, limit, before];
}
