// ignore_for_file: use_null_aware_elements

import '../../../../core/network/xtream_client.dart';
import '../../../../core/network/xtream_parsers.dart';
import '../../../auth/domain/entities/xtream_session.dart';
import '../models/live_category_dto.dart';
import '../models/live_stream_dto.dart';

class LiveRemoteDataSource {
  const LiveRemoteDataSource(this._client);

  final XtreamClient _client;

  Future<List<LiveCategoryDto>> getCategories(XtreamSession session) async {
    final items = await _client.fetchList(
      baseUrl: session.credentials.normalizedBaseUrl,
      username: session.credentials.username,
      password: session.credentials.password,
      action: 'get_live_categories',
    );

    return items
        .map(XtreamParsers.asMap)
        .whereType<Map<String, dynamic>>()
        .map(LiveCategoryDto.fromApi)
        .toList();
  }

  Future<List<LiveStreamDto>> getStreams(
    XtreamSession session, {
    String? categoryId,
  }) async {
    final items = await _client.fetchList(
      baseUrl: session.credentials.normalizedBaseUrl,
      username: session.credentials.username,
      password: session.credentials.password,
      action: 'get_live_streams',
      query: {if (categoryId != null) 'category_id': categoryId},
    );

    return items
        .map(XtreamParsers.asMap)
        .whereType<Map<String, dynamic>>()
        .map(LiveStreamDto.fromApi)
        .toList();
  }
}
