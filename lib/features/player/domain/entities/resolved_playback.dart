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
  PlaybackSessionCapabilities get capabilities => context.capabilities.copyWith(
    hasAudioTracks: context.hasAudioTracks || manifest.hasAudioTracks,
    hasSubtitleTracks: context.hasSubtitleTracks || manifest.hasSubtitleTracks,
    hasQualityVariants:
        context.hasQualityVariants || manifest.hasQualityVariants,
  );
  bool get canSeek => capabilities.canSeek;
  bool get canResume => capabilities.canResume;
  bool get hasArchive => capabilities.hasArchive;
  bool get hasReplay => capabilities.hasReplay;
  bool get hasAudioTracks => capabilities.hasAudioTracks;
  bool get hasSubtitleTracks => capabilities.hasSubtitleTracks;
  bool get hasQualityVariants => capabilities.hasQualityVariants;
  bool get isSeekable => canSeek;

  PlaybackRuntimeContract get runtimeContract => PlaybackRuntimeContract(
    uri: uri,
    sourceType: manifest.sourceType,
    httpHeaders: manifest.normalizedHttpHeaders,
    userAgent: manifest.userAgent,
  );

  ResolvedPlayback copyWith({
    Uri? uri,
    PlaybackContext? context,
    PlaybackManifest? manifest,
  }) {
    final nextManifest = manifest ?? this.manifest;
    final nextContext = (context ?? this.context).copyWith(
      manifest: nextManifest,
    );

    return ResolvedPlayback(
      uri: uri ?? this.uri,
      context: nextContext,
      manifest: nextManifest,
    );
  }
}
