// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_stream_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveStreamDto _$LiveStreamDtoFromJson(Map<String, dynamic> json) =>
    _LiveStreamDto(
      streamId: json['streamId'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String?,
      streamIcon: json['streamIcon'] as String?,
      containerExtension: json['containerExtension'] as String?,
      epgChannelId: json['epgChannelId'] as String?,
      tvArchive: json['tvArchive'] as bool,
      isAdult: json['isAdult'] as bool,
    );

Map<String, dynamic> _$LiveStreamDtoToJson(_LiveStreamDto instance) =>
    <String, dynamic>{
      'streamId': instance.streamId,
      'name': instance.name,
      'categoryId': instance.categoryId,
      'streamIcon': instance.streamIcon,
      'containerExtension': instance.containerExtension,
      'epgChannelId': instance.epgChannelId,
      'tvArchive': instance.tvArchive,
      'isAdult': instance.isAdult,
    };
