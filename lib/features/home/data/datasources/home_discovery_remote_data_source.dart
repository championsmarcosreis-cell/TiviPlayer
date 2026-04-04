import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/xtream_client.dart';
import '../../../../core/network/xtream_parsers.dart';
import '../../../auth/domain/entities/xtream_session.dart';
import '../models/home_discovery_dto.dart';

class HomeDiscoveryRemoteDataSource {
  const HomeDiscoveryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<HomeDiscoveryDto?> fetchHome(
    XtreamSession session, {
    int limit = 12,
  }) async {
    final baseUrl = XtreamClient.normalizeBaseUrl(
      session.credentials.normalizedBaseUrl,
    );

    try {
      final token = await _fetchToken(
        baseUrl: baseUrl,
        username: session.credentials.username,
        password: session.credentials.password,
      );
      if (token == null || token.isEmpty) {
        return null;
      }

      final discoveryUri = Uri.parse(
        '$baseUrl/api/delivery/discovery',
      ).replace(queryParameters: {'limit': limit.toString()});
      final discoveryResponse = await _dio.getUri<dynamic>(
        discoveryUri,
        options: _requestOptions(headers: {'Authorization': 'Bearer $token'}),
      );

      if (discoveryResponse.statusCode == null ||
          discoveryResponse.statusCode! < 200 ||
          discoveryResponse.statusCode! >= 300) {
        return null;
      }

      final payload = _decodeMap(discoveryResponse.data);
      if (payload == null || XtreamParsers.asMap(payload['home']) == null) {
        return null;
      }

      return HomeDiscoveryDto.fromApi(payload);
    } on DioException {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<String?> _fetchToken({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final loginUri = Uri.parse('$baseUrl/api/auth/login');
    final loginResponse = await _dio.postUri<dynamic>(
      loginUri,
      data: jsonEncode({'username': username, 'password': password}),
      options: _requestOptions(),
    );

    if (loginResponse.statusCode == null ||
        loginResponse.statusCode! < 200 ||
        loginResponse.statusCode! >= 300) {
      return null;
    }

    final payload = _decodeMap(loginResponse.data);
    if (payload == null) {
      return null;
    }

    return XtreamParsers.asString(payload['token']);
  }

  Map<String, dynamic>? _decodeMap(dynamic data) {
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(trimmed);
      return XtreamParsers.asMap(decoded);
    }
    return XtreamParsers.asMap(data);
  }

  Options _requestOptions({Map<String, String>? headers}) {
    return Options(
      headers: {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      },
      connectTimeout: const Duration(seconds: 3),
      sendTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 6),
      responseType: ResponseType.plain,
    );
  }
}
