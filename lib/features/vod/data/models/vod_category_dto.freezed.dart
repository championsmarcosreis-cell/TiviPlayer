// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vod_category_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VodCategoryDto {

 String get categoryId; String get categoryName; String? get parentId; String? get libraryKind;
/// Create a copy of VodCategoryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VodCategoryDtoCopyWith<VodCategoryDto> get copyWith => _$VodCategoryDtoCopyWithImpl<VodCategoryDto>(this as VodCategoryDto, _$identity);

  /// Serializes this VodCategoryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VodCategoryDto&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.libraryKind, libraryKind) || other.libraryKind == libraryKind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryId,categoryName,parentId,libraryKind);

@override
String toString() {
  return 'VodCategoryDto(categoryId: $categoryId, categoryName: $categoryName, parentId: $parentId, libraryKind: $libraryKind)';
}


}

/// @nodoc
abstract mixin class $VodCategoryDtoCopyWith<$Res>  {
  factory $VodCategoryDtoCopyWith(VodCategoryDto value, $Res Function(VodCategoryDto) _then) = _$VodCategoryDtoCopyWithImpl;
@useResult
$Res call({
 String categoryId, String categoryName, String? parentId, String? libraryKind
});




}
/// @nodoc
class _$VodCategoryDtoCopyWithImpl<$Res>
    implements $VodCategoryDtoCopyWith<$Res> {
  _$VodCategoryDtoCopyWithImpl(this._self, this._then);

  final VodCategoryDto _self;
  final $Res Function(VodCategoryDto) _then;

/// Create a copy of VodCategoryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = null,Object? categoryName = null,Object? parentId = freezed,Object? libraryKind = freezed,}) {
  return _then(_self.copyWith(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,libraryKind: freezed == libraryKind ? _self.libraryKind : libraryKind // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VodCategoryDto].
extension VodCategoryDtoPatterns on VodCategoryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VodCategoryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VodCategoryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VodCategoryDto value)  $default,){
final _that = this;
switch (_that) {
case _VodCategoryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VodCategoryDto value)?  $default,){
final _that = this;
switch (_that) {
case _VodCategoryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String categoryId,  String categoryName,  String? parentId,  String? libraryKind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VodCategoryDto() when $default != null:
return $default(_that.categoryId,_that.categoryName,_that.parentId,_that.libraryKind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String categoryId,  String categoryName,  String? parentId,  String? libraryKind)  $default,) {final _that = this;
switch (_that) {
case _VodCategoryDto():
return $default(_that.categoryId,_that.categoryName,_that.parentId,_that.libraryKind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String categoryId,  String categoryName,  String? parentId,  String? libraryKind)?  $default,) {final _that = this;
switch (_that) {
case _VodCategoryDto() when $default != null:
return $default(_that.categoryId,_that.categoryName,_that.parentId,_that.libraryKind);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VodCategoryDto implements VodCategoryDto {
  const _VodCategoryDto({required this.categoryId, required this.categoryName, this.parentId, this.libraryKind});
  factory _VodCategoryDto.fromJson(Map<String, dynamic> json) => _$VodCategoryDtoFromJson(json);

@override final  String categoryId;
@override final  String categoryName;
@override final  String? parentId;
@override final  String? libraryKind;

/// Create a copy of VodCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VodCategoryDtoCopyWith<_VodCategoryDto> get copyWith => __$VodCategoryDtoCopyWithImpl<_VodCategoryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VodCategoryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VodCategoryDto&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.libraryKind, libraryKind) || other.libraryKind == libraryKind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryId,categoryName,parentId,libraryKind);

@override
String toString() {
  return 'VodCategoryDto(categoryId: $categoryId, categoryName: $categoryName, parentId: $parentId, libraryKind: $libraryKind)';
}


}

/// @nodoc
abstract mixin class _$VodCategoryDtoCopyWith<$Res> implements $VodCategoryDtoCopyWith<$Res> {
  factory _$VodCategoryDtoCopyWith(_VodCategoryDto value, $Res Function(_VodCategoryDto) _then) = __$VodCategoryDtoCopyWithImpl;
@override @useResult
$Res call({
 String categoryId, String categoryName, String? parentId, String? libraryKind
});




}
/// @nodoc
class __$VodCategoryDtoCopyWithImpl<$Res>
    implements _$VodCategoryDtoCopyWith<$Res> {
  __$VodCategoryDtoCopyWithImpl(this._self, this._then);

  final _VodCategoryDto _self;
  final $Res Function(_VodCategoryDto) _then;

/// Create a copy of VodCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = null,Object? categoryName = null,Object? parentId = freezed,Object? libraryKind = freezed,}) {
  return _then(_VodCategoryDto(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,libraryKind: freezed == libraryKind ? _self.libraryKind : libraryKind // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
