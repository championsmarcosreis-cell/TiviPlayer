import '../../../auth/domain/entities/xtream_session.dart';
import '../entities/vod_category.dart';
import '../repositories/vod_repository.dart';

class GetVodCategoriesUseCase {
  const GetVodCategoriesUseCase(this._repository);

  final VodRepository _repository;

  Future<List<VodCategory>> call(XtreamSession session) {
    return _repository.getCategories(session);
  }
}
