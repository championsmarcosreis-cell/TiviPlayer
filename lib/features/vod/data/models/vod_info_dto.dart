import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/xtream_parsers.dart';

part 'vod_info_dto.freezed.dart';
part 'vod_info_dto.g.dart';

@freezed
abstract class VodInfoDto with _$VodInfoDto {
  const factory VodInfoDto({
    required String streamId,
    required String name,
    String? plot,
    String? genre,
    String? cast,
    String? director,
    String? duration,
    String? releaseDate,
    String? coverBig,
    String? backdropUrl,
    String? rating,
    String? containerExtension,
  }) = _VodInfoDto;

  factory VodInfoDto.fromJson(Map<String, dynamic> json) =>
      _$VodInfoDtoFromJson(json);

  factory VodInfoDto.fromApi(Map<String, dynamic> json) {
    final info = XtreamParsers.asMap(json['info']) ?? const {};
    final movieData = XtreamParsers.asMap(json['movie_data']) ?? const {};

    return VodInfoDto(
      streamId:
          XtreamParsers.asString(movieData['stream_id']) ??
          XtreamParsers.asString(json['vod_id']) ??
          '',
      name:
          XtreamParsers.asString(info['name']) ??
          XtreamParsers.asString(movieData['name']) ??
          'VOD sem nome',
      plot: XtreamParsers.asString(info['plot']),
      genre: XtreamParsers.asString(info['genre']),
      cast: XtreamParsers.asString(info['cast']),
      director: XtreamParsers.asString(info['director']),
      duration: XtreamParsers.asString(info['duration']),
      releaseDate:
          XtreamParsers.asString(info['releasedate']) ??
          XtreamParsers.asString(info['release_date']),
      coverBig:
          XtreamParsers.asString(info['cover_big']) ??
          XtreamParsers.asString(info['cover']),
      backdropUrl:
          XtreamParsers.asString(info['backdrop_url']) ??
          XtreamParsers.asString(info['backdrop_path']) ??
          XtreamParsers.asString(info['backdrop']),
      rating: XtreamParsers.asString(info['rating']),
      containerExtension:
          XtreamParsers.asString(movieData['container_extension']) ??
          XtreamParsers.asString(info['container_extension']),
    );
  }
}
