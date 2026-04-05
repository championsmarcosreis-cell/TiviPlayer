import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/xtream_parsers.dart';
import 'series_episode_dto.dart';

part 'series_info_dto.freezed.dart';
part 'series_info_dto.g.dart';

@freezed
abstract class SeriesInfoDto with _$SeriesInfoDto {
  const factory SeriesInfoDto({
    required String seriesId,
    required String name,
    String? plot,
    String? genre,
    String? cast,
    String? cover,
    String? backdropUrl,
    required int seasonCount,
    required int episodeCount,
    @Default(<SeriesEpisodeDto>[]) List<SeriesEpisodeDto> episodes,
  }) = _SeriesInfoDto;

  factory SeriesInfoDto.fromJson(Map<String, dynamic> json) =>
      _$SeriesInfoDtoFromJson(json);

  factory SeriesInfoDto.fromApi(Map<String, dynamic> json) {
    final info = XtreamParsers.asMap(json['info']) ?? const {};
    final seasons = XtreamParsers.asList(json['seasons']);
    final episodes = XtreamParsers.asMap(json['episodes']);
    final episodeItems = <SeriesEpisodeDto>[];

    var episodeCount = 0;
    if (episodes != null) {
      for (final mapEntry in episodes.entries) {
        final seasonNumber = XtreamParsers.asInt(mapEntry.key) ?? 0;
        final seasonItems = XtreamParsers.asList(mapEntry.value);
        episodeCount += seasonItems.length;
        for (final rawItem in seasonItems) {
          final episode = XtreamParsers.asMap(rawItem);
          if (episode == null) {
            continue;
          }
          episodeItems.add(SeriesEpisodeDto.fromApi(episode, seasonNumber));
        }
      }
    }

    return SeriesInfoDto(
      seriesId:
          XtreamParsers.asString(info['series_id']) ??
          XtreamParsers.asString(json['series_id']) ??
          '',
      name: XtreamParsers.asString(info['name']) ?? 'Série sem nome',
      plot: XtreamParsers.asString(info['plot']),
      genre: XtreamParsers.asString(info['genre']),
      cast: XtreamParsers.asString(info['cast']),
      cover: XtreamParsers.asString(info['cover']),
      backdropUrl:
          XtreamParsers.asString(info['backdrop_url']) ??
          XtreamParsers.asString(info['backdrop_path']) ??
          XtreamParsers.asString(info['backdrop']),
      seasonCount: seasons.length,
      episodeCount: episodeCount,
      episodes: episodeItems,
    );
  }
}
