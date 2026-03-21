// ignore_for_file: use_null_aware_elements

import 'dart:convert';

import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import 'xtream_parsers.dart';

class XtreamClient {
  XtreamClient(this._dio, {int maxRetries = 1}) : _maxRetries = maxRetries;

  final Dio _dio;
  final int _maxRetries;

  Future<Map<String, dynamic>> fetchObject({
    required String baseUrl,
    required String username,
    required String password,
    String? action,
    Map<String, dynamic> query = const {},
  }) async {
    final data = await _request(
      baseUrl: baseUrl,
      username: username,
      password: password,
      action: action,
      query: query,
    );

    return XtreamParsers.asMap(data) ?? <String, dynamic>{};
  }

  Future<List<dynamic>> fetchList({
    required String baseUrl,
    required String username,
    required String password,
    String? action,
    Map<String, dynamic> query = const {},
  }) async {
    final data = await _request(
      baseUrl: baseUrl,
      username: username,
      password: password,
      action: action,
      query: query,
    );

    return XtreamParsers.asList(data);
  }

  Future<dynamic> _request({
    required String baseUrl,
    required String username,
    required String password,
    String? action,
    Map<String, dynamic> query = const {},
  }) async {
    final endpoint = Uri.parse('${normalizeBaseUrl(baseUrl)}/player_api.php')
        .replace(
          queryParameters: {
            'username': username,
            'password': password,
            if (action != null) 'action': action,
            ...query.map((key, value) => MapEntry(key, value.toString())),
          },
        );

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _dio.getUri<dynamic>(endpoint);

        if (response.statusCode == null ||
            response.statusCode! < 200 ||
            response.statusCode! >= 300) {
          throw XtreamRequestException(
            'Falha HTTP ${response.statusCode ?? 'desconhecida'}.',
          );
        }

        return _decodePayload(response.data);
      } on DioException catch (error) {
        if (!_shouldRetry(error) || attempt >= _maxRetries) {
          throw XtreamRequestException(_messageFromDio(error));
        }

        await Future<void>.delayed(Duration(milliseconds: 350 * (attempt + 1)));
      } on FormatException {
        throw const XtreamRequestException('Resposta inválida do serviço.');
      }
    }

    throw const XtreamRequestException('Falha ao consultar o serviço.');
  }

  dynamic _decodePayload(dynamic data) {
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) {
        return <String, dynamic>{};
      }

      return jsonDecode(trimmed);
    }

    return data;
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;
  }

  String _messageFromDio(DioException error) {
    final statusCode = error.response?.statusCode;

    if (statusCode == 401 || statusCode == 403) {
      return 'Acesso negado para este acesso.';
    }

    if (statusCode != null) {
      return 'Falha HTTP $statusCode ao consultar o serviço.';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tempo limite excedido ao conectar no serviço.';
      case DioExceptionType.connectionError:
        return 'Não foi possível alcançar o serviço.';
      default:
        return 'Erro de comunicação com o serviço.';
    }
  }

  static String normalizeBaseUrl(String baseUrl) {
    return baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
