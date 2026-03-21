// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthResponseDto _$AuthResponseDtoFromJson(Map<String, dynamic> json) =>
    _AuthResponseDto(
      userInfo: UserInfoDto.fromJson(json['userInfo'] as Map<String, dynamic>),
      serverInfo: json['serverInfo'] == null
          ? null
          : ServerInfoDto.fromJson(json['serverInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseDtoToJson(_AuthResponseDto instance) =>
    <String, dynamic>{
      'userInfo': instance.userInfo,
      'serverInfo': instance.serverInfo,
    };

_UserInfoDto _$UserInfoDtoFromJson(Map<String, dynamic> json) => _UserInfoDto(
  auth: json['auth'] as bool,
  status: json['status'] as String?,
  username: json['username'] as String?,
  password: json['password'] as String?,
  message: json['message'] as String?,
  expirationDate: json['expirationDate'] as String?,
);

Map<String, dynamic> _$UserInfoDtoToJson(_UserInfoDto instance) =>
    <String, dynamic>{
      'auth': instance.auth,
      'status': instance.status,
      'username': instance.username,
      'password': instance.password,
      'message': instance.message,
      'expirationDate': instance.expirationDate,
    };

_ServerInfoDto _$ServerInfoDtoFromJson(Map<String, dynamic> json) =>
    _ServerInfoDto(
      url: json['url'] as String?,
      port: json['port'] as String?,
      httpsPort: json['httpsPort'] as String?,
      serverProtocol: json['serverProtocol'] as String?,
      timezone: json['timezone'] as String?,
    );

Map<String, dynamic> _$ServerInfoDtoToJson(_ServerInfoDto instance) =>
    <String, dynamic>{
      'url': instance.url,
      'port': instance.port,
      'httpsPort': instance.httpsPort,
      'serverProtocol': instance.serverProtocol,
      'timezone': instance.timezone,
    };
