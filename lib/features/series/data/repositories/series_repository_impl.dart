import '../../domain/entities/series_episode.dart';
import '../../../auth/domain/entities/xtream_session.dart';
import '../../domain/entities/series_category.dart';
import '../../domain/entities/series_info.dart';
import '../../domain/entities/series_item.dart';
import '../../domain/repositories/series_repository.dart';
import '../datasources/series_remote_data_source.dart';

class SeriesRepositoryImpl implements SeriesRepository {
  const SeriesRepositoryImpl(this._remoteDataSource);

  final SeriesRemoteDataSource _remoteDataSource;

  @override
  Future<List<SeriesCategory>> getCategories(XtreamSession session) async {
    final items = await _remoteDataSource.getCategories(session);

    return items
        .where((item) => item.categoryId.isNotEmpty)
        .map(
          (item) => SeriesCategory(
            id: item.categoryId,
            name: item.categoryName,
            parentId: item.parentId,
            libraryKind: item.libraryKind,
          ),
        )
        .toList();
  }

  @override
  Future<SeriesInfo> getInfo(XtreamSession session, String seriesId) async {
    final item = await _remoteDataSource.getInfo(session, seriesId);

    return SeriesInfo(
      id: item.seriesId,
      name: item.name,
      plot: item.plot,
      genre: item.genre,
      cast: item.cast,
      coverUrl: item.cover,
      seasonCount: item.seasonCount,
      episodeCount: item.episodeCount,
      episodes: item.episodes
          .where((episode) => episode.id.isNotEmpty)
          .map(
            (episode) => SeriesEpisode(
              id: episode.id,
              title: episode.title,
              seasonNumber: episode.seasonNumber,
              episodeNumber: episode.episodeNumber,
              plot: episode.plot,
              duration: episode.duration,
              containerExtension: episode.containerExtension,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<List<SeriesItem>> getSeries(
    XtreamSession session, {
    String? categoryId,
  }) async {
    final items = await _remoteDataSource.getSeries(
      session,
      categoryId: categoryId,
    );

    return items
        .where((item) => item.seriesId.isNotEmpty)
        .map(
          (item) => SeriesItem(
            id: item.seriesId,
            name: item.name,
            categoryId: item.categoryId,
            coverUrl: item.cover,
            plot: item.plot,
            genre: item.genre,
            libraryKind: item.libraryKind,
          ),
        )
        .toList();
  }
}
