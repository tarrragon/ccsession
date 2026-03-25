// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionInfo {

 String get id; String get projectPath; String get summary; SessionStatus get status; DateTime get firstEventAt; DateTime get lastEventAt; DateTime? get firstUserMessageAt; int get eventCount; String get agentId; String get agentType; String get lastMessage; String get parentAgentId; String get agentName;
/// Create a copy of SessionInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionInfoCopyWith<SessionInfo> get copyWith => _$SessionInfoCopyWithImpl<SessionInfo>(this as SessionInfo, _$identity);

  /// Serializes this SessionInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.projectPath, projectPath) || other.projectPath == projectPath)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.status, status) || other.status == status)&&(identical(other.firstEventAt, firstEventAt) || other.firstEventAt == firstEventAt)&&(identical(other.lastEventAt, lastEventAt) || other.lastEventAt == lastEventAt)&&(identical(other.firstUserMessageAt, firstUserMessageAt) || other.firstUserMessageAt == firstUserMessageAt)&&(identical(other.eventCount, eventCount) || other.eventCount == eventCount)&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.agentType, agentType) || other.agentType == agentType)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.parentAgentId, parentAgentId) || other.parentAgentId == parentAgentId)&&(identical(other.agentName, agentName) || other.agentName == agentName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,projectPath,summary,status,firstEventAt,lastEventAt,firstUserMessageAt,eventCount,agentId,agentType,lastMessage,parentAgentId,agentName);

@override
String toString() {
  return 'SessionInfo(id: $id, projectPath: $projectPath, summary: $summary, status: $status, firstEventAt: $firstEventAt, lastEventAt: $lastEventAt, firstUserMessageAt: $firstUserMessageAt, eventCount: $eventCount, agentId: $agentId, agentType: $agentType, lastMessage: $lastMessage, parentAgentId: $parentAgentId, agentName: $agentName)';
}


}

