// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series_category_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SeriesCategoryDto _$SeriesCategoryDtoFromJson(Map<String, dynamic> json) =>
    _SeriesCategoryDto(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      parentId: json['parentId'] as String?,
      libraryKind: json['libraryKind'] as String?,
    );

Map<String, dynamic> _$SeriesCategoryDtoToJson(_SeriesCategoryDto instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'parentId': instance.parentId,
      'libraryKind': instance.libraryKind,
    };
