import 'playback_context.dart';
import 'playback_manifest.dart';

class PlaybackRuntimeContract {
  const PlaybackRuntimeContract({
    required this.uri,
    required this.sourceType,
    this.httpHeaders = const <String, String>{},
    this.userAgent,
  });

  final Uri uri;
  final PlaybackSourceType sourceType;
  final Map<String, String> httpHeaders;
  final String? userAgent;

  bool get hasHttpHeaders => httpHeaders.isNotEmpty;
  bool get hasUserAgent => userAgent != null && userAgent!.trim().isNotEmpty;
}

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

  PlaybackRuntimeContract get runtimeContract => PlaybackRuntimeContract(
    uri: uri,
    sourceType: manifest.sourceType,
    httpHeaders: manifest.normalizedHttpHeaders,
    userAgent: manifest.userAgent,
  );
}
