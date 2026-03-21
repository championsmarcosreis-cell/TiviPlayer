// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthResponseDto {

 UserInfoDto get userInfo; ServerInfoDto? get serverInfo;
/// Create a copy of AuthResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthResponseDtoCopyWith<AuthResponseDto> get copyWith => _$AuthResponseDtoCopyWithImpl<AuthResponseDto>(this as AuthResponseDto, _$identity);

  /// Serializes this AuthResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthResponseDto&&(identical(other.userInfo, userInfo) || other.userInfo == userInfo)&&(identical(other.serverInfo, serverInfo) || other.serverInfo == serverInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userInfo,serverInfo);

@override
String toString() {
  return 'AuthResponseDto(userInfo: $userInfo, serverInfo: $serverInfo)';
}


}

/// @nodoc
abstract mixin class $AuthResponseDtoCopyWith<$Res>  {
  factory $AuthResponseDtoCopyWith(AuthResponseDto value, $Res Function(AuthResponseDto) _then) = _$AuthResponseDtoCopyWithImpl;
@useResult
$Res call({
 UserInfoDto userInfo, ServerInfoDto? serverInfo
});


$UserInfoDtoCopyWith<$Res> get userInfo;$ServerInfoDtoCopyWith<$Res>? get serverInfo;

}
/// @nodoc
class _$AuthResponseDtoCopyWithImpl<$Res>
    implements $AuthResponseDtoCopyWith<$Res> {
  _$AuthResponseDtoCopyWithImpl(this._self, this._then);

  final AuthResponseDto _self;
  final $Res Function(AuthResponseDto) _then;

/// Create a copy of AuthResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userInfo = null,Object? serverInfo = freezed,}) {
  return _then(_self.copyWith(
userInfo: null == userInfo ? _self.userInfo : userInfo // ignore: cast_nullable_to_non_nullable
as UserInfoDto,serverInfo: freezed == serverInfo ? _self.serverInfo : serverInfo // ignore: cast_nullable_to_non_nullable
as ServerInfoDto?,
  ));
}
/// Create a copy of AuthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserInfoDtoCopyWith<$Res> get userInfo {
  
  return $UserInfoDtoCopyWith<$Res>(_self.userInfo, (value) {
    return _then(_self.copyWith(userInfo: value));
  });
}/// Create a copy of AuthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServerInfoDtoCopyWith<$Res>? get serverInfo {
    if (_self.serverInfo == null) {
    return null;
  }

  return $ServerInfoDtoCopyWith<$Res>(_self.serverInfo!, (value) {
    return _then(_self.copyWith(serverInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthResponseDto].
extension AuthResponseDtoPatterns on AuthResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _AuthResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _AuthResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserInfoDto userInfo,  ServerInfoDto? serverInfo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthResponseDto() when $default != null:
return $default(_that.userInfo,_that.serverInfo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserInfoDto userInfo,  ServerInfoDto? serverInfo)  $default,) {final _that = this;
switch (_that) {
case _AuthResponseDto():
return $default(_that.userInfo,_that.serverInfo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserInfoDto userInfo,  ServerInfoDto? serverInfo)?  $default,) {final _that = this;
switch (_that) {
case _AuthResponseDto() when $default != null:
return $default(_that.userInfo,_that.serverInfo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthResponseDto implements AuthResponseDto {
  const _AuthResponseDto({required this.userInfo, this.serverInfo});
  factory _AuthResponseDto.fromJson(Map<String, dynamic> json) => _$AuthResponseDtoFromJson(json);

@override final  UserInfoDto userInfo;
@override final  ServerInfoDto? serverInfo;

/// Create a copy of AuthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthResponseDtoCopyWith<_AuthResponseDto> get copyWith => __$AuthResponseDtoCopyWithImpl<_AuthResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthResponseDto&&(identical(other.userInfo, userInfo) || other.userInfo == userInfo)&&(identical(other.serverInfo, serverInfo) || other.serverInfo == serverInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userInfo,serverInfo);

@override
String toString() {
  return 'AuthResponseDto(userInfo: $userInfo, serverInfo: $serverInfo)';
}


}

/// @nodoc
abstract mixin class _$AuthResponseDtoCopyWith<$Res> implements $AuthResponseDtoCopyWith<$Res> {
  factory _$AuthResponseDtoCopyWith(_AuthResponseDto value, $Res Function(_AuthResponseDto) _then) = __$AuthResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 UserInfoDto userInfo, ServerInfoDto? serverInfo
});


@override $UserInfoDtoCopyWith<$Res> get userInfo;@override $ServerInfoDtoCopyWith<$Res>? get serverInfo;

}
/// @nodoc
class __$AuthResponseDtoCopyWithImpl<$Res>
    implements _$AuthResponseDtoCopyWith<$Res> {
  __$AuthResponseDtoCopyWithImpl(this._self, this._then);

  final _AuthResponseDto _self;
  final $Res Function(_AuthResponseDto) _then;

/// Create a copy of AuthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userInfo = null,Object? serverInfo = freezed,}) {
  return _then(_AuthResponseDto(
userInfo: null == userInfo ? _self.userInfo : userInfo // ignore: cast_nullable_to_non_nullable
as UserInfoDto,serverInfo: freezed == serverInfo ? _self.serverInfo : serverInfo // ignore: cast_nullable_to_non_nullable
as ServerInfoDto?,
  ));
}

/// Create a copy of AuthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserInfoDtoCopyWith<$Res> get userInfo {
  
  return $UserInfoDtoCopyWith<$Res>(_self.userInfo, (value) {
    return _then(_self.copyWith(userInfo: value));
  });
}/// Create a copy of AuthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServerInfoDtoCopyWith<$Res>? get serverInfo {
    if (_self.serverInfo == null) {
    return null;
  }

  return $ServerInfoDtoCopyWith<$Res>(_self.serverInfo!, (value) {
    return _then(_self.copyWith(serverInfo: value));
  });
}
}


/// @nodoc
mixin _$UserInfoDto {

 bool get auth; String? get status; String? get username; String? get password; String? get message; String? get expirationDate;
/// Create a copy of UserInfoDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserInfoDtoCopyWith<UserInfoDto> get copyWith => _$UserInfoDtoCopyWithImpl<UserInfoDto>(this as UserInfoDto, _$identity);

  /// Serializes this UserInfoDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserInfoDto&&(identical(other.auth, auth) || other.auth == auth)&&(identical(other.status, status) || other.status == status)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.message, message) || other.message == message)&&(identical(other.expirationDate, expirationDate) || other.expirationDate == expirationDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,auth,status,username,password,message,expirationDate);

@override
String toString() {
  return 'UserInfoDto(auth: $auth, status: $status, username: $username, password: $password, message: $message, expirationDate: $expirationDate)';
}


}

/// @nodoc
abstract mixin class $UserInfoDtoCopyWith<$Res>  {
  factory $UserInfoDtoCopyWith(UserInfoDto value, $Res Function(UserInfoDto) _then) = _$UserInfoDtoCopyWithImpl;
@useResult
$Res call({
 bool auth, String? status, String? username, String? password, String? message, String? expirationDate
});




}
/// @nodoc
class _$UserInfoDtoCopyWithImpl<$Res>
    implements $UserInfoDtoCopyWith<$Res> {
  _$UserInfoDtoCopyWithImpl(this._self, this._then);

  final UserInfoDto _self;
  final $Res Function(UserInfoDto) _then;

/// Create a copy of UserInfoDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? auth = null,Object? status = freezed,Object? username = freezed,Object? password = freezed,Object? message = freezed,Object? expirationDate = freezed,}) {
  return _then(_self.copyWith(
auth: null == auth ? _self.auth : auth // ignore: cast_nullable_to_non_nullable
as bool,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,expirationDate: freezed == expirationDate ? _self.expirationDate : expirationDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserInfoDto].
extension UserInfoDtoPatterns on UserInfoDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserInfoDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserInfoDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserInfoDto value)  $default,){
final _that = this;
switch (_that) {
case _UserInfoDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserInfoDto value)?  $default,){
final _that = this;
switch (_that) {
case _UserInfoDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool auth,  String? status,  String? username,  String? password,  String? message,  String? expirationDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserInfoDto() when $default != null:
return $default(_that.auth,_that.status,_that.username,_that.password,_that.message,_that.expirationDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool auth,  String? status,  String? username,  String? password,  String? message,  String? expirationDate)  $default,) {final _that = this;
switch (_that) {
case _UserInfoDto():
return $default(_that.auth,_that.status,_that.username,_that.password,_that.message,_that.expirationDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool auth,  String? status,  String? username,  String? password,  String? message,  String? expirationDate)?  $default,) {final _that = this;
switch (_that) {
case _UserInfoDto() when $default != null:
return $default(_that.auth,_that.status,_that.username,_that.password,_that.message,_that.expirationDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserInfoDto implements UserInfoDto {
  const _UserInfoDto({required this.auth, this.status, this.username, this.password, this.message, this.expirationDate});
  factory _UserInfoDto.fromJson(Map<String, dynamic> json) => _$UserInfoDtoFromJson(json);

@override final  bool auth;
@override final  String? status;
@override final  String? username;
@override final  String? password;
@override final  String? message;
@override final  String? expirationDate;

/// Create a copy of UserInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserInfoDtoCopyWith<_UserInfoDto> get copyWith => __$UserInfoDtoCopyWithImpl<_UserInfoDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserInfoDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserInfoDto&&(identical(other.auth, auth) || other.auth == auth)&&(identical(other.status, status) || other.status == status)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.message, message) || other.message == message)&&(identical(other.expirationDate, expirationDate) || other.expirationDate == expirationDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,auth,status,username,password,message,expirationDate);

@override
String toString() {
  return 'UserInfoDto(auth: $auth, status: $status, username: $username, password: $password, message: $message, expirationDate: $expirationDate)';
}


}

/// @nodoc
abstract mixin class _$UserInfoDtoCopyWith<$Res> implements $UserInfoDtoCopyWith<$Res> {
  factory _$UserInfoDtoCopyWith(_UserInfoDto value, $Res Function(_UserInfoDto) _then) = __$UserInfoDtoCopyWithImpl;
@override @useResult
$Res call({
 bool auth, String? status, String? username, String? password, String? message, String? expirationDate
});




}
/// @nodoc
class __$UserInfoDtoCopyWithImpl<$Res>
    implements _$UserInfoDtoCopyWith<$Res> {
  __$UserInfoDtoCopyWithImpl(this._self, this._then);

  final _UserInfoDto _self;
  final $Res Function(_UserInfoDto) _then;

/// Create a copy of UserInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? auth = null,Object? status = freezed,Object? username = freezed,Object? password = freezed,Object? message = freezed,Object? expirationDate = freezed,}) {
  return _then(_UserInfoDto(
auth: null == auth ? _self.auth : auth // ignore: cast_nullable_to_non_nullable
as bool,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,expirationDate: freezed == expirationDate ? _self.expirationDate : expirationDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ServerInfoDto {

 String? get url; String? get port; String? get httpsPort; String? get serverProtocol; String? get timezone;
/// Create a copy of ServerInfoDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerInfoDtoCopyWith<ServerInfoDto> get copyWith => _$ServerInfoDtoCopyWithImpl<ServerInfoDto>(this as ServerInfoDto, _$identity);

  /// Serializes this ServerInfoDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerInfoDto&&(identical(other.url, url) || other.url == url)&&(identical(other.port, port) || other.port == port)&&(identical(other.httpsPort, httpsPort) || other.httpsPort == httpsPort)&&(identical(other.serverProtocol, serverProtocol) || other.serverProtocol == serverProtocol)&&(identical(other.timezone, timezone) || other.timezone == timezone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,port,httpsPort,serverProtocol,timezone);

@override
String toString() {
  return 'ServerInfoDto(url: $url, port: $port, httpsPort: $httpsPort, serverProtocol: $serverProtocol, timezone: $timezone)';
}


}

/// @nodoc
abstract mixin class $ServerInfoDtoCopyWith<$Res>  {
  factory $ServerInfoDtoCopyWith(ServerInfoDto value, $Res Function(ServerInfoDto) _then) = _$ServerInfoDtoCopyWithImpl;
@useResult
$Res call({
 String? url, String? port, String? httpsPort, String? serverProtocol, String? timezone
});




}
/// @nodoc
class _$ServerInfoDtoCopyWithImpl<$Res>
    implements $ServerInfoDtoCopyWith<$Res> {
  _$ServerInfoDtoCopyWithImpl(this._self, this._then);

  final ServerInfoDto _self;
  final $Res Function(ServerInfoDto) _then;

/// Create a copy of ServerInfoDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = freezed,Object? port = freezed,Object? httpsPort = freezed,Object? serverProtocol = freezed,Object? timezone = freezed,}) {
  return _then(_self.copyWith(
url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,port: freezed == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as String?,httpsPort: freezed == httpsPort ? _self.httpsPort : httpsPort // ignore: cast_nullable_to_non_nullable
as String?,serverProtocol: freezed == serverProtocol ? _self.serverProtocol : serverProtocol // ignore: cast_nullable_to_non_nullable
as String?,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServerInfoDto].
extension ServerInfoDtoPatterns on ServerInfoDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServerInfoDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerInfoDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServerInfoDto value)  $default,){
final _that = this;
switch (_that) {
case _ServerInfoDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServerInfoDto value)?  $default,){
final _that = this;
switch (_that) {
case _ServerInfoDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? url,  String? port,  String? httpsPort,  String? serverProtocol,  String? timezone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerInfoDto() when $default != null:
return $default(_that.url,_that.port,_that.httpsPort,_that.serverProtocol,_that.timezone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? url,  String? port,  String? httpsPort,  String? serverProtocol,  String? timezone)  $default,) {final _that = this;
switch (_that) {
case _ServerInfoDto():
return $default(_that.url,_that.port,_that.httpsPort,_that.serverProtocol,_that.timezone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? url,  String? port,  String? httpsPort,  String? serverProtocol,  String? timezone)?  $default,) {final _that = this;
switch (_that) {
case _ServerInfoDto() when $default != null:
return $default(_that.url,_that.port,_that.httpsPort,_that.serverProtocol,_that.timezone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServerInfoDto implements ServerInfoDto {
  const _ServerInfoDto({this.url, this.port, this.httpsPort, this.serverProtocol, this.timezone});
  factory _ServerInfoDto.fromJson(Map<String, dynamic> json) => _$ServerInfoDtoFromJson(json);

@override final  String? url;
@override final  String? port;
@override final  String? httpsPort;
@override final  String? serverProtocol;
@override final  String? timezone;

/// Create a copy of ServerInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerInfoDtoCopyWith<_ServerInfoDto> get copyWith => __$ServerInfoDtoCopyWithImpl<_ServerInfoDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServerInfoDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerInfoDto&&(identical(other.url, url) || other.url == url)&&(identical(other.port, port) || other.port == port)&&(identical(other.httpsPort, httpsPort) || other.httpsPort == httpsPort)&&(identical(other.serverProtocol, serverProtocol) || other.serverProtocol == serverProtocol)&&(identical(other.timezone, timezone) || other.timezone == timezone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,port,httpsPort,serverProtocol,timezone);

@override
String toString() {
  return 'ServerInfoDto(url: $url, port: $port, httpsPort: $httpsPort, serverProtocol: $serverProtocol, timezone: $timezone)';
}


}

/// @nodoc
abstract mixin class _$ServerInfoDtoCopyWith<$Res> implements $ServerInfoDtoCopyWith<$Res> {
  factory _$ServerInfoDtoCopyWith(_ServerInfoDto value, $Res Function(_ServerInfoDto) _then) = __$ServerInfoDtoCopyWithImpl;
@override @useResult
$Res call({
 String? url, String? port, String? httpsPort, String? serverProtocol, String? timezone
});




}
/// @nodoc
class __$ServerInfoDtoCopyWithImpl<$Res>
    implements _$ServerInfoDtoCopyWith<$Res> {
  __$ServerInfoDtoCopyWithImpl(this._self, this._then);

  final _ServerInfoDto _self;
  final $Res Function(_ServerInfoDto) _then;

/// Create a copy of ServerInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = freezed,Object? port = freezed,Object? httpsPort = freezed,Object? serverProtocol = freezed,Object? timezone = freezed,}) {
  return _then(_ServerInfoDto(
url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,port: freezed == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as String?,httpsPort: freezed == httpsPort ? _self.httpsPort : httpsPort // ignore: cast_nullable_to_non_nullable
as String?,serverProtocol: freezed == serverProtocol ? _self.serverProtocol : serverProtocol // ignore: cast_nullable_to_non_nullable
as String?,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
