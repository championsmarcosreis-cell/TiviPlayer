import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/home/data/models/home_discovery_dto.dart';
import 'package:tiviplayer/features/series/data/models/series_info_dto.dart';

void main() {
  test('parse series_id from discovery payload when available', () {
    final dto = HomeDiscoveryItemDto.fromApi({
      'id': 'content-46',
      'title': 'A Knight of the Seven Kingdoms',
      'media_type': 'Series',
      'content_id': 46,
      'series_id': 2,
    });

    expect(dto, isNotNull);
    expect(dto!.contentId, '46');
    expect(dto.seriesId, '2');
  });

  test('parse library_kind from discovery payload when available', () {
    final item = HomeDiscoveryItemDto.fromApi({
      'id': 'anime-202',
      'title': 'Solo Leveling',
      'media_type': 'Anime',
      'library_kind': 'anime',
      'content_id': 202,
    });
    final rail = HomeDiscoveryRailDto.fromApi({
      'slug': 'kids',
      'title': 'Kids',
      'library_kind': 'kids',
      'items': const [],
    });

    expect(item, isNotNull);
    expect(item!.libraryKind, 'anime');
    expect(rail, isNotNull);
    expect(rail!.libraryKind, 'kids');
  });

  test('parse seasons and playable episodes from Xtream payload', () {
    final dto = SeriesInfoDto.fromApi({
      'info': {'series_id': '77', 'name': 'Demo Series', 'plot': 'Plot'},
      'seasons': [
        {'season_number': 1},
        {'season_number': 2},
      ],
      'episodes': {
        '1': [
          {
            'id': '1001',
            'info': {
              'title': 'Episode 1',
              'episode_num': 1,
              'container_extension': 'mp4',
              'duration': '00:42:00',
            },
          },
        ],
        '2': [
          {
            'id': '2001',
            'info': {
              'title': 'Episode 2',
              'episode_num': 1,
              'container_extension': 'mkv',
            },
          },
        ],
      },
    });

    expect(dto.seriesId, '77');
    expect(dto.name, 'Demo Series');
    expect(dto.seasonCount, 2);
    expect(dto.episodeCount, 2);
    expect(dto.episodes, hasLength(2));
    expect(dto.episodes.first.id, '1001');
    expect(dto.episodes.first.seasonNumber, 1);
    expect(dto.episodes.first.episodeNumber, 1);
    expect(dto.episodes.first.containerExtension, 'mp4');
    expect(dto.episodes.last.seasonNumber, 2);
  });
}
