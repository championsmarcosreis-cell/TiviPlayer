import 'playback_manifest.dart';

enum PlaybackContentType { live, vod, seriesEpisode }

class PlaybackSessionCapabilities {
  const PlaybackSessionCapabilities({
    this.canSeek = false,
    this.canResume = false,
    this.hasArchive = false,
    this.hasAudioTracks = false,
    this.hasSubtitleTracks = false,
    this.hasQualityVariants = false,
  });

  const PlaybackSessionCapabilities.liveLinear({
    this.hasAudioTracks = false,
    this.hasSubtitleTracks = false,
    this.hasQualityVariants = false,
  }) : canSeek = false,
       canResume = false,
       hasArchive = false;

  const PlaybackSessionCapabilities.liveReplayAvailable({
    this.hasAudioTracks = false,
    this.hasSubtitleTracks = false,
    this.hasQualityVariants = false,
  }) : canSeek = false,
       canResume = false,
       hasArchive = true;

  const PlaybackSessionCapabilities.liveArchiveSession({
    this.hasAudioTracks = false,
    this.hasSubtitleTracks = false,
    this.hasQualityVariants = false,
  }) : canSeek = true,
       canResume = true,
       hasArchive = true;

  const PlaybackSessionCapabilities.onDemand({
    this.hasAudioTracks = false,
    this.hasSubtitleTracks = false,
    this.hasQualityVariants = false,
  }) : canSeek = true,
       canResume = true,
       hasArchive = false;

  final bool canSeek;
  final bool canResume;
  final bool hasArchive;
  final bool hasAudioTracks;
  final bool hasSubtitleTracks;
  final bool hasQualityVariants;

  bool get hasReplay => hasArchive;
  bool get isReplayAvailable => hasArchive;
  bool get isArchiveSession => hasArchive && (canSeek || canResume);

  PlaybackSessionCapabilities copyWith({
    bool? canSeek,
    bool? canResume,
    bool? hasArchive,
    bool? hasAudioTracks,
    bool? hasSubtitleTracks,
    bool? hasQualityVariants,
  }) {
    return PlaybackSessionCapabilities(
      canSeek: canSeek ?? this.canSeek,
      canResume: canResume ?? this.canResume,
      hasArchive: hasArchive ?? this.hasArchive,
      hasAudioTracks: hasAudioTracks ?? this.hasAudioTracks,
      hasSubtitleTracks: hasSubtitleTracks ?? this.hasSubtitleTracks,
      hasQualityVariants: hasQualityVariants ?? this.hasQualityVariants,
    );
  }
}

class PlaybackContext {
  const PlaybackContext({
    required this.contentType,
    required this.itemId,
    required this.title,
    this.containerExtension,
    this.artworkUrl,
    this.resumePosition,
    this.notes,
    this.manifest = const PlaybackManifest(),
    this.capabilities = const PlaybackSessionCapabilities(),
  });

  final PlaybackContentType contentType;
  final String itemId;
  final String title;
  final String? containerExtension;
  final String? artworkUrl;
  final Duration? resumePosition;
  final String? notes;
  final PlaybackManifest manifest;
  final PlaybackSessionCapabilities capabilities;

  bool get isLive => contentType == PlaybackContentType.live;
  bool get canSeek => capabilities.canSeek;
  bool get canResume => capabilities.canResume;
  bool get hasArchive => capabilities.hasArchive;
  bool get hasReplay => capabilities.hasReplay;
  bool get hasAudioTracks =>
      capabilities.hasAudioTracks || manifest.hasAudioTracks;
  bool get hasSubtitleTracks =>
      capabilities.hasSubtitleTracks || manifest.hasSubtitleTracks;
  bool get hasQualityVariants =>
      capabilities.hasQualityVariants || manifest.hasQualityVariants;
  bool get isSeekable => canSeek;

  PlaybackContext copyWith({
    PlaybackContentType? contentType,
    String? itemId,
    String? title,
    String? containerExtension,
    String? artworkUrl,
    Duration? resumePosition,
    String? notes,
    PlaybackManifest? manifest,
    PlaybackSessionCapabilities? capabilities,
  }) {
    return PlaybackContext(
      contentType: contentType ?? this.contentType,
      itemId: itemId ?? this.itemId,
      title: title ?? this.title,
      containerExtension: containerExtension ?? this.containerExtension,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      resumePosition: resumePosition ?? this.resumePosition,
      notes: notes ?? this.notes,
      manifest: manifest ?? this.manifest,
      capabilities: capabilities ?? this.capabilities,
    );
  }
}
