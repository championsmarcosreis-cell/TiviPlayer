import '../entities/playback_context.dart';
import '../entities/playback_history_entry.dart';

abstract class PlaybackHistoryRepository {
  List<PlaybackHistoryEntry> getAll();
  Future<void> upsert(PlaybackHistoryEntry entry);
  Future<void> remove(PlaybackContentType contentType, String itemId);
}
