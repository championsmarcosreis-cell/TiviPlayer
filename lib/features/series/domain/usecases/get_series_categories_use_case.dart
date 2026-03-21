import '../../../auth/domain/entities/xtream_session.dart';
import '../entities/series_category.dart';
import '../repositories/series_repository.dart';

class GetSeriesCategoriesUseCase {
  const GetSeriesCategoriesUseCase(this._repository);

  final SeriesRepository _repository;

  Future<List<SeriesCategory>> call(XtreamSession session) {
    return _repository.getCategories(session);
  }
}
