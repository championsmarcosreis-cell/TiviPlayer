import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/favorite_item.dart';
import '../../domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._preferences);

  final SharedPreferences _preferences;

  static const _storageKey = 'favorites.items';

  @override
  bool contains(String contentType, String contentId) {
    return getAll().any(
      (item) => item.contentType == contentType && item.contentId == contentId,
    );
  }

  @override
  List<FavoriteItem> getAll() {
    final items = _preferences.getStringList(_storageKey) ?? const [];
    return items.map(FavoriteItem.decode).toList();
  }

  @override
  Future<void> toggle(FavoriteItem item) async {
    final items = [...getAll()];
    final index = items.indexWhere((entry) => entry.key == item.key);

    if (index >= 0) {
      items.removeAt(index);
    } else {
      items.add(item);
    }

    await _preferences.setStringList(
      _storageKey,
      items.map((entry) => entry.encode()).toList(),
    );
  }
}
