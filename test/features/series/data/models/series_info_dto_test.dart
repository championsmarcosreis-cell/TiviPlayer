import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/series/data/models/series_info_dto.dart';

void main() {
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
