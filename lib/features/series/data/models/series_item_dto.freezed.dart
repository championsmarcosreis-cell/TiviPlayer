// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'series_item_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SeriesItemDto {

 String get seriesId; String get name; String? get categoryId; String? get cover; String? get plot;
/// Create a copy of SeriesItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeriesItemDtoCopyWith<SeriesItemDto> get copyWith => _$SeriesItemDtoCopyWithImpl<SeriesItemDto>(this as SeriesItemDto, _$identity);

  /// Serializes this SeriesItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeriesItemDto&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.plot, plot) || other.plot == plot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seriesId,name,categoryId,cover,plot);

@override
String toString() {
  return 'SeriesItemDto(seriesId: $seriesId, name: $name, categoryId: $categoryId, cover: $cover, plot: $plot)';
}


}

/// @nodoc
abstract mixin class $SeriesItemDtoCopyWith<$Res>  {
  factory $SeriesItemDtoCopyWith(SeriesItemDto value, $Res Function(SeriesItemDto) _then) = _$SeriesItemDtoCopyWithImpl;
@useResult
$Res call({
 String seriesId, String name, String? categoryId, String? cover, String? plot
});




}
/// @nodoc
class _$SeriesItemDtoCopyWithImpl<$Res>
    implements $SeriesItemDtoCopyWith<$Res> {
  _$SeriesItemDtoCopyWithImpl(this._self, this._then);

  final SeriesItemDto _self;
  final $Res Function(SeriesItemDto) _then;

/// Create a copy of SeriesItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seriesId = null,Object? name = null,Object? categoryId = freezed,Object? cover = freezed,Object? plot = freezed,}) {
  return _then(_self.copyWith(
seriesId: null == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String?,plot: freezed == plot ? _self.plot : plot // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SeriesItemDto].
extension SeriesItemDtoPatterns on SeriesItemDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeriesItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeriesItemDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeriesItemDto value)  $default,){
final _that = this;
switch (_that) {
case _SeriesItemDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeriesItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _SeriesItemDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String seriesId,  String name,  String? categoryId,  String? cover,  String? plot)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeriesItemDto() when $default != null:
return $default(_that.seriesId,_that.name,_that.categoryId,_that.cover,_that.plot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String seriesId,  String name,  String? categoryId,  String? cover,  String? plot)  $default,) {final _that = this;
switch (_that) {
case _SeriesItemDto():
return $default(_that.seriesId,_that.name,_that.categoryId,_that.cover,_that.plot);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String seriesId,  String name,  String? categoryId,  String? cover,  String? plot)?  $default,) {final _that = this;
switch (_that) {
case _SeriesItemDto() when $default != null:
return $default(_that.seriesId,_that.name,_that.categoryId,_that.cover,_that.plot);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeriesItemDto implements SeriesItemDto {
  const _SeriesItemDto({required this.seriesId, required this.name, this.categoryId, this.cover, this.plot});
  factory _SeriesItemDto.fromJson(Map<String, dynamic> json) => _$SeriesItemDtoFromJson(json);

@override final  String seriesId;
@override final  String name;
@override final  String? categoryId;
@override final  String? cover;
@override final  String? plot;

/// Create a copy of SeriesItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeriesItemDtoCopyWith<_SeriesItemDto> get copyWith => __$SeriesItemDtoCopyWithImpl<_SeriesItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeriesItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeriesItemDto&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.plot, plot) || other.plot == plot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seriesId,name,categoryId,cover,plot);

@override
String toString() {
  return 'SeriesItemDto(seriesId: $seriesId, name: $name, categoryId: $categoryId, cover: $cover, plot: $plot)';
}


}

/// @nodoc
abstract mixin class _$SeriesItemDtoCopyWith<$Res> implements $SeriesItemDtoCopyWith<$Res> {
  factory _$SeriesItemDtoCopyWith(_SeriesItemDto value, $Res Function(_SeriesItemDto) _then) = __$SeriesItemDtoCopyWithImpl;
@override @useResult
$Res call({
 String seriesId, String name, String? categoryId, String? cover, String? plot
});




}
/// @nodoc
class __$SeriesItemDtoCopyWithImpl<$Res>
    implements _$SeriesItemDtoCopyWith<$Res> {
  __$SeriesItemDtoCopyWithImpl(this._self, this._then);

  final _SeriesItemDto _self;
  final $Res Function(_SeriesItemDto) _then;

/// Create a copy of SeriesItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seriesId = null,Object? name = null,Object? categoryId = freezed,Object? cover = freezed,Object? plot = freezed,}) {
  return _then(_SeriesItemDto(
seriesId: null == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String?,plot: freezed == plot ? _self.plot : plot // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