/// @nodoc
abstract mixin class $SessionInfoCopyWith<$Res>  {
  factory $SessionInfoCopyWith(SessionInfo value, $Res Function(SessionInfo) _then) = _$SessionInfoCopyWithImpl;
@useResult
$Res call({
 String id, String projectPath, String summary, SessionStatus status, DateTime firstEventAt, DateTime lastEventAt, DateTime? firstUserMessageAt, int eventCount, String agentId, String agentType, String lastMessage, String parentAgentId, String agentName
});




}
/// @nodoc
class _$SessionInfoCopyWithImpl<$Res>
    implements $SessionInfoCopyWith<$Res> {
  _$SessionInfoCopyWithImpl(this._self, this._then);

  final SessionInfo _self;
  final $Res Function(SessionInfo) _then;

/// Create a copy of SessionInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? projectPath = null,Object? summary = null,Object? status = null,Object? firstEventAt = null,Object? lastEventAt = null,Object? firstUserMessageAt = freezed,Object? eventCount = null,Object? agentId = null,Object? agentType = null,Object? lastMessage = null,Object? parentAgentId = null,Object? agentName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectPath: null == projectPath ? _self.projectPath : projectPath // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,firstEventAt: null == firstEventAt ? _self.firstEventAt : firstEventAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastEventAt: null == lastEventAt ? _self.lastEventAt : lastEventAt // ignore: cast_nullable_to_non_nullable
as DateTime,firstUserMessageAt: freezed == firstUserMessageAt ? _self.firstUserMessageAt : firstUserMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,eventCount: null == eventCount ? _self.eventCount : eventCount // ignore: cast_nullable_to_non_nullable
as int,agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,agentType: null == agentType ? _self.agentType : agentType // ignore: cast_nullable_to_non_nullable
as String,lastMessage: null == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as String,parentAgentId: null == parentAgentId ? _self.parentAgentId : parentAgentId // ignore: cast_nullable_to_non_nullable
as String,agentName: null == agentName ? _self.agentName : agentName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionInfo].
extension SessionInfoPatterns on SessionInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionInfo value)  $default,){
final _that = this;
switch (_that) {
case _SessionInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionInfo value)?  $default,){
final _that = this;
switch (_that) {
case _SessionInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String projectPath,  String summary,  SessionStatus status,  DateTime firstEventAt,  DateTime lastEventAt,  DateTime? firstUserMessageAt,  int eventCount,  String agentId,  String agentType,  String lastMessage,  String parentAgentId,  String agentName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionInfo() when $default != null:
return $default(_that.id,_that.projectPath,_that.summary,_that.status,_that.firstEventAt,_that.lastEventAt,_that.firstUserMessageAt,_that.eventCount,_that.agentId,_that.agentType,_that.lastMessage,_that.parentAgentId,_that.agentName);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String projectPath,  String summary,  SessionStatus status,  DateTime firstEventAt,  DateTime lastEventAt,  DateTime? firstUserMessageAt,  int eventCount,  String agentId,  String agentType,  String lastMessage,  String parentAgentId,  String agentName)  $default,) {final _that = this;
switch (_that) {
case _SessionInfo():
return $default(_that.id,_that.projectPath,_that.summary,_that.status,_that.firstEventAt,_that.lastEventAt,_that.firstUserMessageAt,_that.eventCount,_that.agentId,_that.agentType,_that.lastMessage,_that.parentAgentId,_that.agentName);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String projectPath,  String summary,  SessionStatus status,  DateTime firstEventAt,  DateTime lastEventAt,  DateTime? firstUserMessageAt,  int eventCount,  String agentId,  String agentType,  String lastMessage,  String parentAgentId,  String agentName)?  $default,) {final _that = this;
switch (_that) {
case _SessionInfo() when $default != null:
return $default(_that.id,_that.projectPath,_that.summary,_that.status,_that.firstEventAt,_that.lastEventAt,_that.firstUserMessageAt,_that.eventCount,_that.agentId,_that.agentType,_that.lastMessage,_that.parentAgentId,_that.agentName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionInfo implements SessionInfo {
  const _SessionInfo({required this.id, required this.projectPath, this.summary = '', required this.status, required this.firstEventAt, required this.lastEventAt, this.firstUserMessageAt, this.eventCount = 0, this.agentId = '', this.agentType = '', this.lastMessage = '', this.parentAgentId = '', this.agentName = ''});
  factory _SessionInfo.fromJson(Map<String, dynamic> json) => _$SessionInfoFromJson(json);

@override final  String id;
@override final  String projectPath;
@override@JsonKey() final  String summary;
@override final  SessionStatus status;
@override final  DateTime firstEventAt;
@override final  DateTime lastEventAt;
@override final  DateTime? firstUserMessageAt;
@override@JsonKey() final  int eventCount;
@override@JsonKey() final  String agentId;
@override@JsonKey() final  String agentType;
@override@JsonKey() final  String lastMessage;
@override@JsonKey() final  String parentAgentId;
@override@JsonKey() final  String agentName;

/// Create a copy of SessionInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionInfoCopyWith<_SessionInfo> get copyWith => __$SessionInfoCopyWithImpl<_SessionInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.projectPath, projectPath) || other.projectPath == projectPath)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.status, status) || other.status == status)&&(identical(other.firstEventAt, firstEventAt) || other.firstEventAt == firstEventAt)&&(identical(other.lastEventAt, lastEventAt) || other.lastEventAt == lastEventAt)&&(identical(other.firstUserMessageAt, firstUserMessageAt) || other.firstUserMessageAt == firstUserMessageAt)&&(identical(other.eventCount, eventCount) || other.eventCount == eventCount)&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.agentType, agentType) || other.agentType == agentType)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.parentAgentId, parentAgentId) || other.parentAgentId == parentAgentId)&&(identical(other.agentName, agentName) || other.agentName == agentName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,projectPath,summary,status,firstEventAt,lastEventAt,firstUserMessageAt,eventCount,agentId,agentType,lastMessage,parentAgentId,agentName);

@override
String toString() {
  return 'SessionInfo(id: $id, projectPath: $projectPath, summary: $summary, status: $status, firstEventAt: $firstEventAt, lastEventAt: $lastEventAt, firstUserMessageAt: $firstUserMessageAt, eventCount: $eventCount, agentId: $agentId, agentType: $agentType, lastMessage: $lastMessage, parentAgentId: $parentAgentId, agentName: $agentName)';
}


}

/// @nodoc
abstract mixin class _$SessionInfoCopyWith<$Res> implements $SessionInfoCopyWith<$Res> {
  factory _$SessionInfoCopyWith(_SessionInfo value, $Res Function(_SessionInfo) _then) = __$SessionInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String projectPath, String summary, SessionStatus status, DateTime firstEventAt, DateTime lastEventAt, DateTime? firstUserMessageAt, int eventCount, String agentId, String agentType, String lastMessage, String parentAgentId, String agentName
});




}
/// @nodoc
class __$SessionInfoCopyWithImpl<$Res>
    implements _$SessionInfoCopyWith<$Res> {
  __$SessionInfoCopyWithImpl(this._self, this._then);

  final _SessionInfo _self;
  final $Res Function(_SessionInfo) _then;

/// Create a copy of SessionInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? projectPath = null,Object? summary = null,Object? status = null,Object? firstEventAt = null,Object? lastEventAt = null,Object? firstUserMessageAt = freezed,Object? eventCount = null,Object? agentId = null,Object? agentType = null,Object? lastMessage = null,Object? parentAgentId = null,Object? agentName = null,}) {
  return _then(_SessionInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectPath: null == projectPath ? _self.projectPath : projectPath // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,firstEventAt: null == firstEventAt ? _self.firstEventAt : firstEventAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastEventAt: null == lastEventAt ? _self.lastEventAt : lastEventAt // ignore: cast_nullable_to_non_nullable
as DateTime,firstUserMessageAt: freezed == firstUserMessageAt ? _self.firstUserMessageAt : firstUserMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,eventCount: null == eventCount ? _self.eventCount : eventCount // ignore: cast_nullable_to_non_nullable
as int,agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,agentType: null == agentType ? _self.agentType : agentType // ignore: cast_nullable_to_non_nullable
as String,lastMessage: null == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as String,parentAgentId: null == parentAgentId ? _self.parentAgentId : parentAgentId // ignore: cast_nullable_to_non_nullable
as String,agentName: null == agentName ? _self.agentName : agentName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
