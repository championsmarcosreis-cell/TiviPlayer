import '../../../../core/errors/app_exception.dart';
import '../../../auth/domain/entities/xtream_session.dart';
import '../../domain/entities/playback_context.dart';
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
      throw const AppException('Base URL inválida para resolver playback.');
    }

    if (context.itemId.trim().isEmpty) {
      throw const AppException('ID de stream inválido para reprodução.');
    }

    final extension = _normalizeExtension(context.containerExtension);
    if (extension == null) {
      throw AppException(
        'Extensão de mídia indisponível para ${context.title}.',
      );
    }

    final username = session.credentials.username.trim();
    final password = session.credentials.password.trim();

    if (username.isEmpty || password.isEmpty) {
      throw const AppException('Credenciais Xtream inválidas para reprodução.');
    }

    final pathPrefix = switch (context.contentType) {
      PlaybackContentType.live => 'live',
      PlaybackContentType.vod => 'movie',
      PlaybackContentType.seriesEpisode => 'series',
    };

    final pathSegments = [
      ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
      pathPrefix,
      username,
      password,
      '${context.itemId}.$extension',
    ];

    return ResolvedPlayback(
      uri: baseUri.replace(pathSegments: pathSegments),
      context: context,
    );
  }

  String? _normalizeExtension(String? value) {
    final normalized = value?.trim().replaceFirst(RegExp(r'^\.+'), '');
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
