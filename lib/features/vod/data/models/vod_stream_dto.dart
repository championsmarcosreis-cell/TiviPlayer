import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/xtream_parsers.dart';

part 'vod_stream_dto.freezed.dart';
part 'vod_stream_dto.g.dart';

@freezed
abstract class VodStreamDto with _$VodStreamDto {
  const factory VodStreamDto({
    required String streamId,
    required String name,
    String? categoryId,
    String? streamIcon,
    String? containerExtension,
    String? rating,
    String? genre,
    String? libraryKind,
  }) = _VodStreamDto;

  factory VodStreamDto.fromJson(Map<String, dynamic> json) =>
      _$VodStreamDtoFromJson(json);

  factory VodStreamDto.fromApi(Map<String, dynamic> json) {
    return VodStreamDto(
      streamId: XtreamParsers.asString(json['stream_id']) ?? '',
      name: XtreamParsers.asString(json['name']) ?? 'Filme sem nome',
      categoryId: XtreamParsers.asString(json['category_id']),
      streamIcon: XtreamParsers.asString(json['stream_icon']),
      containerExtension: XtreamParsers.asString(json['container_extension']),
      rating: XtreamParsers.asString(json['rating']),
      genre: XtreamParsers.asString(json['genre']),
      libraryKind:
          XtreamParsers.asString(json['library_kind']) ??
          XtreamParsers.asString(json['libraryKind']),
    );
  }
}
