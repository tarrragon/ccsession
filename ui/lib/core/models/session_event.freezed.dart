// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionEvent {

 String get sessionId; String get projectPath; String get type; DateTime get timestamp; String get messageId; int get contentIndex; bool get isLastContent; EventContent get content; String get toolName;
/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionEventCopyWith<SessionEvent> get copyWith => _$SessionEventCopyWithImpl<SessionEvent>(this as SessionEvent, _$identity);

  /// Serializes this SessionEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionEvent&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.projectPath, projectPath) || other.projectPath == projectPath)&&(identical(other.type, type) || other.type == type)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.contentIndex, contentIndex) || other.contentIndex == contentIndex)&&(identical(other.isLastContent, isLastContent) || other.isLastContent == isLastContent)&&(identical(other.content, content) || other.content == content)&&(identical(other.toolName, toolName) || other.toolName == toolName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,projectPath,type,timestamp,messageId,contentIndex,isLastContent,content,toolName);

@override
String toString() {
  return 'SessionEvent(sessionId: $sessionId, projectPath: $projectPath, type: $type, timestamp: $timestamp, messageId: $messageId, contentIndex: $contentIndex, isLastContent: $isLastContent, content: $content, toolName: $toolName)';
}


}

/// @nodoc
abstract mixin class $SessionEventCopyWith<$Res>  {
  factory $SessionEventCopyWith(SessionEvent value, $Res Function(SessionEvent) _then) = _$SessionEventCopyWithImpl;
@useResult
$Res call({
 String sessionId, String projectPath, String type, DateTime timestamp, String messageId, int contentIndex, bool isLastContent, EventContent content, String toolName
});


$EventContentCopyWith<$Res> get content;

}
/// @nodoc
class _$SessionEventCopyWithImpl<$Res>
    implements $SessionEventCopyWith<$Res> {
  _$SessionEventCopyWithImpl(this._self, this._then);

  final SessionEvent _self;
  final $Res Function(SessionEvent) _then;

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? projectPath = null,Object? type = null,Object? timestamp = null,Object? messageId = null,Object? contentIndex = null,Object? isLastContent = null,Object? content = null,Object? toolName = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,projectPath: null == projectPath ? _self.projectPath : projectPath // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,contentIndex: null == contentIndex ? _self.contentIndex : contentIndex // ignore: cast_nullable_to_non_nullable
as int,isLastContent: null == isLastContent ? _self.isLastContent : isLastContent // ignore: cast_nullable_to_non_nullable
as bool,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as EventContent,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventContentCopyWith<$Res> get content {
  
  return $EventContentCopyWith<$Res>(_self.content, (value) {
    return _then(_self.copyWith(content: value));
  });
}
}


