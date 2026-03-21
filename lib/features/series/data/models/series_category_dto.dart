import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/xtream_parsers.dart';

part 'series_category_dto.freezed.dart';
part 'series_category_dto.g.dart';

@freezed
abstract class SeriesCategoryDto with _$SeriesCategoryDto {
  const factory SeriesCategoryDto({
    required String categoryId,
    required String categoryName,
    String? parentId,
  }) = _SeriesCategoryDto;

  factory SeriesCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$SeriesCategoryDtoFromJson(json);

  factory SeriesCategoryDto.fromApi(Map<String, dynamic> json) {
    return SeriesCategoryDto(
      categoryId: XtreamParsers.asString(json['category_id']) ?? '',
      categoryName:
          XtreamParsers.asString(json['category_name']) ?? 'Categoria sem nome',
      parentId: XtreamParsers.asString(json['parent_id']),
    );
  }
}
