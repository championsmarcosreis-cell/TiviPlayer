import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/xtream_parsers.dart';

part 'auth_response_dto.freezed.dart';
part 'auth_response_dto.g.dart';

@freezed
abstract class AuthResponseDto with _$AuthResponseDto {
  const factory AuthResponseDto({
    required UserInfoDto userInfo,
    ServerInfoDto? serverInfo,
  }) = _AuthResponseDto;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);

  factory AuthResponseDto.fromApi(Map<String, dynamic> json) {
    final userInfo = XtreamParsers.asMap(json['user_info']) ?? const {};
    final serverInfo = XtreamParsers.asMap(json['server_info']);

    return AuthResponseDto(
      userInfo: UserInfoDto.fromApi(userInfo),
      serverInfo: serverInfo == null ? null : ServerInfoDto.fromApi(serverInfo),
    );
  }
}

@freezed
abstract class UserInfoDto with _$UserInfoDto {
  const factory UserInfoDto({
    required bool auth,
    String? status,
    String? username,
    String? password,
    String? message,
    String? expirationDate,
  }) = _UserInfoDto;

  factory UserInfoDto.fromJson(Map<String, dynamic> json) =>
      _$UserInfoDtoFromJson(json);

  factory UserInfoDto.fromApi(Map<String, dynamic> json) {
    return UserInfoDto(
      auth: XtreamParsers.asBool(json['auth']),
      status: XtreamParsers.asString(json['status']),
      username: XtreamParsers.asString(json['username']),
      password: XtreamParsers.asString(json['password']),
      message: XtreamParsers.asString(json['message']),
      expirationDate: XtreamParsers.asString(json['exp_date']),
    );
  }
}

@freezed
abstract class ServerInfoDto with _$ServerInfoDto {
  const factory ServerInfoDto({
    String? url,
    String? port,
    String? httpsPort,
    String? serverProtocol,
    String? timezone,
  }) = _ServerInfoDto;

  factory ServerInfoDto.fromJson(Map<String, dynamic> json) =>
      _$ServerInfoDtoFromJson(json);

  factory ServerInfoDto.fromApi(Map<String, dynamic> json) {
    return ServerInfoDto(
      url: XtreamParsers.asString(json['url']),
      port: XtreamParsers.asString(json['port']),
      httpsPort: XtreamParsers.asString(json['https_port']),
      serverProtocol: XtreamParsers.asString(json['server_protocol']),
      timezone: XtreamParsers.asString(json['timezone']),
    );
  }
}
