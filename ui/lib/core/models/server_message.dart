import 'package:equatable/equatable.dart';

import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/core/models/session_info.dart';

/// 需求：Server -> Client 訊息信封
/// 約束：data 為 raw Map，消費端依 type 選擇 payload 類別解析
class ServerMessage extends Equatable {
  const ServerMessage({
    required this.type,
    required this.data,
  });

  final String type;
  final Map<String, dynamic> data;

  factory ServerMessage.fromJson(Map<String, dynamic> json) {
    return ServerMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'data': data,
      };

  @override
  List<Object?> get props => [type, data];
}

/// session_list payload
class SessionListData extends Equatable {
  const SessionListData({
    required this.sessions,
  });

  final List<SessionInfo> sessions;

  factory SessionListData.fromJson(Map<String, dynamic> json) {
    return SessionListData(
      sessions: (json['sessions'] as List<dynamic>)
          .map((e) => SessionInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sessions': sessions.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [sessions];
}

/// session_event payload
class SessionEventData extends Equatable {
  const SessionEventData({
    required this.sessionId,
    this.agentId = '',
  });

  final String sessionId;
  final String agentId;

  factory SessionEventData.fromJson(Map<String, dynamic> json) {
    return SessionEventData(
      sessionId: json['sessionId'] as String,
      agentId: (json['agentId'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'agentId': agentId,
      };

  @override
  List<Object?> get props => [sessionId, agentId];
}

/// session_status_change payload
/// 需求：[0.2.1-W4-002] session_status_change payload
/// 約束：lastEventAt 為 nullable，向後相容舊版 backend
class SessionStatusChangeData extends Equatable {
  const SessionStatusChangeData({
    required this.sessionId,
    required this.status,
    this.lastEventAt,
  });

  final String sessionId;
  final SessionStatus status;
  final DateTime? lastEventAt;

  factory SessionStatusChangeData.fromJson(Map<String, dynamic> json) {
    final rawLastEventAt = json['lastEventAt'] as String?;
    return SessionStatusChangeData(
      sessionId: json['sessionId'] as String,
      status: SessionStatus.values.byName(json['status'] as String),
      lastEventAt:
          rawLastEventAt != null ? DateTime.parse(rawLastEventAt) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'status': status.name,
        if (lastEventAt != null) 'lastEventAt': lastEventAt!.toIso8601String(),
      };

  @override
  List<Object?> get props => [sessionId, status, lastEventAt];
}

/// session_history payload
class SessionHistoryData extends Equatable {
  const SessionHistoryData({
    required this.sessionId,
    required this.events,
    this.hasMore = false,
  });

  final String sessionId;
  final List<SessionEvent> events;
  final bool hasMore;

  factory SessionHistoryData.fromJson(Map<String, dynamic> json) {
    return SessionHistoryData(
      sessionId: json['sessionId'] as String,
      events: (json['events'] as List<dynamic>)
          .map((e) => SessionEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: (json['hasMore'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'events': events.map((e) => e.toJson()).toList(),
        'hasMore': hasMore,
      };

  @override
  List<Object?> get props => [sessionId, events, hasMore];
}

/// session_update payload（增量：單一 session upsert）
/// 需求：[0.4.0-W2-001.1] 對應 Go SessionUpdateData
class SessionUpdateData extends Equatable {
  const SessionUpdateData({required this.session});

  final SessionInfo session;

  factory SessionUpdateData.fromJson(Map<String, dynamic> json) {
    return SessionUpdateData(
      session: SessionInfo.fromJson(json['session'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {'session': session.toJson()};

  @override
  List<Object?> get props => [session];
}

/// session_remove payload（增量：移除指定 session）
/// 需求：[0.4.0-W2-001.1] 對應 Go SessionRemoveData
class SessionRemoveData extends Equatable {
  const SessionRemoveData({required this.sessionId});

  final String sessionId;

  factory SessionRemoveData.fromJson(Map<String, dynamic> json) {
    return SessionRemoveData(sessionId: json['sessionId'] as String);
  }

  Map<String, dynamic> toJson() => {'sessionId': sessionId};

  @override
  List<Object?> get props => [sessionId];
}

/// error payload
class ErrorData extends Equatable {
  const ErrorData({
    required this.code,
  });

  final String code;

  factory ErrorData.fromJson(Map<String, dynamic> json) {
    return ErrorData(
      code: json['code'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
      };

  @override
  List<Object?> get props => [code];
}
