import 'playback_context.dart';

class ResolvedPlayback {
  const ResolvedPlayback({required this.uri, required this.context});

  final Uri uri;
  final PlaybackContext context;

  bool get isLive => context.isLive;
  bool get isSeekable => context.isSeekable;
}
