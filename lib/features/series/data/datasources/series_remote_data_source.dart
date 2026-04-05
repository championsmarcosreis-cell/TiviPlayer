// ignore_for_file: use_null_aware_elements

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/xtream_client.dart';
import '../../../../core/network/xtream_parsers.dart';
import '../../../auth/domain/entities/xtream_session.dart';
import '../models/series_category_dto.dart';
import '../models/series_info_dto.dart';
import '../models/series_item_dto.dart';

class SeriesRemoteDataSource {
  const SeriesRemoteDataSource(this._client);

  final XtreamClient _client;

  Future<List<SeriesCategoryDto>> getCategories(XtreamSession session) async {
    final items = await _client.fetchList(
      baseUrl: session.credentials.normalizedBaseUrl,
      username: session.credentials.username,
      password: session.credentials.password,
      action: 'get_series_categories',
    );

    return items
        .map(XtreamParsers.asMap)
        .whereType<Map<String, dynamic>>()
        .map(SeriesCategoryDto.fromApi)
        .toList();
  }

  Future<List<SeriesItemDto>> getSeries(
    XtreamSession session, {
    String? categoryId,
  }) async {
    final items = await _client.fetchList(
      baseUrl: session.credentials.normalizedBaseUrl,
      username: session.credentials.username,
      password: session.credentials.password,
      action: 'get_series',
      query: {if (categoryId != null) 'category_id': categoryId},
    );

    return items
        .map(XtreamParsers.asMap)
        .whereType<Map<String, dynamic>>()
        .map(SeriesItemDto.fromApi)
        .toList();
  }

  Future<SeriesInfoDto> getInfo(XtreamSession session, String seriesId) async {
    final primaryResponse = await _client.fetchObject(
      baseUrl: session.credentials.normalizedBaseUrl,
      username: session.credentials.username,
      password: session.credentials.password,
      action: 'get_series_info',
      query: {'series': seriesId},
    );

    if (_isValidSeriesInfoResponse(primaryResponse)) {
      return SeriesInfoDto.fromApi(primaryResponse);
    }

    final fallbackResponse = await _client.fetchObject(
      baseUrl: session.credentials.normalizedBaseUrl,
      username: session.credentials.username,
      password: session.credentials.password,
      action: 'get_series_info',
      query: {'series_id': seriesId},
    );

    if (!_isValidSeriesInfoResponse(fallbackResponse)) {
      throw const XtreamRequestException(
        'Detalhes da série indisponíveis para este título.',
      );
    }

    return SeriesInfoDto.fromApi(fallbackResponse);
  }

  bool _isValidSeriesInfoResponse(Map<String, dynamic> response) {
    final info = XtreamParsers.asMap(response['info']);
    final seasons = XtreamParsers.asList(response['seasons']);
    final episodes = XtreamParsers.asMap(response['episodes']);
    final rootSeriesId = XtreamParsers.asString(response['series_id']);

    return (info != null && info.isNotEmpty) ||
        seasons.isNotEmpty ||
        (episodes != null && episodes.isNotEmpty) ||
        (rootSeriesId != null && rootSeriesId.isNotEmpty);
  }
}
