import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/player_repository_impl.dart';
import '../../domain/repositories/player_repository.dart';
import '../../domain/usecases/resolve_playback_use_case.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return const PlayerRepositoryImpl();
});

final resolvePlaybackUseCaseProvider = Provider<ResolvePlaybackUseCase>((ref) {
  return ResolvePlaybackUseCase(ref.watch(playerRepositoryProvider));
});
