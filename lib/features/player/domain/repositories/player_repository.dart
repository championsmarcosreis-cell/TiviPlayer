import '../../../auth/domain/entities/xtream_session.dart';
import '../entities/playback_context.dart';
import '../entities/resolved_playback.dart';

abstract class PlayerRepository {
  ResolvedPlayback resolvePlayback(
    XtreamSession session,
    PlaybackContext context,
  );
}
