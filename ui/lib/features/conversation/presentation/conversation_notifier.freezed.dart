// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversationState implements DiagnosticableTreeMixin {

/// 當前載入的 session ID
 String? get sessionId;/// 對話事件列表（按 timestamp 升序）
 List<SessionEvent> get events;/// 是否正在載入歷史事件
 bool get isLoadingHistory;/// 是否還有更早的歷史事件可載入
 bool get hasMore;/// 是否處於自動捲動模式（使用者未手動上捲）
 bool get isAutoScrollEnabled;/// 錯誤訊息（載入失敗時）
 String? get errorMessage;
/// Create a copy of ConversationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationStateCopyWith<ConversationState> get copyWith => _$ConversationStateCopyWithImpl<ConversationState>(this as ConversationState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ConversationState'))
    ..add(DiagnosticsProperty('sessionId', sessionId))..add(DiagnosticsProperty('events', events))..add(DiagnosticsProperty('isLoadingHistory', isLoadingHistory))..add(DiagnosticsProperty('hasMore', hasMore))..add(DiagnosticsProperty('isAutoScrollEnabled', isAutoScrollEnabled))..add(DiagnosticsProperty('errorMessage', errorMessage));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationState&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&const DeepCollectionEquality().equals(other.events, events)&&(identical(other.isLoadingHistory, isLoadingHistory) || other.isLoadingHistory == isLoadingHistory)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.isAutoScrollEnabled, isAutoScrollEnabled) || other.isAutoScrollEnabled == isAutoScrollEnabled)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,const DeepCollectionEquality().hash(events),isLoadingHistory,hasMore,isAutoScrollEnabled,errorMessage);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ConversationState(sessionId: $sessionId, events: $events, isLoadingHistory: $isLoadingHistory, hasMore: $hasMore, isAutoScrollEnabled: $isAutoScrollEnabled, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $ConversationStateCopyWith<$Res>  {
  factory $ConversationStateCopyWith(ConversationState value, $Res Function(ConversationState) _then) = _$ConversationStateCopyWithImpl;
@useResult
$Res call({
 String? sessionId, List<SessionEvent> events, bool isLoadingHistory, bool hasMore, bool isAutoScrollEnabled, String? errorMessage
});




}
/// @nodoc
class _$ConversationStateCopyWithImpl<$Res>
    implements $ConversationStateCopyWith<$Res> {
  _$ConversationStateCopyWithImpl(this._self, this._then);

  final ConversationState _self;
  final $Res Function(ConversationState) _then;

/// Create a copy of ConversationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = freezed,Object? events = null,Object? isLoadingHistory = null,Object? hasMore = null,Object? isAutoScrollEnabled = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<SessionEvent>,isLoadingHistory: null == isLoadingHistory ? _self.isLoadingHistory : isLoadingHistory // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isAutoScrollEnabled: null == isAutoScrollEnabled ? _self.isAutoScrollEnabled : isAutoScrollEnabled // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationState].
extension ConversationStatePatterns on ConversationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationState value)  $default,){
final _that = this;
switch (_that) {
case _ConversationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationState value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? sessionId,  List<SessionEvent> events,  bool isLoadingHistory,  bool hasMore,  bool isAutoScrollEnabled,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationState() when $default != null:
return $default(_that.sessionId,_that.events,_that.isLoadingHistory,_that.hasMore,_that.isAutoScrollEnabled,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? sessionId,  List<SessionEvent> events,  bool isLoadingHistory,  bool hasMore,  bool isAutoScrollEnabled,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _ConversationState():
return $default(_that.sessionId,_that.events,_that.isLoadingHistory,_that.hasMore,_that.isAutoScrollEnabled,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? sessionId,  List<SessionEvent> events,  bool isLoadingHistory,  bool hasMore,  bool isAutoScrollEnabled,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _ConversationState() when $default != null:
return $default(_that.sessionId,_that.events,_that.isLoadingHistory,_that.hasMore,_that.isAutoScrollEnabled,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationState with DiagnosticableTreeMixin implements ConversationState {
  const _ConversationState({this.sessionId, final  List<SessionEvent> events = const [], this.isLoadingHistory = false, this.hasMore = false, this.isAutoScrollEnabled = true, this.errorMessage}): _events = events;
  

/// 當前載入的 session ID
@override final  String? sessionId;
/// 對話事件列表（按 timestamp 升序）
 final  List<SessionEvent> _events;
/// 對話事件列表（按 timestamp 升序）
@override@JsonKey() List<SessionEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

/// 是否正在載入歷史事件
@override@JsonKey() final  bool isLoadingHistory;
/// 是否還有更早的歷史事件可載入
@override@JsonKey() final  bool hasMore;
/// 是否處於自動捲動模式（使用者未手動上捲）
@override@JsonKey() final  bool isAutoScrollEnabled;
/// 錯誤訊息（載入失敗時）
@override final  String? errorMessage;

/// Create a copy of ConversationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationStateCopyWith<_ConversationState> get copyWith => __$ConversationStateCopyWithImpl<_ConversationState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ConversationState'))
    ..add(DiagnosticsProperty('sessionId', sessionId))..add(DiagnosticsProperty('events', events))..add(DiagnosticsProperty('isLoadingHistory', isLoadingHistory))..add(DiagnosticsProperty('hasMore', hasMore))..add(DiagnosticsProperty('isAutoScrollEnabled', isAutoScrollEnabled))..add(DiagnosticsProperty('errorMessage', errorMessage));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationState&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&const DeepCollectionEquality().equals(other._events, _events)&&(identical(other.isLoadingHistory, isLoadingHistory) || other.isLoadingHistory == isLoadingHistory)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.isAutoScrollEnabled, isAutoScrollEnabled) || other.isAutoScrollEnabled == isAutoScrollEnabled)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,const DeepCollectionEquality().hash(_events),isLoadingHistory,hasMore,isAutoScrollEnabled,errorMessage);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ConversationState(sessionId: $sessionId, events: $events, isLoadingHistory: $isLoadingHistory, hasMore: $hasMore, isAutoScrollEnabled: $isAutoScrollEnabled, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ConversationStateCopyWith<$Res> implements $ConversationStateCopyWith<$Res> {
  factory _$ConversationStateCopyWith(_ConversationState value, $Res Function(_ConversationState) _then) = __$ConversationStateCopyWithImpl;
@override @useResult
$Res call({
 String? sessionId, List<SessionEvent> events, bool isLoadingHistory, bool hasMore, bool isAutoScrollEnabled, String? errorMessage
});




}
/// @nodoc
class __$ConversationStateCopyWithImpl<$Res>
    implements _$ConversationStateCopyWith<$Res> {
  __$ConversationStateCopyWithImpl(this._self, this._then);

  final _ConversationState _self;
  final $Res Function(_ConversationState) _then;

/// Create a copy of ConversationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = freezed,Object? events = null,Object? isLoadingHistory = null,Object? hasMore = null,Object? isAutoScrollEnabled = null,Object? errorMessage = freezed,}) {
  return _then(_ConversationState(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<SessionEvent>,isLoadingHistory: null == isLoadingHistory ? _self.isLoadingHistory : isLoadingHistory // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isAutoScrollEnabled: null == isAutoScrollEnabled ? _self.isAutoScrollEnabled : isAutoScrollEnabled // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
