import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/xtream_parsers.dart';

part 'live_category_dto.freezed.dart';
part 'live_category_dto.g.dart';

@freezed
abstract class LiveCategoryDto with _$LiveCategoryDto {
  const factory LiveCategoryDto({
    required String categoryId,
    required String categoryName,
    String? parentId,
  }) = _LiveCategoryDto;

  factory LiveCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$LiveCategoryDtoFromJson(json);

  factory LiveCategoryDto.fromApi(Map<String, dynamic> json) {
    return LiveCategoryDto(
      categoryId: XtreamParsers.asString(json['category_id']) ?? '',
      categoryName:
          XtreamParsers.asString(json['category_name']) ?? 'Categoria sem nome',
      parentId: XtreamParsers.asString(json['parent_id']),
    );
  }
}
