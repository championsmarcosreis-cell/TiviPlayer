import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/xtream_parsers.dart';

part 'vod_category_dto.freezed.dart';
part 'vod_category_dto.g.dart';

@freezed
abstract class VodCategoryDto with _$VodCategoryDto {
  const factory VodCategoryDto({
    required String categoryId,
    required String categoryName,
    String? parentId,
  }) = _VodCategoryDto;

  factory VodCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$VodCategoryDtoFromJson(json);

  factory VodCategoryDto.fromApi(Map<String, dynamic> json) {
    return VodCategoryDto(
      categoryId: XtreamParsers.asString(json['category_id']) ?? '',
      categoryName:
          XtreamParsers.asString(json['category_name']) ?? 'Categoria sem nome',
      parentId: XtreamParsers.asString(json['parent_id']),
    );
  }
}
