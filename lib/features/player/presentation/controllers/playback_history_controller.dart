import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/repositories/playback_history_repository_impl.dart';
import '../../domain/entities/playback_context.dart';
import '../../domain/entities/playback_history_entry.dart';
import '../../domain/repositories/playback_history_repository.dart';

final playbackHistoryRepositoryProvider = Provider<PlaybackHistoryRepository>(
  (ref) => PlaybackHistoryRepositoryImpl(ref.watch(sharedPreferencesProvider)),
);

final playbackHistoryControllerProvider =
    NotifierProvider<PlaybackHistoryController, List<PlaybackHistoryEntry>>(
      PlaybackHistoryController.new,
    );

class PlaybackHistoryController extends Notifier<List<PlaybackHistoryEntry>> {
  PlaybackHistoryRepository? _repository;

  @override
  List<PlaybackHistoryEntry> build() {
    try {
      _repository = ref.watch(playbackHistoryRepositoryProvider);
      return _repository!.getAll();
    } catch (_) {
      _repository = null;
      return const [];
    }
  }

  Future<void> upsert(PlaybackHistoryEntry entry) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    await repository.upsert(entry);
    state = repository.getAll();
  }

  Future<void> remove(PlaybackContentType contentType, String itemId) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    await repository.remove(contentType, itemId);
    state = repository.getAll();
  }
}
