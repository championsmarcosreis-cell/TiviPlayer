// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'series_category_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SeriesCategoryDto {

 String get categoryId; String get categoryName; String? get parentId;
/// Create a copy of SeriesCategoryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeriesCategoryDtoCopyWith<SeriesCategoryDto> get copyWith => _$SeriesCategoryDtoCopyWithImpl<SeriesCategoryDto>(this as SeriesCategoryDto, _$identity);

  /// Serializes this SeriesCategoryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeriesCategoryDto&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.parentId, parentId) || other.parentId == parentId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryId,categoryName,parentId);

@override
String toString() {
  return 'SeriesCategoryDto(categoryId: $categoryId, categoryName: $categoryName, parentId: $parentId)';
}


}

/// @nodoc
abstract mixin class $SeriesCategoryDtoCopyWith<$Res>  {
  factory $SeriesCategoryDtoCopyWith(SeriesCategoryDto value, $Res Function(SeriesCategoryDto) _then) = _$SeriesCategoryDtoCopyWithImpl;
@useResult
$Res call({
 String categoryId, String categoryName, String? parentId
});




}
/// @nodoc
class _$SeriesCategoryDtoCopyWithImpl<$Res>
    implements $SeriesCategoryDtoCopyWith<$Res> {
  _$SeriesCategoryDtoCopyWithImpl(this._self, this._then);

  final SeriesCategoryDto _self;
  final $Res Function(SeriesCategoryDto) _then;

/// Create a copy of SeriesCategoryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = null,Object? categoryName = null,Object? parentId = freezed,}) {
  return _then(_self.copyWith(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SeriesCategoryDto].
extension SeriesCategoryDtoPatterns on SeriesCategoryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeriesCategoryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeriesCategoryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeriesCategoryDto value)  $default,){
final _that = this;
switch (_that) {
case _SeriesCategoryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeriesCategoryDto value)?  $default,){
final _that = this;
switch (_that) {
case _SeriesCategoryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String categoryId,  String categoryName,  String? parentId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeriesCategoryDto() when $default != null:
return $default(_that.categoryId,_that.categoryName,_that.parentId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String categoryId,  String categoryName,  String? parentId)  $default,) {final _that = this;
switch (_that) {
case _SeriesCategoryDto():
return $default(_that.categoryId,_that.categoryName,_that.parentId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String categoryId,  String categoryName,  String? parentId)?  $default,) {final _that = this;
switch (_that) {
case _SeriesCategoryDto() when $default != null:
return $default(_that.categoryId,_that.categoryName,_that.parentId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeriesCategoryDto implements SeriesCategoryDto {
  const _SeriesCategoryDto({required this.categoryId, required this.categoryName, this.parentId});
  factory _SeriesCategoryDto.fromJson(Map<String, dynamic> json) => _$SeriesCategoryDtoFromJson(json);

@override final  String categoryId;
@override final  String categoryName;
@override final  String? parentId;

/// Create a copy of SeriesCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeriesCategoryDtoCopyWith<_SeriesCategoryDto> get copyWith => __$SeriesCategoryDtoCopyWithImpl<_SeriesCategoryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeriesCategoryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeriesCategoryDto&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.parentId, parentId) || other.parentId == parentId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryId,categoryName,parentId);

@override
String toString() {
  return 'SeriesCategoryDto(categoryId: $categoryId, categoryName: $categoryName, parentId: $parentId)';
}


}

/// @nodoc
abstract mixin class _$SeriesCategoryDtoCopyWith<$Res> implements $SeriesCategoryDtoCopyWith<$Res> {
  factory _$SeriesCategoryDtoCopyWith(_SeriesCategoryDto value, $Res Function(_SeriesCategoryDto) _then) = __$SeriesCategoryDtoCopyWithImpl;
@override @useResult
$Res call({
 String categoryId, String categoryName, String? parentId
});




}
/// @nodoc
class __$SeriesCategoryDtoCopyWithImpl<$Res>
    implements _$SeriesCategoryDtoCopyWith<$Res> {
  __$SeriesCategoryDtoCopyWithImpl(this._self, this._then);

  final _SeriesCategoryDto _self;
  final $Res Function(_SeriesCategoryDto) _then;

/// Create a copy of SeriesCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = null,Object? categoryName = null,Object? parentId = freezed,}) {
  return _then(_SeriesCategoryDto(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
