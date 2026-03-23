import '../../../../core/errors/app_exception.dart';
import '../../../auth/domain/entities/xtream_session.dart';
import '../../domain/entities/playback_context.dart';
import '../../domain/entities/playback_manifest.dart';
import '../../domain/entities/resolved_playback.dart';
import '../../domain/repositories/player_repository.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  const PlayerRepositoryImpl();

  @override
  ResolvedPlayback resolvePlayback(
    XtreamSession session,
    PlaybackContext context,
  ) {
    final baseUri = Uri.tryParse(session.displayServer);

    if (baseUri == null || !baseUri.hasScheme || baseUri.host.isEmpty) {
      throw const AppException(
        'Endereço de acesso inválido para iniciar a reprodução.',
      );
    }

    if (context.itemId.trim().isEmpty) {
      throw const AppException('ID de stream inválido para reprodução.');
    }

    final extension = _normalizeExtension(context.containerExtension);
    if (extension == null && context.contentType != PlaybackContentType.live) {
      throw AppException(
        'Extensão de mídia indisponível para ${context.title}.',
      );
    }

    final username = session.credentials.username.trim();
    final password = session.credentials.password.trim();

    if (username.isEmpty || password.isEmpty) {
      throw const AppException('Credenciais inválidas para reprodução.');
    }

    final pathSegments = _resolvePathSegments(
      baseUri: baseUri,
      context: context,
      username: username,
      password: password,
      extension: extension,
    );

    return ResolvedPlayback(
      uri: baseUri.replace(pathSegments: pathSegments),
      context: context,
      manifest: _resolveManifest(context, extension),
    );
  }

  List<String> _resolvePathSegments({
    required Uri baseUri,
    required PlaybackContext context,
    required String username,
    required String password,
    required String? extension,
  }) {
    final basePath = baseUri.pathSegments.where(
      (segment) => segment.isNotEmpty,
    );
    final itemId = context.itemId;

    if (context.contentType == PlaybackContentType.live && extension == null) {
      // Alguns painéis Xtream devolvem live sem container_extension e expõem
      // o stream TS no formato /<usuario>/<senha>/<stream_id>.
      return [...basePath, username, password, itemId];
    }

    final pathPrefix = switch (context.contentType) {
      PlaybackContentType.live => 'live',
      PlaybackContentType.vod => 'movie',
      PlaybackContentType.seriesEpisode => 'series',
    };

    return [...basePath, pathPrefix, username, password, '$itemId.$extension'];
  }

  String? _normalizeExtension(String? value) {
    final normalized = value?.trim().replaceFirst(RegExp(r'^\.+'), '');
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  PlaybackManifest _resolveManifest(
    PlaybackContext context,
    String? extension,
  ) {
    final sourceType = _resolveSourceType(
      context.manifest.sourceType,
      extension: extension,
      isLive: context.isLive,
    );
    final fallbackFromNotes = _parseManifestFromNotes(context.notes);

    final audioTracks = context.manifest.audioTracks.isNotEmpty
        ? context.manifest.audioTracks
        : fallbackFromNotes.audioTracks;
    final subtitleTracks = context.manifest.subtitleTracks.isNotEmpty
        ? context.manifest.subtitleTracks
        : fallbackFromNotes.subtitleTracks;
    final variants = context.manifest.variants.isNotEmpty
        ? context.manifest.variants
        : fallbackFromNotes.variants;

    return PlaybackManifest(
      sourceType: sourceType,
      audioTracks: audioTracks,
      subtitleTracks: subtitleTracks,
      variants: variants,
      httpHeaders: context.manifest.httpHeaders,
    );
  }

  PlaybackSourceType _resolveSourceType(
    PlaybackSourceType provided, {
    required String? extension,
    required bool isLive,
  }) {
    if (provided != PlaybackSourceType.unknown) {
      return provided;
    }

    if (extension == null) {
      return isLive
          ? PlaybackSourceType.progressive
          : PlaybackSourceType.unknown;
    }

    return _inferSourceType(extension);
  }

  PlaybackSourceType _inferSourceType(String extension) {
    final normalized = extension.trim().toLowerCase();

    if (normalized == 'm3u8') {
      return PlaybackSourceType.hls;
    }
    if (normalized == 'mpd') {
      return PlaybackSourceType.dash;
    }

    return PlaybackSourceType.progressive;
  }

  PlaybackManifest _parseManifestFromNotes(String? notes) {
    final audioLabels = _parseValuesFromNotes(
      notes,
      keys: const ['audio', 'audios', 'audio_tracks', 'audio-track', 'lang'],
    );
    final subtitleLabels = _parseValuesFromNotes(
      notes,
      keys: const [
        'subtitle',
        'subtitles',
        'subs',
        'legenda',
        'legendas',
        'cc',
      ],
    );
    final qualityLabels = _parseValuesFromNotes(
      notes,
      keys: const ['quality', 'qualities', 'resolution', 'resolutions', 'abr'],
    );

    return PlaybackManifest(
      audioTracks: [
        for (var index = 0; index < audioLabels.length; index++)
          PlaybackTrack(
            id: 'audio-$index',
            type: PlaybackTrackType.audio,
            label: audioLabels[index],
            isDefault: index == 0,
          ),
      ],
      subtitleTracks: [
        for (var index = 0; index < subtitleLabels.length; index++)
          PlaybackTrack(
            id: 'subtitle-$index',
            type: PlaybackTrackType.subtitle,
            label: subtitleLabels[index],
            isDefault: index == 0,
          ),
      ],
      variants: [
        for (var index = 0; index < qualityLabels.length; index++)
          PlaybackVariant(
            id: 'quality-$index',
            label: qualityLabels[index],
            isDefault: index == 0,
          ),
      ],
    );
  }

  List<String> _parseValuesFromNotes(
    String? notes, {
    required List<String> keys,
  }) {
    final raw = notes?.trim();
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final loweredKeys = keys.map((value) => value.toLowerCase()).toSet();
    final segments = raw.split(RegExp(r'[\n;]'));
    final values = <String>{};

    for (final segment in segments) {
      final separatorIndex = segment.indexOf(RegExp(r'[:=]'));
      if (separatorIndex <= 0) {
        continue;
      }

      final rawKey = segment.substring(0, separatorIndex).trim().toLowerCase();
      if (!loweredKeys.contains(rawKey)) {
        continue;
      }

      final parsedValues = segment
          .substring(separatorIndex + 1)
          .split(RegExp(r'[,|/]'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty);
      values.addAll(parsedValues);
    }

    return values.toList(growable: false);
  }
}