/// Adds pattern-matching-related methods to [SessionEvent].
extension SessionEventPatterns on SessionEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionEvent value)  $default,){
final _that = this;
switch (_that) {
case _SessionEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionEvent value)?  $default,){
final _that = this;
switch (_that) {
case _SessionEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  String projectPath,  String type,  DateTime timestamp,  String messageId,  int contentIndex,  bool isLastContent,  EventContent content,  String toolName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionEvent() when $default != null:
return $default(_that.sessionId,_that.projectPath,_that.type,_that.timestamp,_that.messageId,_that.contentIndex,_that.isLastContent,_that.content,_that.toolName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  String projectPath,  String type,  DateTime timestamp,  String messageId,  int contentIndex,  bool isLastContent,  EventContent content,  String toolName)  $default,) {final _that = this;
switch (_that) {
case _SessionEvent():
return $default(_that.sessionId,_that.projectPath,_that.type,_that.timestamp,_that.messageId,_that.contentIndex,_that.isLastContent,_that.content,_that.toolName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  String projectPath,  String type,  DateTime timestamp,  String messageId,  int contentIndex,  bool isLastContent,  EventContent content,  String toolName)?  $default,) {final _that = this;
switch (_that) {
case _SessionEvent() when $default != null:
return $default(_that.sessionId,_that.projectPath,_that.type,_that.timestamp,_that.messageId,_that.contentIndex,_that.isLastContent,_that.content,_that.toolName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionEvent implements SessionEvent {
  const _SessionEvent({required this.sessionId, this.projectPath = '', required this.type, required this.timestamp, this.messageId = '', this.contentIndex = -1, this.isLastContent = false, required this.content, this.toolName = ''});
  factory _SessionEvent.fromJson(Map<String, dynamic> json) => _$SessionEventFromJson(json);

@override final  String sessionId;
@override@JsonKey() final  String projectPath;
@override final  String type;
@override final  DateTime timestamp;
@override@JsonKey() final  String messageId;
@override@JsonKey() final  int contentIndex;
@override@JsonKey() final  bool isLastContent;
@override final  EventContent content;
@override@JsonKey() final  String toolName;

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionEventCopyWith<_SessionEvent> get copyWith => __$SessionEventCopyWithImpl<_SessionEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionEvent&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.projectPath, projectPath) || other.projectPath == projectPath)&&(identical(other.type, type) || other.type == type)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.contentIndex, contentIndex) || other.contentIndex == contentIndex)&&(identical(other.isLastContent, isLastContent) || other.isLastContent == isLastContent)&&(identical(other.content, content) || other.content == content)&&(identical(other.toolName, toolName) || other.toolName == toolName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,projectPath,type,timestamp,messageId,contentIndex,isLastContent,content,toolName);

@override
String toString() {
  return 'SessionEvent(sessionId: $sessionId, projectPath: $projectPath, type: $type, timestamp: $timestamp, messageId: $messageId, contentIndex: $contentIndex, isLastContent: $isLastContent, content: $content, toolName: $toolName)';
}


}

/// @nodoc
abstract mixin class _$SessionEventCopyWith<$Res> implements $SessionEventCopyWith<$Res> {
  factory _$SessionEventCopyWith(_SessionEvent value, $Res Function(_SessionEvent) _then) = __$SessionEventCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, String projectPath, String type, DateTime timestamp, String messageId, int contentIndex, bool isLastContent, EventContent content, String toolName
});


