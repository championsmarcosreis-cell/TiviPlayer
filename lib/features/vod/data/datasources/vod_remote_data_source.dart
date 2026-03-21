// ignore_for_file: use_null_aware_elements

import '../../../../core/network/xtream_client.dart';
import '../../../../core/network/xtream_parsers.dart';
import '../../../auth/domain/entities/xtream_session.dart';
import '../models/vod_category_dto.dart';
import '../models/vod_info_dto.dart';
import '../models/vod_stream_dto.dart';

class VodRemoteDataSource {
  const VodRemoteDataSource(this._client);

  final XtreamClient _client;

  Future<List<VodCategoryDto>> getCategories(XtreamSession session) async {
    final items = await _client.fetchList(
      baseUrl: session.credentials.normalizedBaseUrl,
      username: session.credentials.username,
      password: session.credentials.password,
      action: 'get_vod_categories',
    );

    return items
        .map(XtreamParsers.asMap)
        .whereType<Map<String, dynamic>>()
        .map(VodCategoryDto.fromApi)
        .toList();
  }

  Future<List<VodStreamDto>> getStreams(
    XtreamSession session, {
    String? categoryId,
  }) async {
    final items = await _client.fetchList(
      baseUrl: session.credentials.normalizedBaseUrl,
      username: session.credentials.username,
      password: session.credentials.password,
      action: 'get_vod_streams',
      query: {if (categoryId != null) 'category_id': categoryId},
    );

    return items
        .map(XtreamParsers.asMap)
        .whereType<Map<String, dynamic>>()
        .map(VodStreamDto.fromApi)
        .toList();
  }

  Future<VodInfoDto> getInfo(XtreamSession session, String vodId) async {
    final response = await _client.fetchObject(
      baseUrl: session.credentials.normalizedBaseUrl,
      username: session.credentials.username,
      password: session.credentials.password,
      action: 'get_vod_info',
      query: {'vod_id': vodId},
    );

    return VodInfoDto.fromApi(response);
  }
}
