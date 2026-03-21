// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_stream_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveStreamDto {

 String get streamId; String get name; String? get categoryId; String? get streamIcon; String? get epgChannelId; bool get tvArchive; bool get isAdult;
/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveStreamDtoCopyWith<LiveStreamDto> get copyWith => _$LiveStreamDtoCopyWithImpl<LiveStreamDto>(this as LiveStreamDto, _$identity);

  /// Serializes this LiveStreamDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveStreamDto&&(identical(other.streamId, streamId) || other.streamId == streamId)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.streamIcon, streamIcon) || other.streamIcon == streamIcon)&&(identical(other.epgChannelId, epgChannelId) || other.epgChannelId == epgChannelId)&&(identical(other.tvArchive, tvArchive) || other.tvArchive == tvArchive)&&(identical(other.isAdult, isAdult) || other.isAdult == isAdult));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streamId,name,categoryId,streamIcon,epgChannelId,tvArchive,isAdult);

@override
String toString() {
  return 'LiveStreamDto(streamId: $streamId, name: $name, categoryId: $categoryId, streamIcon: $streamIcon, epgChannelId: $epgChannelId, tvArchive: $tvArchive, isAdult: $isAdult)';
}


}

/// @nodoc
abstract mixin class $LiveStreamDtoCopyWith<$Res>  {
  factory $LiveStreamDtoCopyWith(LiveStreamDto value, $Res Function(LiveStreamDto) _then) = _$LiveStreamDtoCopyWithImpl;
@useResult
$Res call({
 String streamId, String name, String? categoryId, String? streamIcon, String? epgChannelId, bool tvArchive, bool isAdult
});




}
/// @nodoc
class _$LiveStreamDtoCopyWithImpl<$Res>
    implements $LiveStreamDtoCopyWith<$Res> {
  _$LiveStreamDtoCopyWithImpl(this._self, this._then);

  final LiveStreamDto _self;
  final $Res Function(LiveStreamDto) _then;

/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? streamId = null,Object? name = null,Object? categoryId = freezed,Object? streamIcon = freezed,Object? epgChannelId = freezed,Object? tvArchive = null,Object? isAdult = null,}) {
  return _then(_self.copyWith(
streamId: null == streamId ? _self.streamId : streamId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,streamIcon: freezed == streamIcon ? _self.streamIcon : streamIcon // ignore: cast_nullable_to_non_nullable
as String?,epgChannelId: freezed == epgChannelId ? _self.epgChannelId : epgChannelId // ignore: cast_nullable_to_non_nullable
as String?,tvArchive: null == tvArchive ? _self.tvArchive : tvArchive // ignore: cast_nullable_to_non_nullable
as bool,isAdult: null == isAdult ? _self.isAdult : isAdult // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveStreamDto].
extension LiveStreamDtoPatterns on LiveStreamDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveStreamDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveStreamDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveStreamDto value)  $default,){
final _that = this;
switch (_that) {
case _LiveStreamDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveStreamDto value)?  $default,){
final _that = this;
switch (_that) {
case _LiveStreamDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String streamId,  String name,  String? categoryId,  String? streamIcon,  String? epgChannelId,  bool tvArchive,  bool isAdult)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveStreamDto() when $default != null:
return $default(_that.streamId,_that.name,_that.categoryId,_that.streamIcon,_that.epgChannelId,_that.tvArchive,_that.isAdult);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String streamId,  String name,  String? categoryId,  String? streamIcon,  String? epgChannelId,  bool tvArchive,  bool isAdult)  $default,) {final _that = this;
switch (_that) {
case _LiveStreamDto():
return $default(_that.streamId,_that.name,_that.categoryId,_that.streamIcon,_that.epgChannelId,_that.tvArchive,_that.isAdult);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String streamId,  String name,  String? categoryId,  String? streamIcon,  String? epgChannelId,  bool tvArchive,  bool isAdult)?  $default,) {final _that = this;
switch (_that) {
case _LiveStreamDto() when $default != null:
return $default(_that.streamId,_that.name,_that.categoryId,_that.streamIcon,_that.epgChannelId,_that.tvArchive,_that.isAdult);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveStreamDto implements LiveStreamDto {
  const _LiveStreamDto({required this.streamId, required this.name, this.categoryId, this.streamIcon, this.epgChannelId, required this.tvArchive, required this.isAdult});
  factory _LiveStreamDto.fromJson(Map<String, dynamic> json) => _$LiveStreamDtoFromJson(json);

@override final  String streamId;
@override final  String name;
@override final  String? categoryId;
@override final  String? streamIcon;
@override final  String? epgChannelId;
@override final  bool tvArchive;
@override final  bool isAdult;

/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveStreamDtoCopyWith<_LiveStreamDto> get copyWith => __$LiveStreamDtoCopyWithImpl<_LiveStreamDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveStreamDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveStreamDto&&(identical(other.streamId, streamId) || other.streamId == streamId)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.streamIcon, streamIcon) || other.streamIcon == streamIcon)&&(identical(other.epgChannelId, epgChannelId) || other.epgChannelId == epgChannelId)&&(identical(other.tvArchive, tvArchive) || other.tvArchive == tvArchive)&&(identical(other.isAdult, isAdult) || other.isAdult == isAdult));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streamId,name,categoryId,streamIcon,epgChannelId,tvArchive,isAdult);

@override
String toString() {
  return 'LiveStreamDto(streamId: $streamId, name: $name, categoryId: $categoryId, streamIcon: $streamIcon, epgChannelId: $epgChannelId, tvArchive: $tvArchive, isAdult: $isAdult)';
}


}

/// @nodoc
abstract mixin class _$LiveStreamDtoCopyWith<$Res> implements $LiveStreamDtoCopyWith<$Res> {
  factory _$LiveStreamDtoCopyWith(_LiveStreamDto value, $Res Function(_LiveStreamDto) _then) = __$LiveStreamDtoCopyWithImpl;
@override @useResult
$Res call({
 String streamId, String name, String? categoryId, String? streamIcon, String? epgChannelId, bool tvArchive, bool isAdult
});




}
/// @nodoc
class __$LiveStreamDtoCopyWithImpl<$Res>
    implements _$LiveStreamDtoCopyWith<$Res> {
  __$LiveStreamDtoCopyWithImpl(this._self, this._then);

  final _LiveStreamDto _self;
  final $Res Function(_LiveStreamDto) _then;

/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? streamId = null,Object? name = null,Object? categoryId = freezed,Object? streamIcon = freezed,Object? epgChannelId = freezed,Object? tvArchive = null,Object? isAdult = null,}) {
  return _then(_LiveStreamDto(
streamId: null == streamId ? _self.streamId : streamId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,streamIcon: freezed == streamIcon ? _self.streamIcon : streamIcon // ignore: cast_nullable_to_non_nullable
as String?,epgChannelId: freezed == epgChannelId ? _self.epgChannelId : epgChannelId // ignore: cast_nullable_to_non_nullable
as String?,tvArchive: null == tvArchive ? _self.tvArchive : tvArchive // ignore: cast_nullable_to_non_nullable
as bool,isAdult: null == isAdult ? _self.isAdult : isAdult // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
