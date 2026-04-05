import '../../../auth/domain/entities/xtream_session.dart';
import '../../domain/entities/vod_category.dart';
import '../../domain/entities/vod_info.dart';
import '../../domain/entities/vod_stream.dart';
import '../../domain/repositories/vod_repository.dart';
import '../datasources/vod_remote_data_source.dart';

class VodRepositoryImpl implements VodRepository {
  const VodRepositoryImpl(this._remoteDataSource);

  final VodRemoteDataSource _remoteDataSource;

  @override
  Future<List<VodCategory>> getCategories(XtreamSession session) async {
    final items = await _remoteDataSource.getCategories(session);

    return items
        .where((item) => item.categoryId.isNotEmpty)
        .map(
          (item) => VodCategory(
            id: item.categoryId,
            name: item.categoryName,
            parentId: item.parentId,
            libraryKind: item.libraryKind,
          ),
        )
        .toList();
  }

  @override
  Future<VodInfo> getInfo(XtreamSession session, String vodId) async {
    final item = await _remoteDataSource.getInfo(session, vodId);

    return VodInfo(
      id: item.streamId,
      name: item.name,
      plot: item.plot,
      genre: item.genre,
      cast: item.cast,
      director: item.director,
      duration: item.duration,
      releaseDate: item.releaseDate,
      coverUrl: item.coverBig,
      rating: item.rating,
      containerExtension: item.containerExtension,
    );
  }

  @override
  Future<List<VodStream>> getStreams(
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
          (item) => VodStream(
            id: item.streamId,
            name: item.name,
            categoryId: item.categoryId,
            coverUrl: item.streamIcon,
            containerExtension: item.containerExtension,
            rating: item.rating,
            genre: item.genre,
            libraryKind: item.libraryKind,
          ),
        )
        .toList();
  }
}
