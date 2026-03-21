import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/repositories/favorites_repository_impl.dart';
import '../../domain/entities/favorite_item.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/usecases/get_favorites_use_case.dart';
import '../../domain/usecases/toggle_favorite_use_case.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl(ref.watch(sharedPreferencesProvider));
});

final getFavoritesUseCaseProvider = Provider<GetFavoritesUseCase>((ref) {
  return GetFavoritesUseCase(ref.watch(favoritesRepositoryProvider));
});

final toggleFavoriteUseCaseProvider = Provider<ToggleFavoriteUseCase>((ref) {
  return ToggleFavoriteUseCase(ref.watch(favoritesRepositoryProvider));
});

final favoritesControllerProvider =
    NotifierProvider<FavoritesController, List<FavoriteItem>>(
      FavoritesController.new,
    );

class FavoritesController extends Notifier<List<FavoriteItem>> {
  late final GetFavoritesUseCase _getFavoritesUseCase;
  late final ToggleFavoriteUseCase _toggleFavoriteUseCase;

  @override
  List<FavoriteItem> build() {
    _getFavoritesUseCase = ref.watch(getFavoritesUseCaseProvider);
    _toggleFavoriteUseCase = ref.watch(toggleFavoriteUseCaseProvider);
    return _getFavoritesUseCase();
  }

  bool contains(String contentType, String contentId) {
    return state.any(
      (item) => item.contentType == contentType && item.contentId == contentId,
    );
  }

  Future<void> toggle(FavoriteItem item) async {
    await _toggleFavoriteUseCase(item);
    state = _getFavoritesUseCase();
  }
}
