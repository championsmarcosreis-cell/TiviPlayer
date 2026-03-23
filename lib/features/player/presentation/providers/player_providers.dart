import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/engine/android_channel_player_engine_adapter.dart';
import '../../data/engine/video_player_engine_adapter.dart';
import '../../data/observability/debug_player_telemetry_sink.dart';
import '../../data/repositories/player_repository_impl.dart';
import '../../domain/engine/player_engine_adapter.dart';
import '../../domain/observability/player_telemetry.dart';
import '../../domain/repositories/player_repository.dart';
import '../../domain/usecases/resolve_playback_use_case.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return const PlayerRepositoryImpl();
});

final playerTelemetrySinkProvider = Provider<PlayerTelemetrySink>((ref) {
  return const DebugPlayerTelemetrySink();
});

final playerEngineAdapterProvider = Provider<PlayerEngineAdapter>((ref) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return AndroidChannelPlayerEngineAdapter(
      telemetrySink: ref.watch(playerTelemetrySinkProvider),
    );
  }

  return const VideoPlayerEngineAdapter();
});

final resolvePlaybackUseCaseProvider = Provider<ResolvePlaybackUseCase>((ref) {
  return ResolvePlaybackUseCase(ref.watch(playerRepositoryProvider));
});
