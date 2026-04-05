// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SeriesItemDto _$SeriesItemDtoFromJson(Map<String, dynamic> json) =>
    _SeriesItemDto(
      seriesId: json['seriesId'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String?,
      cover: json['cover'] as String?,
      plot: json['plot'] as String?,
      genre: json['genre'] as String?,
      libraryKind: json['libraryKind'] as String?,
    );

Map<String, dynamic> _$SeriesItemDtoToJson(_SeriesItemDto instance) =>
    <String, dynamic>{
      'seriesId': instance.seriesId,
      'name': instance.name,
      'categoryId': instance.categoryId,
      'cover': instance.cover,
      'plot': instance.plot,
      'genre': instance.genre,
      'libraryKind': instance.libraryKind,
    };
