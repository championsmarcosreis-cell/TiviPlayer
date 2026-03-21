// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'series_info_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SeriesInfoDto {

 String get seriesId; String get name; String? get plot; String? get genre; String? get cast; String? get cover; int get seasonCount; int get episodeCount;
/// Create a copy of SeriesInfoDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeriesInfoDtoCopyWith<SeriesInfoDto> get copyWith => _$SeriesInfoDtoCopyWithImpl<SeriesInfoDto>(this as SeriesInfoDto, _$identity);

  /// Serializes this SeriesInfoDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeriesInfoDto&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.name, name) || other.name == name)&&(identical(other.plot, plot) || other.plot == plot)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.cast, cast) || other.cast == cast)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.seasonCount, seasonCount) || other.seasonCount == seasonCount)&&(identical(other.episodeCount, episodeCount) || other.episodeCount == episodeCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seriesId,name,plot,genre,cast,cover,seasonCount,episodeCount);

@override
String toString() {
  return 'SeriesInfoDto(seriesId: $seriesId, name: $name, plot: $plot, genre: $genre, cast: $cast, cover: $cover, seasonCount: $seasonCount, episodeCount: $episodeCount)';
}


}

/// @nodoc
abstract mixin class $SeriesInfoDtoCopyWith<$Res>  {
  factory $SeriesInfoDtoCopyWith(SeriesInfoDto value, $Res Function(SeriesInfoDto) _then) = _$SeriesInfoDtoCopyWithImpl;
@useResult
$Res call({
 String seriesId, String name, String? plot, String? genre, String? cast, String? cover, int seasonCount, int episodeCount
});




}
/// @nodoc
class _$SeriesInfoDtoCopyWithImpl<$Res>
    implements $SeriesInfoDtoCopyWith<$Res> {
  _$SeriesInfoDtoCopyWithImpl(this._self, this._then);

  final SeriesInfoDto _self;
  final $Res Function(SeriesInfoDto) _then;

/// Create a copy of SeriesInfoDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seriesId = null,Object? name = null,Object? plot = freezed,Object? genre = freezed,Object? cast = freezed,Object? cover = freezed,Object? seasonCount = null,Object? episodeCount = null,}) {
  return _then(_self.copyWith(
seriesId: null == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,plot: freezed == plot ? _self.plot : plot // ignore: cast_nullable_to_non_nullable
as String?,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,cast: freezed == cast ? _self.cast : cast // ignore: cast_nullable_to_non_nullable
as String?,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String?,seasonCount: null == seasonCount ? _self.seasonCount : seasonCount // ignore: cast_nullable_to_non_nullable
as int,episodeCount: null == episodeCount ? _self.episodeCount : episodeCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SeriesInfoDto].
extension SeriesInfoDtoPatterns on SeriesInfoDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeriesInfoDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeriesInfoDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeriesInfoDto value)  $default,){
final _that = this;
switch (_that) {
case _SeriesInfoDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeriesInfoDto value)?  $default,){
final _that = this;
switch (_that) {
case _SeriesInfoDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String seriesId,  String name,  String? plot,  String? genre,  String? cast,  String? cover,  int seasonCount,  int episodeCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeriesInfoDto() when $default != null:
return $default(_that.seriesId,_that.name,_that.plot,_that.genre,_that.cast,_that.cover,_that.seasonCount,_that.episodeCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String seriesId,  String name,  String? plot,  String? genre,  String? cast,  String? cover,  int seasonCount,  int episodeCount)  $default,) {final _that = this;
switch (_that) {
case _SeriesInfoDto():
return $default(_that.seriesId,_that.name,_that.plot,_that.genre,_that.cast,_that.cover,_that.seasonCount,_that.episodeCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String seriesId,  String name,  String? plot,  String? genre,  String? cast,  String? cover,  int seasonCount,  int episodeCount)?  $default,) {final _that = this;
switch (_that) {
case _SeriesInfoDto() when $default != null:
return $default(_that.seriesId,_that.name,_that.plot,_that.genre,_that.cast,_that.cover,_that.seasonCount,_that.episodeCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeriesInfoDto implements SeriesInfoDto {
  const _SeriesInfoDto({required this.seriesId, required this.name, this.plot, this.genre, this.cast, this.cover, required this.seasonCount, required this.episodeCount});
  factory _SeriesInfoDto.fromJson(Map<String, dynamic> json) => _$SeriesInfoDtoFromJson(json);

@override final  String seriesId;
@override final  String name;
@override final  String? plot;
@override final  String? genre;
@override final  String? cast;
@override final  String? cover;
@override final  int seasonCount;
@override final  int episodeCount;

/// Create a copy of SeriesInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeriesInfoDtoCopyWith<_SeriesInfoDto> get copyWith => __$SeriesInfoDtoCopyWithImpl<_SeriesInfoDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeriesInfoDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeriesInfoDto&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.name, name) || other.name == name)&&(identical(other.plot, plot) || other.plot == plot)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.cast, cast) || other.cast == cast)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.seasonCount, seasonCount) || other.seasonCount == seasonCount)&&(identical(other.episodeCount, episodeCount) || other.episodeCount == episodeCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seriesId,name,plot,genre,cast,cover,seasonCount,episodeCount);

@override
String toString() {
  return 'SeriesInfoDto(seriesId: $seriesId, name: $name, plot: $plot, genre: $genre, cast: $cast, cover: $cover, seasonCount: $seasonCount, episodeCount: $episodeCount)';
}


}

/// @nodoc
abstract mixin class _$SeriesInfoDtoCopyWith<$Res> implements $SeriesInfoDtoCopyWith<$Res> {
  factory _$SeriesInfoDtoCopyWith(_SeriesInfoDto value, $Res Function(_SeriesInfoDto) _then) = __$SeriesInfoDtoCopyWithImpl;
@override @useResult
$Res call({
 String seriesId, String name, String? plot, String? genre, String? cast, String? cover, int seasonCount, int episodeCount
});




}
/// @nodoc
class __$SeriesInfoDtoCopyWithImpl<$Res>
    implements _$SeriesInfoDtoCopyWith<$Res> {
  __$SeriesInfoDtoCopyWithImpl(this._self, this._then);

  final _SeriesInfoDto _self;
  final $Res Function(_SeriesInfoDto) _then;

/// Create a copy of SeriesInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seriesId = null,Object? name = null,Object? plot = freezed,Object? genre = freezed,Object? cast = freezed,Object? cover = freezed,Object? seasonCount = null,Object? episodeCount = null,}) {
  return _then(_SeriesInfoDto(
seriesId: null == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,plot: freezed == plot ? _self.plot : plot // ignore: cast_nullable_to_non_nullable
as String?,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,cast: freezed == cast ? _self.cast : cast // ignore: cast_nullable_to_non_nullable
as String?,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String?,seasonCount: null == seasonCount ? _self.seasonCount : seasonCount // ignore: cast_nullable_to_non_nullable
as int,episodeCount: null == episodeCount ? _self.episodeCount : episodeCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
