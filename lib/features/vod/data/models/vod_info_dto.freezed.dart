// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vod_info_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VodInfoDto {

 String get streamId; String get name; String? get plot; String? get genre; String? get cast; String? get director; String? get duration; String? get releaseDate; String? get coverBig; String? get rating; String? get containerExtension;
/// Create a copy of VodInfoDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VodInfoDtoCopyWith<VodInfoDto> get copyWith => _$VodInfoDtoCopyWithImpl<VodInfoDto>(this as VodInfoDto, _$identity);

  /// Serializes this VodInfoDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VodInfoDto&&(identical(other.streamId, streamId) || other.streamId == streamId)&&(identical(other.name, name) || other.name == name)&&(identical(other.plot, plot) || other.plot == plot)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.cast, cast) || other.cast == cast)&&(identical(other.director, director) || other.director == director)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.releaseDate, releaseDate) || other.releaseDate == releaseDate)&&(identical(other.coverBig, coverBig) || other.coverBig == coverBig)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.containerExtension, containerExtension) || other.containerExtension == containerExtension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streamId,name,plot,genre,cast,director,duration,releaseDate,coverBig,rating,containerExtension);

@override
String toString() {
  return 'VodInfoDto(streamId: $streamId, name: $name, plot: $plot, genre: $genre, cast: $cast, director: $director, duration: $duration, releaseDate: $releaseDate, coverBig: $coverBig, rating: $rating, containerExtension: $containerExtension)';
}


}

