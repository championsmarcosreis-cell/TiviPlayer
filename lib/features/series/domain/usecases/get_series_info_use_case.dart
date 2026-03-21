import '../../../auth/domain/entities/xtream_session.dart';
import '../entities/series_info.dart';
import '../repositories/series_repository.dart';

class GetSeriesInfoUseCase {
  const GetSeriesInfoUseCase(this._repository);

  final SeriesRepository _repository;

  Future<SeriesInfo> call(XtreamSession session, String seriesId) {
    return _repository.getInfo(session, seriesId);
  }
}
