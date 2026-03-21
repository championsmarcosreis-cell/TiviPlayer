import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/xtream_parsers.dart';

part 'live_stream_dto.freezed.dart';
part 'live_stream_dto.g.dart';

@freezed
abstract class LiveStreamDto with _$LiveStreamDto {
  const factory LiveStreamDto({
    required String streamId,
    required String name,
    String? categoryId,
    String? streamIcon,
    String? containerExtension,
    String? epgChannelId,
    required bool tvArchive,
    required bool isAdult,
  }) = _LiveStreamDto;

  factory LiveStreamDto.fromJson(Map<String, dynamic> json) =>
      _$LiveStreamDtoFromJson(json);

  factory LiveStreamDto.fromApi(Map<String, dynamic> json) {
    return LiveStreamDto(
      streamId: XtreamParsers.asString(json['stream_id']) ?? '',
      name: XtreamParsers.asString(json['name']) ?? 'Canal sem nome',
      categoryId: XtreamParsers.asString(json['category_id']),
      streamIcon: XtreamParsers.asString(json['stream_icon']),
      containerExtension: XtreamParsers.asString(json['container_extension']),
      epgChannelId: XtreamParsers.asString(json['epg_channel_id']),
      tvArchive: XtreamParsers.asBool(json['tv_archive']),
      isAdult: XtreamParsers.asBool(json['is_adult']),
    );
  }
}
