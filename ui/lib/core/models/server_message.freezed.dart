// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'server_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServerMessage {

 String get type; Map<String, dynamic> get data;
/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerMessageCopyWith<ServerMessage> get copyWith => _$ServerMessageCopyWithImpl<ServerMessage>(this as ServerMessage, _$identity);

  /// Serializes this ServerMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerMessage&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'ServerMessage(type: $type, data: $data)';
}


}

/// @nodoc
abstract mixin class $ServerMessageCopyWith<$Res>  {
  factory $ServerMessageCopyWith(ServerMessage value, $Res Function(ServerMessage) _then) = _$ServerMessageCopyWithImpl;
@useResult
$Res call({
 String type, Map<String, dynamic> data
});




}
/// @nodoc
class _$ServerMessageCopyWithImpl<$Res>
    implements $ServerMessageCopyWith<$Res> {
  _$ServerMessageCopyWithImpl(this._self, this._then);

  final ServerMessage _self;
  final $Res Function(ServerMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? data = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ServerMessage].
extension ServerMessagePatterns on ServerMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServerMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServerMessage value)  $default,){
final _that = this;
switch (_that) {
case _ServerMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServerMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ServerMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  Map<String, dynamic> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerMessage() when $default != null:
return $default(_that.type,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  Map<String, dynamic> data)  $default,) {final _that = this;
switch (_that) {
case _ServerMessage():
return $default(_that.type,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  Map<String, dynamic> data)?  $default,) {final _that = this;
switch (_that) {
case _ServerMessage() when $default != null:
return $default(_that.type,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServerMessage implements ServerMessage {
  const _ServerMessage({required this.type, required final  Map<String, dynamic> data}): _data = data;
  factory _ServerMessage.fromJson(Map<String, dynamic> json) => _$ServerMessageFromJson(json);

@override final  String type;
 final  Map<String, dynamic> _data;
@override Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}


/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerMessageCopyWith<_ServerMessage> get copyWith => __$ServerMessageCopyWithImpl<_ServerMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServerMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerMessage&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'ServerMessage(type: $type, data: $data)';
}


}

/// @nodoc
abstract mixin class _$ServerMessageCopyWith<$Res> implements $ServerMessageCopyWith<$Res> {
  factory _$ServerMessageCopyWith(_ServerMessage value, $Res Function(_ServerMessage) _then) = __$ServerMessageCopyWithImpl;
@override @useResult
$Res call({
 String type, Map<String, dynamic> data
});




}
/// @nodoc
class __$ServerMessageCopyWithImpl<$Res>
    implements _$ServerMessageCopyWith<$Res> {
  __$ServerMessageCopyWithImpl(this._self, this._then);

  final _ServerMessage _self;
  final $Res Function(_ServerMessage) _then;

/// Create a copy of ServerMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? data = null,}) {
  return _then(_ServerMessage(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$SessionListData {

 List<SessionInfo> get sessions;
/// Create a copy of SessionListData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionListDataCopyWith<SessionListData> get copyWith => _$SessionListDataCopyWithImpl<SessionListData>(this as SessionListData, _$identity);

  /// Serializes this SessionListData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionListData&&const DeepCollectionEquality().equals(other.sessions, sessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(sessions));

@override
String toString() {
  return 'SessionListData(sessions: $sessions)';
}


}

/// @nodoc
abstract mixin class $SessionListDataCopyWith<$Res>  {
  factory $SessionListDataCopyWith(SessionListData value, $Res Function(SessionListData) _then) = _$SessionListDataCopyWithImpl;
@useResult
$Res call({
 List<SessionInfo> sessions
});




}
/// @nodoc
class _$SessionListDataCopyWithImpl<$Res>
    implements $SessionListDataCopyWith<$Res> {
  _$SessionListDataCopyWithImpl(this._self, this._then);

  final SessionListData _self;
  final $Res Function(SessionListData) _then;

/// Create a copy of SessionListData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessions = null,}) {
  return _then(_self.copyWith(
sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as List<SessionInfo>,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionListData].
extension SessionListDataPatterns on SessionListData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionListData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionListData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionListData value)  $default,){
final _that = this;
switch (_that) {
case _SessionListData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionListData value)?  $default,){
final _that = this;
switch (_that) {
case _SessionListData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SessionInfo> sessions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionListData() when $default != null:
return $default(_that.sessions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SessionInfo> sessions)  $default,) {final _that = this;
switch (_that) {
case _SessionListData():
return $default(_that.sessions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SessionInfo> sessions)?  $default,) {final _that = this;
switch (_that) {
case _SessionListData() when $default != null:
return $default(_that.sessions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionListData implements SessionListData {
  const _SessionListData({required final  List<SessionInfo> sessions}): _sessions = sessions;
  factory _SessionListData.fromJson(Map<String, dynamic> json) => _$SessionListDataFromJson(json);

 final  List<SessionInfo> _sessions;
@override List<SessionInfo> get sessions {
  if (_sessions is EqualUnmodifiableListView) return _sessions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sessions);
}


/// Create a copy of SessionListData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionListDataCopyWith<_SessionListData> get copyWith => __$SessionListDataCopyWithImpl<_SessionListData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionListDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionListData&&const DeepCollectionEquality().equals(other._sessions, _sessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_sessions));

@override
String toString() {
  return 'SessionListData(sessions: $sessions)';
}


}

/// @nodoc
abstract mixin class _$SessionListDataCopyWith<$Res> implements $SessionListDataCopyWith<$Res> {
  factory _$SessionListDataCopyWith(_SessionListData value, $Res Function(_SessionListData) _then) = __$SessionListDataCopyWithImpl;
@override @useResult
$Res call({
 List<SessionInfo> sessions
});




}
/// @nodoc
class __$SessionListDataCopyWithImpl<$Res>
    implements _$SessionListDataCopyWith<$Res> {
  __$SessionListDataCopyWithImpl(this._self, this._then);

  final _SessionListData _self;
  final $Res Function(_SessionListData) _then;

/// Create a copy of SessionListData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessions = null,}) {
  return _then(_SessionListData(
sessions: null == sessions ? _self._sessions : sessions // ignore: cast_nullable_to_non_nullable
as List<SessionInfo>,
  ));
}


}


/// @nodoc
mixin _$SessionEventData {

 String get sessionId; String get agentId;
/// Create a copy of SessionEventData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionEventDataCopyWith<SessionEventData> get copyWith => _$SessionEventDataCopyWithImpl<SessionEventData>(this as SessionEventData, _$identity);

  /// Serializes this SessionEventData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionEventData&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.agentId, agentId) || other.agentId == agentId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,agentId);

@override
String toString() {
  return 'SessionEventData(sessionId: $sessionId, agentId: $agentId)';
}


}

/// @nodoc
abstract mixin class $SessionEventDataCopyWith<$Res>  {
  factory $SessionEventDataCopyWith(SessionEventData value, $Res Function(SessionEventData) _then) = _$SessionEventDataCopyWithImpl;
@useResult
$Res call({
 String sessionId, String agentId
});




}
/// @nodoc
class _$SessionEventDataCopyWithImpl<$Res>
    implements $SessionEventDataCopyWith<$Res> {
  _$SessionEventDataCopyWithImpl(this._self, this._then);

  final SessionEventData _self;
  final $Res Function(SessionEventData) _then;

/// Create a copy of SessionEventData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? agentId = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionEventData].
extension SessionEventDataPatterns on SessionEventData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionEventData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionEventData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionEventData value)  $default,){
final _that = this;
switch (_that) {
case _SessionEventData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionEventData value)?  $default,){
final _that = this;
switch (_that) {
case _SessionEventData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  String agentId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionEventData() when $default != null:
return $default(_that.sessionId,_that.agentId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  String agentId)  $default,) {final _that = this;
switch (_that) {
case _SessionEventData():
return $default(_that.sessionId,_that.agentId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  String agentId)?  $default,) {final _that = this;
switch (_that) {
case _SessionEventData() when $default != null:
return $default(_that.sessionId,_that.agentId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionEventData implements SessionEventData {
  const _SessionEventData({required this.sessionId, this.agentId = ''});
  factory _SessionEventData.fromJson(Map<String, dynamic> json) => _$SessionEventDataFromJson(json);

@override final  String sessionId;
@override@JsonKey() final  String agentId;

/// Create a copy of SessionEventData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionEventDataCopyWith<_SessionEventData> get copyWith => __$SessionEventDataCopyWithImpl<_SessionEventData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionEventDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionEventData&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.agentId, agentId) || other.agentId == agentId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,agentId);

@override
String toString() {
  return 'SessionEventData(sessionId: $sessionId, agentId: $agentId)';
}


}

/// @nodoc
abstract mixin class _$SessionEventDataCopyWith<$Res> implements $SessionEventDataCopyWith<$Res> {
  factory _$SessionEventDataCopyWith(_SessionEventData value, $Res Function(_SessionEventData) _then) = __$SessionEventDataCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, String agentId
});




}
/// @nodoc
class __$SessionEventDataCopyWithImpl<$Res>
    implements _$SessionEventDataCopyWith<$Res> {
  __$SessionEventDataCopyWithImpl(this._self, this._then);

  final _SessionEventData _self;
  final $Res Function(_SessionEventData) _then;

/// Create a copy of SessionEventData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? agentId = null,}) {
  return _then(_SessionEventData(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,agentId: null == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SessionStatusChangeData {

 String get sessionId; SessionStatus get status;
/// Create a copy of SessionStatusChangeData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionStatusChangeDataCopyWith<SessionStatusChangeData> get copyWith => _$SessionStatusChangeDataCopyWithImpl<SessionStatusChangeData>(this as SessionStatusChangeData, _$identity);

  /// Serializes this SessionStatusChangeData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionStatusChangeData&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,status);

@override
String toString() {
  return 'SessionStatusChangeData(sessionId: $sessionId, status: $status)';
}


}

/// @nodoc
abstract mixin class $SessionStatusChangeDataCopyWith<$Res>  {
  factory $SessionStatusChangeDataCopyWith(SessionStatusChangeData value, $Res Function(SessionStatusChangeData) _then) = _$SessionStatusChangeDataCopyWithImpl;
@useResult
$Res call({
 String sessionId, SessionStatus status
});




}
/// @nodoc
class _$SessionStatusChangeDataCopyWithImpl<$Res>
    implements $SessionStatusChangeDataCopyWith<$Res> {
  _$SessionStatusChangeDataCopyWithImpl(this._self, this._then);

  final SessionStatusChangeData _self;
  final $Res Function(SessionStatusChangeData) _then;

/// Create a copy of SessionStatusChangeData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? status = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionStatusChangeData].
extension SessionStatusChangeDataPatterns on SessionStatusChangeData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionStatusChangeData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionStatusChangeData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionStatusChangeData value)  $default,){
final _that = this;
switch (_that) {
case _SessionStatusChangeData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionStatusChangeData value)?  $default,){
final _that = this;
switch (_that) {
case _SessionStatusChangeData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  SessionStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionStatusChangeData() when $default != null:
return $default(_that.sessionId,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  SessionStatus status)  $default,) {final _that = this;
switch (_that) {
case _SessionStatusChangeData():
return $default(_that.sessionId,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  SessionStatus status)?  $default,) {final _that = this;
switch (_that) {
case _SessionStatusChangeData() when $default != null:
return $default(_that.sessionId,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionStatusChangeData implements SessionStatusChangeData {
  const _SessionStatusChangeData({required this.sessionId, required this.status});
  factory _SessionStatusChangeData.fromJson(Map<String, dynamic> json) => _$SessionStatusChangeDataFromJson(json);

@override final  String sessionId;
@override final  SessionStatus status;

/// Create a copy of SessionStatusChangeData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionStatusChangeDataCopyWith<_SessionStatusChangeData> get copyWith => __$SessionStatusChangeDataCopyWithImpl<_SessionStatusChangeData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionStatusChangeDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionStatusChangeData&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,status);

@override
String toString() {
  return 'SessionStatusChangeData(sessionId: $sessionId, status: $status)';
}


}

/// @nodoc
abstract mixin class _$SessionStatusChangeDataCopyWith<$Res> implements $SessionStatusChangeDataCopyWith<$Res> {
  factory _$SessionStatusChangeDataCopyWith(_SessionStatusChangeData value, $Res Function(_SessionStatusChangeData) _then) = __$SessionStatusChangeDataCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, SessionStatus status
});




}
/// @nodoc
class __$SessionStatusChangeDataCopyWithImpl<$Res>
    implements _$SessionStatusChangeDataCopyWith<$Res> {
  __$SessionStatusChangeDataCopyWithImpl(this._self, this._then);

  final _SessionStatusChangeData _self;
  final $Res Function(_SessionStatusChangeData) _then;

/// Create a copy of SessionStatusChangeData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? status = null,}) {
  return _then(_SessionStatusChangeData(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,
  ));
}


}


/// @nodoc
mixin _$SessionHistoryData {

 String get sessionId; List<SessionEvent> get events; bool get hasMore;
/// Create a copy of SessionHistoryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionHistoryDataCopyWith<SessionHistoryData> get copyWith => _$SessionHistoryDataCopyWithImpl<SessionHistoryData>(this as SessionHistoryData, _$identity);

  /// Serializes this SessionHistoryData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionHistoryData&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&const DeepCollectionEquality().equals(other.events, events)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,const DeepCollectionEquality().hash(events),hasMore);

@override
String toString() {
  return 'SessionHistoryData(sessionId: $sessionId, events: $events, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class $SessionHistoryDataCopyWith<$Res>  {
  factory $SessionHistoryDataCopyWith(SessionHistoryData value, $Res Function(SessionHistoryData) _then) = _$SessionHistoryDataCopyWithImpl;
@useResult
$Res call({
 String sessionId, List<SessionEvent> events, bool hasMore
});




}
/// @nodoc
class _$SessionHistoryDataCopyWithImpl<$Res>
    implements $SessionHistoryDataCopyWith<$Res> {
  _$SessionHistoryDataCopyWithImpl(this._self, this._then);

  final SessionHistoryData _self;
  final $Res Function(SessionHistoryData) _then;

/// Create a copy of SessionHistoryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? events = null,Object? hasMore = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<SessionEvent>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionHistoryData].
extension SessionHistoryDataPatterns on SessionHistoryData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionHistoryData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionHistoryData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionHistoryData value)  $default,){
final _that = this;
switch (_that) {
case _SessionHistoryData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionHistoryData value)?  $default,){
final _that = this;
switch (_that) {
case _SessionHistoryData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  List<SessionEvent> events,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionHistoryData() when $default != null:
return $default(_that.sessionId,_that.events,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  List<SessionEvent> events,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _SessionHistoryData():
return $default(_that.sessionId,_that.events,_that.hasMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  List<SessionEvent> events,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _SessionHistoryData() when $default != null:
return $default(_that.sessionId,_that.events,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionHistoryData implements SessionHistoryData {
  const _SessionHistoryData({required this.sessionId, required final  List<SessionEvent> events, this.hasMore = false}): _events = events;
  factory _SessionHistoryData.fromJson(Map<String, dynamic> json) => _$SessionHistoryDataFromJson(json);

@override final  String sessionId;
 final  List<SessionEvent> _events;
@override List<SessionEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

@override@JsonKey() final  bool hasMore;

/// Create a copy of SessionHistoryData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionHistoryDataCopyWith<_SessionHistoryData> get copyWith => __$SessionHistoryDataCopyWithImpl<_SessionHistoryData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionHistoryDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionHistoryData&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&const DeepCollectionEquality().equals(other._events, _events)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,const DeepCollectionEquality().hash(_events),hasMore);

@override
String toString() {
  return 'SessionHistoryData(sessionId: $sessionId, events: $events, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$SessionHistoryDataCopyWith<$Res> implements $SessionHistoryDataCopyWith<$Res> {
  factory _$SessionHistoryDataCopyWith(_SessionHistoryData value, $Res Function(_SessionHistoryData) _then) = __$SessionHistoryDataCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, List<SessionEvent> events, bool hasMore
});




}
/// @nodoc
class __$SessionHistoryDataCopyWithImpl<$Res>
    implements _$SessionHistoryDataCopyWith<$Res> {
  __$SessionHistoryDataCopyWithImpl(this._self, this._then);

  final _SessionHistoryData _self;
  final $Res Function(_SessionHistoryData) _then;

/// Create a copy of SessionHistoryData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? events = null,Object? hasMore = null,}) {
  return _then(_SessionHistoryData(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<SessionEvent>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ErrorData {

 String get code;
/// Create a copy of ErrorData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorDataCopyWith<ErrorData> get copyWith => _$ErrorDataCopyWithImpl<ErrorData>(this as ErrorData, _$identity);

  /// Serializes this ErrorData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorData&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code);

@override
String toString() {
  return 'ErrorData(code: $code)';
}


}

/// @nodoc
abstract mixin class $ErrorDataCopyWith<$Res>  {
  factory $ErrorDataCopyWith(ErrorData value, $Res Function(ErrorData) _then) = _$ErrorDataCopyWithImpl;
@useResult
$Res call({
 String code
});




}
/// @nodoc
class _$ErrorDataCopyWithImpl<$Res>
    implements $ErrorDataCopyWith<$Res> {
  _$ErrorDataCopyWithImpl(this._self, this._then);

  final ErrorData _self;
  final $Res Function(ErrorData) _then;

/// Create a copy of ErrorData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ErrorData].
extension ErrorDataPatterns on ErrorData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ErrorData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ErrorData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ErrorData value)  $default,){
final _that = this;
switch (_that) {
case _ErrorData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ErrorData value)?  $default,){
final _that = this;
switch (_that) {
case _ErrorData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ErrorData() when $default != null:
return $default(_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code)  $default,) {final _that = this;
switch (_that) {
case _ErrorData():
return $default(_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code)?  $default,) {final _that = this;
switch (_that) {
case _ErrorData() when $default != null:
return $default(_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ErrorData implements ErrorData {
  const _ErrorData({required this.code});
  factory _ErrorData.fromJson(Map<String, dynamic> json) => _$ErrorDataFromJson(json);

@override final  String code;

/// Create a copy of ErrorData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorDataCopyWith<_ErrorData> get copyWith => __$ErrorDataCopyWithImpl<_ErrorData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ErrorDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ErrorData&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code);

@override
String toString() {
  return 'ErrorData(code: $code)';
}


}

/// @nodoc
abstract mixin class _$ErrorDataCopyWith<$Res> implements $ErrorDataCopyWith<$Res> {
  factory _$ErrorDataCopyWith(_ErrorData value, $Res Function(_ErrorData) _then) = __$ErrorDataCopyWithImpl;
@override @useResult
$Res call({
 String code
});




}
/// @nodoc
class __$ErrorDataCopyWithImpl<$Res>
    implements _$ErrorDataCopyWith<$Res> {
  __$ErrorDataCopyWithImpl(this._self, this._then);

  final _ErrorData _self;
  final $Res Function(_ErrorData) _then;

/// Create a copy of ErrorData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,}) {
  return _then(_ErrorData(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
