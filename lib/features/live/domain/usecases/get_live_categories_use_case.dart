import '../../../auth/domain/entities/xtream_session.dart';
import '../entities/live_category.dart';
import '../repositories/live_repository.dart';

class GetLiveCategoriesUseCase {
  const GetLiveCategoriesUseCase(this._repository);

  final LiveRepository _repository;

  Future<List<LiveCategory>> call(XtreamSession session) {
    return _repository.getCategories(session);
  }
}
