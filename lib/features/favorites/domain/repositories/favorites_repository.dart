import '../entities/favorite_item.dart';

abstract class FavoritesRepository {
  List<FavoriteItem> getAll();
  Future<void> toggle(FavoriteItem item);
  bool contains(String contentType, String contentId);
}
