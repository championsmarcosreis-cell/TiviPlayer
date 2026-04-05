// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vod_category_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VodCategoryDto _$VodCategoryDtoFromJson(Map<String, dynamic> json) =>
    _VodCategoryDto(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      parentId: json['parentId'] as String?,
      libraryKind: json['libraryKind'] as String?,
    );

Map<String, dynamic> _$VodCategoryDtoToJson(_VodCategoryDto instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'parentId': instance.parentId,
      'libraryKind': instance.libraryKind,
    };
