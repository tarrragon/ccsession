// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClientMessage {

 String get action; String get sessionId; int get limit; String get before;
/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClientMessageCopyWith<ClientMessage> get copyWith => _$ClientMessageCopyWithImpl<ClientMessage>(this as ClientMessage, _$identity);

  /// Serializes this ClientMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClientMessage&&(identical(other.action, action) || other.action == action)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.before, before) || other.before == before));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,sessionId,limit,before);

@override
String toString() {
  return 'ClientMessage(action: $action, sessionId: $sessionId, limit: $limit, before: $before)';
}


}

/// @nodoc
abstract mixin class $ClientMessageCopyWith<$Res>  {
  factory $ClientMessageCopyWith(ClientMessage value, $Res Function(ClientMessage) _then) = _$ClientMessageCopyWithImpl;
@useResult
$Res call({
 String action, String sessionId, int limit, String before
});




}
/// @nodoc
class _$ClientMessageCopyWithImpl<$Res>
    implements $ClientMessageCopyWith<$Res> {
  _$ClientMessageCopyWithImpl(this._self, this._then);

  final ClientMessage _self;
  final $Res Function(ClientMessage) _then;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? action = null,Object? sessionId = null,Object? limit = null,Object? before = null,}) {
  return _then(_self.copyWith(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,before: null == before ? _self.before : before // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ClientMessage].
extension ClientMessagePatterns on ClientMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClientMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClientMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClientMessage value)  $default,){
final _that = this;
switch (_that) {
case _ClientMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClientMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ClientMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String action,  String sessionId,  int limit,  String before)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClientMessage() when $default != null:
return $default(_that.action,_that.sessionId,_that.limit,_that.before);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String action,  String sessionId,  int limit,  String before)  $default,) {final _that = this;
switch (_that) {
case _ClientMessage():
return $default(_that.action,_that.sessionId,_that.limit,_that.before);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String action,  String sessionId,  int limit,  String before)?  $default,) {final _that = this;
switch (_that) {
case _ClientMessage() when $default != null:
return $default(_that.action,_that.sessionId,_that.limit,_that.before);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClientMessage implements ClientMessage {
  const _ClientMessage({required this.action, this.sessionId = '', this.limit = 0, this.before = ''});
  factory _ClientMessage.fromJson(Map<String, dynamic> json) => _$ClientMessageFromJson(json);

@override final  String action;
@override@JsonKey() final  String sessionId;
@override@JsonKey() final  int limit;
@override@JsonKey() final  String before;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClientMessageCopyWith<_ClientMessage> get copyWith => __$ClientMessageCopyWithImpl<_ClientMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClientMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClientMessage&&(identical(other.action, action) || other.action == action)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.before, before) || other.before == before));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,sessionId,limit,before);

@override
String toString() {
  return 'ClientMessage(action: $action, sessionId: $sessionId, limit: $limit, before: $before)';
}


}

/// @nodoc
abstract mixin class _$ClientMessageCopyWith<$Res> implements $ClientMessageCopyWith<$Res> {
  factory _$ClientMessageCopyWith(_ClientMessage value, $Res Function(_ClientMessage) _then) = __$ClientMessageCopyWithImpl;
@override @useResult
$Res call({
 String action, String sessionId, int limit, String before
});




}
/// @nodoc
class __$ClientMessageCopyWithImpl<$Res>
    implements _$ClientMessageCopyWith<$Res> {
  __$ClientMessageCopyWithImpl(this._self, this._then);

  final _ClientMessage _self;
  final $Res Function(_ClientMessage) _then;

/// Create a copy of ClientMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? action = null,Object? sessionId = null,Object? limit = null,Object? before = null,}) {
  return _then(_ClientMessage(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,before: null == before ? _self.before : before // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
