enum PlaybackSourceType { unknown, progressive, hls, dash }

enum PlaybackTrackType { audio, subtitle }

class PlaybackTrack {
  const PlaybackTrack({
    required this.id,
    required this.type,
    required this.label,
    this.languageCode,
    this.codec,
    this.isDefault = false,
    this.isForced = false,
  });

  final String id;
  final PlaybackTrackType type;
  final String label;
  final String? languageCode;
  final String? codec;
  final bool isDefault;
  final bool isForced;
}

class PlaybackVariant {
  const PlaybackVariant({
    required this.id,
    required this.label,
    this.width,
    this.height,
    this.bitrateKbps,
    this.codec,
    this.isDefault = false,
    this.isAuto = false,
  });

  final String id;
  final String label;
  final int? width;
  final int? height;
  final int? bitrateKbps;
  final String? codec;
  final bool isDefault;
  final bool isAuto;
}

class PlaybackManifest {
  const PlaybackManifest({
    this.sourceType = PlaybackSourceType.unknown,
    this.audioTracks = const <PlaybackTrack>[],
    this.subtitleTracks = const <PlaybackTrack>[],
    this.variants = const <PlaybackVariant>[],
    this.httpHeaders = const <String, String>{},
  });

  final PlaybackSourceType sourceType;
  final List<PlaybackTrack> audioTracks;
  final List<PlaybackTrack> subtitleTracks;
  final List<PlaybackVariant> variants;
  final Map<String, String> httpHeaders;

  bool get hasTrackMetadata =>
      audioTracks.isNotEmpty || subtitleTracks.isNotEmpty;

  bool get hasVariants => variants.isNotEmpty;
}
