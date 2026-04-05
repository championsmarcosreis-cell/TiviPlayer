// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vod_stream_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VodStreamDto {

 String get streamId; String get name; String? get categoryId; String? get streamIcon; String? get containerExtension; String? get rating; String? get libraryKind;
/// Create a copy of VodStreamDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VodStreamDtoCopyWith<VodStreamDto> get copyWith => _$VodStreamDtoCopyWithImpl<VodStreamDto>(this as VodStreamDto, _$identity);

  /// Serializes this VodStreamDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VodStreamDto&&(identical(other.streamId, streamId) || other.streamId == streamId)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.streamIcon, streamIcon) || other.streamIcon == streamIcon)&&(identical(other.containerExtension, containerExtension) || other.containerExtension == containerExtension)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.libraryKind, libraryKind) || other.libraryKind == libraryKind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streamId,name,categoryId,streamIcon,containerExtension,rating,libraryKind);

@override
String toString() {
  return 'VodStreamDto(streamId: $streamId, name: $name, categoryId: $categoryId, streamIcon: $streamIcon, containerExtension: $containerExtension, rating: $rating, libraryKind: $libraryKind)';
}


}

/// @nodoc
abstract mixin class $VodStreamDtoCopyWith<$Res>  {
  factory $VodStreamDtoCopyWith(VodStreamDto value, $Res Function(VodStreamDto) _then) = _$VodStreamDtoCopyWithImpl;
@useResult
$Res call({
 String streamId, String name, String? categoryId, String? streamIcon, String? containerExtension, String? rating, String? libraryKind
});




}
/// @nodoc
class _$VodStreamDtoCopyWithImpl<$Res>
    implements $VodStreamDtoCopyWith<$Res> {
  _$VodStreamDtoCopyWithImpl(this._self, this._then);

  final VodStreamDto _self;
  final $Res Function(VodStreamDto) _then;

/// Create a copy of VodStreamDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? streamId = null,Object? name = null,Object? categoryId = freezed,Object? streamIcon = freezed,Object? containerExtension = freezed,Object? rating = freezed,Object? libraryKind = freezed,}) {
  return _then(_self.copyWith(
streamId: null == streamId ? _self.streamId : streamId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,streamIcon: freezed == streamIcon ? _self.streamIcon : streamIcon // ignore: cast_nullable_to_non_nullable
as String?,containerExtension: freezed == containerExtension ? _self.containerExtension : containerExtension // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as String?,libraryKind: freezed == libraryKind ? _self.libraryKind : libraryKind // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VodStreamDto].
extension VodStreamDtoPatterns on VodStreamDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VodStreamDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VodStreamDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VodStreamDto value)  $default,){
final _that = this;
switch (_that) {
case _VodStreamDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VodStreamDto value)?  $default,){
final _that = this;
switch (_that) {
case _VodStreamDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String streamId,  String name,  String? categoryId,  String? streamIcon,  String? containerExtension,  String? rating,  String? libraryKind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VodStreamDto() when $default != null:
return $default(_that.streamId,_that.name,_that.categoryId,_that.streamIcon,_that.containerExtension,_that.rating,_that.libraryKind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String streamId,  String name,  String? categoryId,  String? streamIcon,  String? containerExtension,  String? rating,  String? libraryKind)  $default,) {final _that = this;
switch (_that) {
case _VodStreamDto():
return $default(_that.streamId,_that.name,_that.categoryId,_that.streamIcon,_that.containerExtension,_that.rating,_that.libraryKind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String streamId,  String name,  String? categoryId,  String? streamIcon,  String? containerExtension,  String? rating,  String? libraryKind)?  $default,) {final _that = this;
switch (_that) {
case _VodStreamDto() when $default != null:
return $default(_that.streamId,_that.name,_that.categoryId,_that.streamIcon,_that.containerExtension,_that.rating,_that.libraryKind);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VodStreamDto implements VodStreamDto {
  const _VodStreamDto({required this.streamId, required this.name, this.categoryId, this.streamIcon, this.containerExtension, this.rating, this.libraryKind});
  factory _VodStreamDto.fromJson(Map<String, dynamic> json) => _$VodStreamDtoFromJson(json);

@override final  String streamId;
@override final  String name;
@override final  String? categoryId;
@override final  String? streamIcon;
@override final  String? containerExtension;
@override final  String? rating;
@override final  String? libraryKind;

/// Create a copy of VodStreamDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VodStreamDtoCopyWith<_VodStreamDto> get copyWith => __$VodStreamDtoCopyWithImpl<_VodStreamDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VodStreamDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VodStreamDto&&(identical(other.streamId, streamId) || other.streamId == streamId)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.streamIcon, streamIcon) || other.streamIcon == streamIcon)&&(identical(other.containerExtension, containerExtension) || other.containerExtension == containerExtension)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.libraryKind, libraryKind) || other.libraryKind == libraryKind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streamId,name,categoryId,streamIcon,containerExtension,rating,libraryKind);

@override
String toString() {
  return 'VodStreamDto(streamId: $streamId, name: $name, categoryId: $categoryId, streamIcon: $streamIcon, containerExtension: $containerExtension, rating: $rating, libraryKind: $libraryKind)';
}


}

/// @nodoc
abstract mixin class _$VodStreamDtoCopyWith<$Res> implements $VodStreamDtoCopyWith<$Res> {
  factory _$VodStreamDtoCopyWith(_VodStreamDto value, $Res Function(_VodStreamDto) _then) = __$VodStreamDtoCopyWithImpl;
@override @useResult
$Res call({
 String streamId, String name, String? categoryId, String? streamIcon, String? containerExtension, String? rating, String? libraryKind
});




}
/// @nodoc
class __$VodStreamDtoCopyWithImpl<$Res>
    implements _$VodStreamDtoCopyWith<$Res> {
  __$VodStreamDtoCopyWithImpl(this._self, this._then);

  final _VodStreamDto _self;
  final $Res Function(_VodStreamDto) _then;

/// Create a copy of VodStreamDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? streamId = null,Object? name = null,Object? categoryId = freezed,Object? streamIcon = freezed,Object? containerExtension = freezed,Object? rating = freezed,Object? libraryKind = freezed,}) {
  return _then(_VodStreamDto(
streamId: null == streamId ? _self.streamId : streamId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,streamIcon: freezed == streamIcon ? _self.streamIcon : streamIcon // ignore: cast_nullable_to_non_nullable
as String?,containerExtension: freezed == containerExtension ? _self.containerExtension : containerExtension // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as String?,libraryKind: freezed == libraryKind ? _self.libraryKind : libraryKind // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
