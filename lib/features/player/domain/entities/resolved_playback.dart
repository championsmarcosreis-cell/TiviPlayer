import 'playback_context.dart';
import 'playback_manifest.dart';

class ResolvedPlayback {
  const ResolvedPlayback({
    required this.uri,
    required this.context,
    this.manifest = const PlaybackManifest(),
  });

  final Uri uri;
  final PlaybackContext context;
  final PlaybackManifest manifest;

  bool get isLive => context.isLive;
  bool get isSeekable => context.isSeekable;
}
