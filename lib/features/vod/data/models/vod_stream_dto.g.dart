// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vod_stream_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VodStreamDto _$VodStreamDtoFromJson(Map<String, dynamic> json) =>
    _VodStreamDto(
      streamId: json['streamId'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String?,
      streamIcon: json['streamIcon'] as String?,
      containerExtension: json['containerExtension'] as String?,
      rating: json['rating'] as String?,
    );

Map<String, dynamic> _$VodStreamDtoToJson(_VodStreamDto instance) =>
    <String, dynamic>{
      'streamId': instance.streamId,
      'name': instance.name,
      'categoryId': instance.categoryId,
      'streamIcon': instance.streamIcon,
      'containerExtension': instance.containerExtension,
      'rating': instance.rating,
    };
