import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/xtream_parsers.dart';

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
    required int seasonCount,
    required int episodeCount,
  }) = _SeriesInfoDto;

  factory SeriesInfoDto.fromJson(Map<String, dynamic> json) =>
      _$SeriesInfoDtoFromJson(json);

  factory SeriesInfoDto.fromApi(Map<String, dynamic> json) {
    final info = XtreamParsers.asMap(json['info']) ?? const {};
    final seasons = XtreamParsers.asList(json['seasons']);
    final episodes = XtreamParsers.asMap(json['episodes']);

    var episodeCount = 0;
    if (episodes != null) {
      for (final entry in episodes.values) {
        episodeCount += XtreamParsers.asList(entry).length;
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
      seasonCount: seasons.length,
      episodeCount: episodeCount,
    );
  }
}
