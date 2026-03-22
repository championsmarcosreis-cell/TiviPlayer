import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/playback_context.dart';
import '../../domain/entities/playback_history_entry.dart';
import '../../domain/repositories/playback_history_repository.dart';

class PlaybackHistoryRepositoryImpl implements PlaybackHistoryRepository {
  PlaybackHistoryRepositoryImpl(this._preferences);

  final SharedPreferences _preferences;

  static const _storageKey = 'player.history.entries';
  static const _maxEntries = 30;

  @override
  List<PlaybackHistoryEntry> getAll() {
    final raw = _preferences.getStringList(_storageKey) ?? const [];
    final entries = <PlaybackHistoryEntry>[];

    for (final item in raw) {
      try {
        final entry = PlaybackHistoryEntry.decode(item);
        if (entry.itemId.trim().isEmpty || entry.title.trim().isEmpty) {
          continue;
        }
        entries.add(entry);
      } catch (_) {
        // Ignora entradas legadas ou corrompidas.
      }
    }

    entries.sort((a, b) => b.updatedAtEpochMs.compareTo(a.updatedAtEpochMs));
    return entries;
  }

  @override
  Future<void> upsert(PlaybackHistoryEntry entry) async {
    final items = [...getAll()];
    items.removeWhere((saved) => saved.key == entry.key);
    items.add(entry);
    items.sort((a, b) => b.updatedAtEpochMs.compareTo(a.updatedAtEpochMs));

    await _preferences.setStringList(
      _storageKey,
      items.take(_maxEntries).map((saved) => saved.encode()).toList(),
    );
  }

  @override
  Future<void> remove(PlaybackContentType contentType, String itemId) async {
    final key = '${contentType.name}:$itemId';
    final items = [...getAll()];
    items.removeWhere((saved) => saved.key == key);

    await _preferences.setStringList(
      _storageKey,
      items.map((saved) => saved.encode()).toList(),
    );
  }
}
