import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/core/errors/app_exception.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_credentials.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_session.dart';
import 'package:tiviplayer/features/player/data/repositories/player_repository_impl.dart';
import 'package:tiviplayer/features/player/domain/entities/playback_context.dart';
import 'package:tiviplayer/features/player/domain/entities/playback_manifest.dart';

void main() {
  const repository = PlayerRepositoryImpl();
  const credentials = XtreamCredentials(
    baseUrl: 'http://provider.example:8080',
    username: 'user',
    password: 'pass',
  );
  const session = XtreamSession(
    credentials: credentials,
    accountStatus: 'Active',
    serverUrl: 'http://provider.example:8080',
  );

  test('resolve URL for live playback', () {
    const context = PlaybackContext(
      contentType: PlaybackContentType.live,
      itemId: '1001',
      title: 'News',
      containerExtension: 'ts',
    );

    final resolved = repository.resolvePlayback(session, context);

    expect(
      resolved.uri.toString(),
      'http://provider.example:8080/live/user/pass/1001.ts',
    );
    expect(resolved.isLive, isTrue);
    expect(resolved.manifest.sourceType, PlaybackSourceType.progressive);
  });

  test(
    'resolve URL for live playback without extension using Xtream fallback',
    () {
      const context = PlaybackContext(
        contentType: PlaybackContentType.live,
        itemId: '1001',
        title: 'News',
      );

      final resolved = repository.resolvePlayback(session, context);

      expect(
        resolved.uri.toString(),
        'http://provider.example:8080/user/pass/1001',
      );
      expect(resolved.isLive, isTrue);
      expect(resolved.manifest.sourceType, PlaybackSourceType.progressive);
    },
  );

  test('resolve URL for VOD playback', () {
    const context = PlaybackContext(
      contentType: PlaybackContentType.vod,
      itemId: '2002',
      title: 'Movie',
      containerExtension: '.mp4',
    );

    final resolved = repository.resolvePlayback(session, context);

    expect(
      resolved.uri.toString(),
      'http://provider.example:8080/movie/user/pass/2002.mp4',
    );
    expect(resolved.isSeekable, isTrue);
    expect(resolved.manifest.sourceType, PlaybackSourceType.progressive);
  });

  test('resolve URL for series episode playback', () {
    const context = PlaybackContext(
      contentType: PlaybackContentType.seriesEpisode,
      itemId: '3003',
      title: 'Episode',
      containerExtension: 'mkv',
    );

    final resolved = repository.resolvePlayback(session, context);

    expect(
      resolved.uri.toString(),
      'http://provider.example:8080/series/user/pass/3003.mkv',
    );
  });

  test('infer HLS and parse structured fallback from notes', () {
    const context = PlaybackContext(
      contentType: PlaybackContentType.live,
      itemId: '1002',
      title: 'Sports',
      containerExtension: 'm3u8',
      notes: 'audio: PT-BR, EN; subtitles: PT-BR, EN; quality: 1080p, 720p',
    );

    final resolved = repository.resolvePlayback(session, context);

    expect(resolved.manifest.sourceType, PlaybackSourceType.hls);
    expect(resolved.manifest.audioTracks.map((track) => track.label).toList(), [
      'PT-BR',
      'EN',
    ]);
    expect(
      resolved.manifest.subtitleTracks.map((track) => track.label).toList(),
      ['PT-BR', 'EN'],
    );
    expect(
      resolved.manifest.variants.map((variant) => variant.label).toList(),
      ['1080p', '720p'],
    );
  });

  test('throw explicit error when VOD extension is unavailable', () {
    const context = PlaybackContext(
      contentType: PlaybackContentType.vod,
      itemId: '2002',
      title: 'Movie',
    );

    expect(
      () => repository.resolvePlayback(session, context),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          contains('Extensão de mídia indisponível'),
        ),
      ),
    );
  });
}