/// @nodoc
abstract mixin class $VodInfoDtoCopyWith<$Res>  {
  factory $VodInfoDtoCopyWith(VodInfoDto value, $Res Function(VodInfoDto) _then) = _$VodInfoDtoCopyWithImpl;
@useResult
$Res call({
 String streamId, String name, String? plot, String? genre, String? cast, String? director, String? duration, String? releaseDate, String? coverBig, String? rating, String? containerExtension
});




}
/// @nodoc
class _$VodInfoDtoCopyWithImpl<$Res>
    implements $VodInfoDtoCopyWith<$Res> {
  _$VodInfoDtoCopyWithImpl(this._self, this._then);

  final VodInfoDto _self;
  final $Res Function(VodInfoDto) _then;

/// Create a copy of VodInfoDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? streamId = null,Object? name = null,Object? plot = freezed,Object? genre = freezed,Object? cast = freezed,Object? director = freezed,Object? duration = freezed,Object? releaseDate = freezed,Object? coverBig = freezed,Object? rating = freezed,Object? containerExtension = freezed,}) {
  return _then(_self.copyWith(
streamId: null == streamId ? _self.streamId : streamId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,plot: freezed == plot ? _self.plot : plot // ignore: cast_nullable_to_non_nullable
as String?,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,cast: freezed == cast ? _self.cast : cast // ignore: cast_nullable_to_non_nullable
as String?,director: freezed == director ? _self.director : director // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String?,releaseDate: freezed == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String?,coverBig: freezed == coverBig ? _self.coverBig : coverBig // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as String?,containerExtension: freezed == containerExtension ? _self.containerExtension : containerExtension // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VodInfoDto].
extension VodInfoDtoPatterns on VodInfoDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VodInfoDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VodInfoDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VodInfoDto value)  $default,){
final _that = this;
switch (_that) {
case _VodInfoDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VodInfoDto value)?  $default,){
final _that = this;
switch (_that) {
case _VodInfoDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String streamId,  String name,  String? plot,  String? genre,  String? cast,  String? director,  String? duration,  String? releaseDate,  String? coverBig,  String? rating,  String? containerExtension)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VodInfoDto() when $default != null:
return $default(_that.streamId,_that.name,_that.plot,_that.genre,_that.cast,_that.director,_that.duration,_that.releaseDate,_that.coverBig,_that.rating,_that.containerExtension);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String streamId,  String name,  String? plot,  String? genre,  String? cast,  String? director,  String? duration,  String? releaseDate,  String? coverBig,  String? rating,  String? containerExtension)  $default,) {final _that = this;
switch (_that) {
case _VodInfoDto():
return $default(_that.streamId,_that.name,_that.plot,_that.genre,_that.cast,_that.director,_that.duration,_that.releaseDate,_that.coverBig,_that.rating,_that.containerExtension);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String streamId,  String name,  String? plot,  String? genre,  String? cast,  String? director,  String? duration,  String? releaseDate,  String? coverBig,  String? rating,  String? containerExtension)?  $default,) {final _that = this;
switch (_that) {
case _VodInfoDto() when $default != null:
return $default(_that.streamId,_that.name,_that.plot,_that.genre,_that.cast,_that.director,_that.duration,_that.releaseDate,_that.coverBig,_that.rating,_that.containerExtension);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VodInfoDto implements VodInfoDto {
  const _VodInfoDto({required this.streamId, required this.name, this.plot, this.genre, this.cast, this.director, this.duration, this.releaseDate, this.coverBig, this.rating, this.containerExtension});
  factory _VodInfoDto.fromJson(Map<String, dynamic> json) => _$VodInfoDtoFromJson(json);

@override final  String streamId;
@override final  String name;
@override final  String? plot;
@override final  String? genre;
@override final  String? cast;
@override final  String? director;
@override final  String? duration;
@override final  String? releaseDate;
@override final  String? coverBig;
@override final  String? rating;
@override final  String? containerExtension;

/// Create a copy of VodInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VodInfoDtoCopyWith<_VodInfoDto> get copyWith => __$VodInfoDtoCopyWithImpl<_VodInfoDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VodInfoDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VodInfoDto&&(identical(other.streamId, streamId) || other.streamId == streamId)&&(identical(other.name, name) || other.name == name)&&(identical(other.plot, plot) || other.plot == plot)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.cast, cast) || other.cast == cast)&&(identical(other.director, director) || other.director == director)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.releaseDate, releaseDate) || other.releaseDate == releaseDate)&&(identical(other.coverBig, coverBig) || other.coverBig == coverBig)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.containerExtension, containerExtension) || other.containerExtension == containerExtension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streamId,name,plot,genre,cast,director,duration,releaseDate,coverBig,rating,containerExtension);

@override
String toString() {
  return 'VodInfoDto(streamId: $streamId, name: $name, plot: $plot, genre: $genre, cast: $cast, director: $director, duration: $duration, releaseDate: $releaseDate, coverBig: $coverBig, rating: $rating, containerExtension: $containerExtension)';
}


}

/// @nodoc
abstract mixin class _$VodInfoDtoCopyWith<$Res> implements $VodInfoDtoCopyWith<$Res> {
  factory _$VodInfoDtoCopyWith(_VodInfoDto value, $Res Function(_VodInfoDto) _then) = __$VodInfoDtoCopyWithImpl;
@override @useResult
$Res call({
 String streamId, String name, String? plot, String? genre, String? cast, String? director, String? duration, String? releaseDate, String? coverBig, String? rating, String? containerExtension
});




}
/// @nodoc
class __$VodInfoDtoCopyWithImpl<$Res>
    implements _$VodInfoDtoCopyWith<$Res> {
  __$VodInfoDtoCopyWithImpl(this._self, this._then);

  final _VodInfoDto _self;
  final $Res Function(_VodInfoDto) _then;

/// Create a copy of VodInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? streamId = null,Object? name = null,Object? plot = freezed,Object? genre = freezed,Object? cast = freezed,Object? director = freezed,Object? duration = freezed,Object? releaseDate = freezed,Object? coverBig = freezed,Object? rating = freezed,Object? containerExtension = freezed,}) {
  return _then(_VodInfoDto(
streamId: null == streamId ? _self.streamId : streamId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,plot: freezed == plot ? _self.plot : plot // ignore: cast_nullable_to_non_nullable
as String?,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,cast: freezed == cast ? _self.cast : cast // ignore: cast_nullable_to_non_nullable
as String?,director: freezed == director ? _self.director : director // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String?,releaseDate: freezed == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String?,coverBig: freezed == coverBig ? _self.coverBig : coverBig // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as String?,containerExtension: freezed == containerExtension ? _self.containerExtension : containerExtension // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
