// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vod_info_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VodInfoDto _$VodInfoDtoFromJson(Map<String, dynamic> json) => _VodInfoDto(
  streamId: json['streamId'] as String,
  name: json['name'] as String,
  plot: json['plot'] as String?,
  genre: json['genre'] as String?,
  cast: json['cast'] as String?,
  director: json['director'] as String?,
  duration: json['duration'] as String?,
  releaseDate: json['releaseDate'] as String?,
  coverBig: json['coverBig'] as String?,
  rating: json['rating'] as String?,
);

Map<String, dynamic> _$VodInfoDtoToJson(_VodInfoDto instance) =>
    <String, dynamic>{
      'streamId': instance.streamId,
      'name': instance.name,
      'plot': instance.plot,
      'genre': instance.genre,
      'cast': instance.cast,
      'director': instance.director,
      'duration': instance.duration,
      'releaseDate': instance.releaseDate,
      'coverBig': instance.coverBig,
      'rating': instance.rating,
    };
