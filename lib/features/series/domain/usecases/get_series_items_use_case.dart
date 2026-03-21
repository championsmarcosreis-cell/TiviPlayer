import '../../../auth/domain/entities/xtream_session.dart';
import '../entities/series_item.dart';
import '../repositories/series_repository.dart';

class GetSeriesItemsUseCase {
  const GetSeriesItemsUseCase(this._repository);

  final SeriesRepository _repository;

  Future<List<SeriesItem>> call(XtreamSession session, {String? categoryId}) {
    return _repository.getSeries(session, categoryId: categoryId);
  }
}
