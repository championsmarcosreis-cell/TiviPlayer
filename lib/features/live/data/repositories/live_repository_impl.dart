import '../../../auth/domain/entities/xtream_session.dart';
import '../../domain/entities/live_category.dart';
import '../../domain/entities/live_stream.dart';
import '../../domain/repositories/live_repository.dart';
import '../datasources/live_remote_data_source.dart';

class LiveRepositoryImpl implements LiveRepository {
  const LiveRepositoryImpl(this._remoteDataSource);

  final LiveRemoteDataSource _remoteDataSource;

  @override
  Future<List<LiveCategory>> getCategories(XtreamSession session) async {
    final items = await _remoteDataSource.getCategories(session);

    return items
        .where((item) => item.categoryId.isNotEmpty)
        .map(
          (item) => LiveCategory(
            id: item.categoryId,
            name: item.categoryName,
            parentId: item.parentId,
          ),
        )
        .toList();
  }

  @override
  Future<List<LiveStream>> getStreams(
    XtreamSession session, {
    String? categoryId,
  }) async {
    final items = await _remoteDataSource.getStreams(
      session,
      categoryId: categoryId,
    );

    return items
        .where((item) => item.streamId.isNotEmpty)
        .map(
          (item) => LiveStream(
            id: item.streamId,
            name: item.name,
            categoryId: item.categoryId,
            iconUrl: item.streamIcon,
            epgChannelId: item.epgChannelId,
            hasArchive: item.tvArchive,
            isAdult: item.isAdult,
          ),
        )
        .toList();
  }
}
