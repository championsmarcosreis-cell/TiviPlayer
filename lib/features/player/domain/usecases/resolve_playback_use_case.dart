import '../../../auth/domain/entities/xtream_session.dart';
import '../entities/playback_context.dart';
import '../entities/resolved_playback.dart';
import '../repositories/player_repository.dart';

class ResolvePlaybackUseCase {
  const ResolvePlaybackUseCase(this._repository);

  final PlayerRepository _repository;

  ResolvedPlayback call(XtreamSession session, PlaybackContext context) {
    return _repository.resolvePlayback(session, context);
  }
}
