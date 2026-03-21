// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series_info_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SeriesInfoDto _$SeriesInfoDtoFromJson(Map<String, dynamic> json) =>
    _SeriesInfoDto(
      seriesId: json['seriesId'] as String,
      name: json['name'] as String,
      plot: json['plot'] as String?,
      genre: json['genre'] as String?,
      cast: json['cast'] as String?,
      cover: json['cover'] as String?,
      seasonCount: (json['seasonCount'] as num).toInt(),
      episodeCount: (json['episodeCount'] as num).toInt(),
      episodes:
          (json['episodes'] as List<dynamic>?)
              ?.map((e) => SeriesEpisodeDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SeriesEpisodeDto>[],
    );

Map<String, dynamic> _$SeriesInfoDtoToJson(_SeriesInfoDto instance) =>
    <String, dynamic>{
      'seriesId': instance.seriesId,
      'name': instance.name,
      'plot': instance.plot,
      'genre': instance.genre,
      'cast': instance.cast,
      'cover': instance.cover,
      'seasonCount': instance.seasonCount,
      'episodeCount': instance.episodeCount,
      'episodes': instance.episodes,
    };
