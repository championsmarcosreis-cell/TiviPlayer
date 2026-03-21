// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_category_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveCategoryDto _$LiveCategoryDtoFromJson(Map<String, dynamic> json) =>
    _LiveCategoryDto(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      parentId: json['parentId'] as String?,
    );

Map<String, dynamic> _$LiveCategoryDtoToJson(_LiveCategoryDto instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'parentId': instance.parentId,
    };
