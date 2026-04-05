// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_reaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageReactionModel {

 String get id;@JsonKey(name: 'message_id') String get messageId;@JsonKey(name: 'user_id') String get userId; String get username;@JsonKey(readValue: _readReaction) String get reaction;@JsonKey(name: 'created_at', fromJson: _dateTimeFromJson) DateTime get createdAt;
/// Create a copy of MessageReactionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageReactionModelCopyWith<MessageReactionModel> get copyWith => _$MessageReactionModelCopyWithImpl<MessageReactionModel>(this as MessageReactionModel, _$identity);

  /// Serializes this MessageReactionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageReactionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.reaction, reaction) || other.reaction == reaction)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,messageId,userId,username,reaction,createdAt);

@override
String toString() {
  return 'MessageReactionModel(id: $id, messageId: $messageId, userId: $userId, username: $username, reaction: $reaction, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MessageReactionModelCopyWith<$Res>  {
  factory $MessageReactionModelCopyWith(MessageReactionModel value, $Res Function(MessageReactionModel) _then) = _$MessageReactionModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'message_id') String messageId,@JsonKey(name: 'user_id') String userId, String username,@JsonKey(readValue: _readReaction) String reaction,@JsonKey(name: 'created_at', fromJson: _dateTimeFromJson) DateTime createdAt
});




}
/// @nodoc
class _$MessageReactionModelCopyWithImpl<$Res>
    implements $MessageReactionModelCopyWith<$Res> {
  _$MessageReactionModelCopyWithImpl(this._self, this._then);

  final MessageReactionModel _self;
  final $Res Function(MessageReactionModel) _then;

/// Create a copy of MessageReactionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? messageId = null,Object? userId = null,Object? username = null,Object? reaction = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,reaction: null == reaction ? _self.reaction : reaction // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageReactionModel].
extension MessageReactionModelPatterns on MessageReactionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageReactionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageReactionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageReactionModel value)  $default,){
final _that = this;
switch (_that) {
case _MessageReactionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageReactionModel value)?  $default,){
final _that = this;
switch (_that) {
case _MessageReactionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'user_id')  String userId,  String username, @JsonKey(readValue: _readReaction)  String reaction, @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageReactionModel() when $default != null:
return $default(_that.id,_that.messageId,_that.userId,_that.username,_that.reaction,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'user_id')  String userId,  String username, @JsonKey(readValue: _readReaction)  String reaction, @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MessageReactionModel():
return $default(_that.id,_that.messageId,_that.userId,_that.username,_that.reaction,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'user_id')  String userId,  String username, @JsonKey(readValue: _readReaction)  String reaction, @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MessageReactionModel() when $default != null:
return $default(_that.id,_that.messageId,_that.userId,_that.username,_that.reaction,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageReactionModel extends MessageReactionModel {
  const _MessageReactionModel({this.id = '', @JsonKey(name: 'message_id') this.messageId = '', @JsonKey(name: 'user_id') this.userId = '', this.username = 'Unknown', @JsonKey(readValue: _readReaction) required this.reaction, @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson) required this.createdAt}): super._();
  factory _MessageReactionModel.fromJson(Map<String, dynamic> json) => _$MessageReactionModelFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey(name: 'message_id') final  String messageId;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey() final  String username;
@override@JsonKey(readValue: _readReaction) final  String reaction;
@override@JsonKey(name: 'created_at', fromJson: _dateTimeFromJson) final  DateTime createdAt;

/// Create a copy of MessageReactionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageReactionModelCopyWith<_MessageReactionModel> get copyWith => __$MessageReactionModelCopyWithImpl<_MessageReactionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageReactionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageReactionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.reaction, reaction) || other.reaction == reaction)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,messageId,userId,username,reaction,createdAt);

@override
String toString() {
  return 'MessageReactionModel(id: $id, messageId: $messageId, userId: $userId, username: $username, reaction: $reaction, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MessageReactionModelCopyWith<$Res> implements $MessageReactionModelCopyWith<$Res> {
  factory _$MessageReactionModelCopyWith(_MessageReactionModel value, $Res Function(_MessageReactionModel) _then) = __$MessageReactionModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'message_id') String messageId,@JsonKey(name: 'user_id') String userId, String username,@JsonKey(readValue: _readReaction) String reaction,@JsonKey(name: 'created_at', fromJson: _dateTimeFromJson) DateTime createdAt
});




}
/// @nodoc
class __$MessageReactionModelCopyWithImpl<$Res>
    implements _$MessageReactionModelCopyWith<$Res> {
  __$MessageReactionModelCopyWithImpl(this._self, this._then);

  final _MessageReactionModel _self;
  final $Res Function(_MessageReactionModel) _then;

/// Create a copy of MessageReactionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? messageId = null,Object? userId = null,Object? username = null,Object? reaction = null,Object? createdAt = null,}) {
  return _then(_MessageReactionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,reaction: null == reaction ? _self.reaction : reaction // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$GroupedReaction {

 String get emoji; int get count; List<String> get usernames; bool get hasCurrentUserReacted;
/// Create a copy of GroupedReaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupedReactionCopyWith<GroupedReaction> get copyWith => _$GroupedReactionCopyWithImpl<GroupedReaction>(this as GroupedReaction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupedReaction&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other.usernames, usernames)&&(identical(other.hasCurrentUserReacted, hasCurrentUserReacted) || other.hasCurrentUserReacted == hasCurrentUserReacted));
}


@override
int get hashCode => Object.hash(runtimeType,emoji,count,const DeepCollectionEquality().hash(usernames),hasCurrentUserReacted);

@override
String toString() {
  return 'GroupedReaction(emoji: $emoji, count: $count, usernames: $usernames, hasCurrentUserReacted: $hasCurrentUserReacted)';
}


}

