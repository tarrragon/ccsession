// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_list_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionListState {

/// 完整 session 列表（來自 WebSocket session_list 訊息）
 List<SessionInfo> get sessions;/// 當前選中的 session ID（null 表示未選擇）
 String? get selectedSessionId;
/// Create a copy of SessionListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionListStateCopyWith<SessionListState> get copyWith => _$SessionListStateCopyWithImpl<SessionListState>(this as SessionListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionListState&&const DeepCollectionEquality().equals(other.sessions, sessions)&&(identical(other.selectedSessionId, selectedSessionId) || other.selectedSessionId == selectedSessionId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(sessions),selectedSessionId);

@override
String toString() {
  return 'SessionListState(sessions: $sessions, selectedSessionId: $selectedSessionId)';
}


}

/// @nodoc
abstract mixin class $SessionListStateCopyWith<$Res>  {
  factory $SessionListStateCopyWith(SessionListState value, $Res Function(SessionListState) _then) = _$SessionListStateCopyWithImpl;
@useResult
$Res call({
 List<SessionInfo> sessions, String? selectedSessionId
});




}
/// @nodoc
class _$SessionListStateCopyWithImpl<$Res>
    implements $SessionListStateCopyWith<$Res> {
  _$SessionListStateCopyWithImpl(this._self, this._then);

  final SessionListState _self;
  final $Res Function(SessionListState) _then;

/// Create a copy of SessionListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessions = null,Object? selectedSessionId = freezed,}) {
  return _then(_self.copyWith(
sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as List<SessionInfo>,selectedSessionId: freezed == selectedSessionId ? _self.selectedSessionId : selectedSessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionListState].
extension SessionListStatePatterns on SessionListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionListState value)  $default,){
final _that = this;
switch (_that) {
case _SessionListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionListState value)?  $default,){
final _that = this;
switch (_that) {
case _SessionListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SessionInfo> sessions,  String? selectedSessionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionListState() when $default != null:
return $default(_that.sessions,_that.selectedSessionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SessionInfo> sessions,  String? selectedSessionId)  $default,) {final _that = this;
switch (_that) {
case _SessionListState():
return $default(_that.sessions,_that.selectedSessionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SessionInfo> sessions,  String? selectedSessionId)?  $default,) {final _that = this;
switch (_that) {
case _SessionListState() when $default != null:
return $default(_that.sessions,_that.selectedSessionId);case _:
  return null;

}
}

}

/// @nodoc


class _SessionListState implements SessionListState {
  const _SessionListState({final  List<SessionInfo> sessions = const [], this.selectedSessionId}): _sessions = sessions;
  

/// 完整 session 列表（來自 WebSocket session_list 訊息）
 final  List<SessionInfo> _sessions;
/// 完整 session 列表（來自 WebSocket session_list 訊息）
@override@JsonKey() List<SessionInfo> get sessions {
  if (_sessions is EqualUnmodifiableListView) return _sessions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sessions);
}

/// 當前選中的 session ID（null 表示未選擇）
@override final  String? selectedSessionId;

/// Create a copy of SessionListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionListStateCopyWith<_SessionListState> get copyWith => __$SessionListStateCopyWithImpl<_SessionListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionListState&&const DeepCollectionEquality().equals(other._sessions, _sessions)&&(identical(other.selectedSessionId, selectedSessionId) || other.selectedSessionId == selectedSessionId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_sessions),selectedSessionId);

@override
String toString() {
  return 'SessionListState(sessions: $sessions, selectedSessionId: $selectedSessionId)';
}


}

/// @nodoc
abstract mixin class _$SessionListStateCopyWith<$Res> implements $SessionListStateCopyWith<$Res> {
  factory _$SessionListStateCopyWith(_SessionListState value, $Res Function(_SessionListState) _then) = __$SessionListStateCopyWithImpl;
@override @useResult
$Res call({
 List<SessionInfo> sessions, String? selectedSessionId
});




}
/// @nodoc
class __$SessionListStateCopyWithImpl<$Res>
    implements _$SessionListStateCopyWith<$Res> {
  __$SessionListStateCopyWithImpl(this._self, this._then);

  final _SessionListState _self;
  final $Res Function(_SessionListState) _then;

/// Create a copy of SessionListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessions = null,Object? selectedSessionId = freezed,}) {
  return _then(_SessionListState(
sessions: null == sessions ? _self._sessions : sessions // ignore: cast_nullable_to_non_nullable
as List<SessionInfo>,selectedSessionId: freezed == selectedSessionId ? _self.selectedSessionId : selectedSessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