@override $EventContentCopyWith<$Res> get content;

}
/// @nodoc
class __$SessionEventCopyWithImpl<$Res>
    implements _$SessionEventCopyWith<$Res> {
  __$SessionEventCopyWithImpl(this._self, this._then);

  final _SessionEvent _self;
  final $Res Function(_SessionEvent) _then;

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? projectPath = null,Object? type = null,Object? timestamp = null,Object? messageId = null,Object? contentIndex = null,Object? isLastContent = null,Object? content = null,Object? toolName = null,}) {
  return _then(_SessionEvent(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,projectPath: null == projectPath ? _self.projectPath : projectPath // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,contentIndex: null == contentIndex ? _self.contentIndex : contentIndex // ignore: cast_nullable_to_non_nullable
as int,isLastContent: null == isLastContent ? _self.isLastContent : isLastContent // ignore: cast_nullable_to_non_nullable
as bool,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as EventContent,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventContentCopyWith<$Res> get content {
  
  return $EventContentCopyWith<$Res>(_self.content, (value) {
    return _then(_self.copyWith(content: value));
  });
}
}


/// @nodoc
mixin _$EventContent {

 String get text; String get toolName; Object? get toolInput; String get toolUseId; String get output; bool get isError;
/// Create a copy of EventContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventContentCopyWith<EventContent> get copyWith => _$EventContentCopyWithImpl<EventContent>(this as EventContent, _$identity);

  /// Serializes this EventContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventContent&&(identical(other.text, text) || other.text == text)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&const DeepCollectionEquality().equals(other.toolInput, toolInput)&&(identical(other.toolUseId, toolUseId) || other.toolUseId == toolUseId)&&(identical(other.output, output) || other.output == output)&&(identical(other.isError, isError) || other.isError == isError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,toolName,const DeepCollectionEquality().hash(toolInput),toolUseId,output,isError);

@override
String toString() {
  return 'EventContent(text: $text, toolName: $toolName, toolInput: $toolInput, toolUseId: $toolUseId, output: $output, isError: $isError)';
}


}

/// @nodoc
abstract mixin class $EventContentCopyWith<$Res>  {
  factory $EventContentCopyWith(EventContent value, $Res Function(EventContent) _then) = _$EventContentCopyWithImpl;
@useResult
$Res call({
 String text, String toolName, Object? toolInput, String toolUseId, String output, bool isError
});




}
/// @nodoc
class _$EventContentCopyWithImpl<$Res>
    implements $EventContentCopyWith<$Res> {
  _$EventContentCopyWithImpl(this._self, this._then);

  final EventContent _self;
  final $Res Function(EventContent) _then;

/// Create a copy of EventContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? toolName = null,Object? toolInput = freezed,Object? toolUseId = null,Object? output = null,Object? isError = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,toolInput: freezed == toolInput ? _self.toolInput : toolInput ,toolUseId: null == toolUseId ? _self.toolUseId : toolUseId // ignore: cast_nullable_to_non_nullable
as String,output: null == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String,isError: null == isError ? _self.isError : isError // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [EventContent].
extension EventContentPatterns on EventContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventContent value)  $default,){
final _that = this;
switch (_that) {
case _EventContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventContent value)?  $default,){
final _that = this;
switch (_that) {
case _EventContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  String toolName,  Object? toolInput,  String toolUseId,  String output,  bool isError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventContent() when $default != null:
return $default(_that.text,_that.toolName,_that.toolInput,_that.toolUseId,_that.output,_that.isError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  String toolName,  Object? toolInput,  String toolUseId,  String output,  bool isError)  $default,) {final _that = this;
switch (_that) {
case _EventContent():
return $default(_that.text,_that.toolName,_that.toolInput,_that.toolUseId,_that.output,_that.isError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  String toolName,  Object? toolInput,  String toolUseId,  String output,  bool isError)?  $default,) {final _that = this;
switch (_that) {
case _EventContent() when $default != null:
return $default(_that.text,_that.toolName,_that.toolInput,_that.toolUseId,_that.output,_that.isError);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventContent implements EventContent {
  const _EventContent({this.text = '', this.toolName = '', this.toolInput, this.toolUseId = '', this.output = '', this.isError = false});
  factory _EventContent.fromJson(Map<String, dynamic> json) => _$EventContentFromJson(json);

@override@JsonKey() final  String text;
@override@JsonKey() final  String toolName;
@override final  Object? toolInput;
@override@JsonKey() final  String toolUseId;
@override@JsonKey() final  String output;
@override@JsonKey() final  bool isError;

/// Create a copy of EventContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventContentCopyWith<_EventContent> get copyWith => __$EventContentCopyWithImpl<_EventContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventContent&&(identical(other.text, text) || other.text == text)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&const DeepCollectionEquality().equals(other.toolInput, toolInput)&&(identical(other.toolUseId, toolUseId) || other.toolUseId == toolUseId)&&(identical(other.output, output) || other.output == output)&&(identical(other.isError, isError) || other.isError == isError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,toolName,const DeepCollectionEquality().hash(toolInput),toolUseId,output,isError);

@override
String toString() {
  return 'EventContent(text: $text, toolName: $toolName, toolInput: $toolInput, toolUseId: $toolUseId, output: $output, isError: $isError)';
}


}

/// @nodoc
abstract mixin class _$EventContentCopyWith<$Res> implements $EventContentCopyWith<$Res> {
  factory _$EventContentCopyWith(_EventContent value, $Res Function(_EventContent) _then) = __$EventContentCopyWithImpl;
@override @useResult
$Res call({
 String text, String toolName, Object? toolInput, String toolUseId, String output, bool isError
});




}
/// @nodoc
class __$EventContentCopyWithImpl<$Res>
    implements _$EventContentCopyWith<$Res> {
  __$EventContentCopyWithImpl(this._self, this._then);

  final _EventContent _self;
  final $Res Function(_EventContent) _then;

/// Create a copy of EventContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? toolName = null,Object? toolInput = freezed,Object? toolUseId = null,Object? output = null,Object? isError = null,}) {
  return _then(_EventContent(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,toolInput: freezed == toolInput ? _self.toolInput : toolInput ,toolUseId: null == toolUseId ? _self.toolUseId : toolUseId // ignore: cast_nullable_to_non_nullable
as String,output: null == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String,isError: null == isError ? _self.isError : isError // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
