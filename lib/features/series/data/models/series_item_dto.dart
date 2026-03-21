import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/xtream_parsers.dart';

part 'series_item_dto.freezed.dart';
part 'series_item_dto.g.dart';

@freezed
abstract class SeriesItemDto with _$SeriesItemDto {
  const factory SeriesItemDto({
    required String seriesId,
    required String name,
    String? categoryId,
    String? cover,
    String? plot,
  }) = _SeriesItemDto;

  factory SeriesItemDto.fromJson(Map<String, dynamic> json) =>
      _$SeriesItemDtoFromJson(json);

  factory SeriesItemDto.fromApi(Map<String, dynamic> json) {
    return SeriesItemDto(
      seriesId: XtreamParsers.asString(json['series_id']) ?? '',
      name: XtreamParsers.asString(json['name']) ?? 'Série sem nome',
      categoryId: XtreamParsers.asString(json['category_id']),
      cover: XtreamParsers.asString(json['cover']),
      plot: XtreamParsers.asString(json['plot']),
    );
  }
}