/// @nodoc
abstract mixin class $GroupedReactionCopyWith<$Res>  {
  factory $GroupedReactionCopyWith(GroupedReaction value, $Res Function(GroupedReaction) _then) = _$GroupedReactionCopyWithImpl;
@useResult
$Res call({
 String emoji, int count, List<String> usernames, bool hasCurrentUserReacted
});




}
/// @nodoc
class _$GroupedReactionCopyWithImpl<$Res>
    implements $GroupedReactionCopyWith<$Res> {
  _$GroupedReactionCopyWithImpl(this._self, this._then);

  final GroupedReaction _self;
  final $Res Function(GroupedReaction) _then;

/// Create a copy of GroupedReaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? emoji = null,Object? count = null,Object? usernames = null,Object? hasCurrentUserReacted = null,}) {
  return _then(_self.copyWith(
emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,usernames: null == usernames ? _self.usernames : usernames // ignore: cast_nullable_to_non_nullable
as List<String>,hasCurrentUserReacted: null == hasCurrentUserReacted ? _self.hasCurrentUserReacted : hasCurrentUserReacted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupedReaction].
extension GroupedReactionPatterns on GroupedReaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupedReaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupedReaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupedReaction value)  $default,){
final _that = this;
switch (_that) {
case _GroupedReaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupedReaction value)?  $default,){
final _that = this;
switch (_that) {
case _GroupedReaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String emoji,  int count,  List<String> usernames,  bool hasCurrentUserReacted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupedReaction() when $default != null:
return $default(_that.emoji,_that.count,_that.usernames,_that.hasCurrentUserReacted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String emoji,  int count,  List<String> usernames,  bool hasCurrentUserReacted)  $default,) {final _that = this;
switch (_that) {
case _GroupedReaction():
return $default(_that.emoji,_that.count,_that.usernames,_that.hasCurrentUserReacted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String emoji,  int count,  List<String> usernames,  bool hasCurrentUserReacted)?  $default,) {final _that = this;
switch (_that) {
case _GroupedReaction() when $default != null:
return $default(_that.emoji,_that.count,_that.usernames,_that.hasCurrentUserReacted);case _:
  return null;

}
}

}

/// @nodoc


class _GroupedReaction extends GroupedReaction {
  const _GroupedReaction({required this.emoji, required this.count, required final  List<String> usernames, this.hasCurrentUserReacted = false}): _usernames = usernames,super._();
  

@override final  String emoji;
@override final  int count;
 final  List<String> _usernames;
@override List<String> get usernames {
  if (_usernames is EqualUnmodifiableListView) return _usernames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_usernames);
}

@override@JsonKey() final  bool hasCurrentUserReacted;

/// Create a copy of GroupedReaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupedReactionCopyWith<_GroupedReaction> get copyWith => __$GroupedReactionCopyWithImpl<_GroupedReaction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupedReaction&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other._usernames, _usernames)&&(identical(other.hasCurrentUserReacted, hasCurrentUserReacted) || other.hasCurrentUserReacted == hasCurrentUserReacted));
}


@override
int get hashCode => Object.hash(runtimeType,emoji,count,const DeepCollectionEquality().hash(_usernames),hasCurrentUserReacted);

@override
String toString() {
  return 'GroupedReaction(emoji: $emoji, count: $count, usernames: $usernames, hasCurrentUserReacted: $hasCurrentUserReacted)';
}


}

/// @nodoc
abstract mixin class _$GroupedReactionCopyWith<$Res> implements $GroupedReactionCopyWith<$Res> {
  factory _$GroupedReactionCopyWith(_GroupedReaction value, $Res Function(_GroupedReaction) _then) = __$GroupedReactionCopyWithImpl;
@override @useResult
$Res call({
 String emoji, int count, List<String> usernames, bool hasCurrentUserReacted
});




}
/// @nodoc
class __$GroupedReactionCopyWithImpl<$Res>
    implements _$GroupedReactionCopyWith<$Res> {
  __$GroupedReactionCopyWithImpl(this._self, this._then);

  final _GroupedReaction _self;
  final $Res Function(_GroupedReaction) _then;

/// Create a copy of GroupedReaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? emoji = null,Object? count = null,Object? usernames = null,Object? hasCurrentUserReacted = null,}) {
  return _then(_GroupedReaction(
emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,usernames: null == usernames ? _self._usernames : usernames // ignore: cast_nullable_to_non_nullable
as List<String>,hasCurrentUserReacted: null == hasCurrentUserReacted ? _self.hasCurrentUserReacted : hasCurrentUserReacted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
