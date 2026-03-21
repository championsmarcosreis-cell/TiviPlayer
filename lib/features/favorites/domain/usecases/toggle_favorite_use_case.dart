import '../entities/favorite_item.dart';
import '../repositories/favorites_repository.dart';

class ToggleFavoriteUseCase {
  const ToggleFavoriteUseCase(this._repository);

  final FavoritesRepository _repository;

  Future<void> call(FavoriteItem item) => _repository.toggle(item);
}
