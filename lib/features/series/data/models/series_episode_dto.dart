import '../../../../core/network/xtream_parsers.dart';

class SeriesEpisodeDto {
  const SeriesEpisodeDto({
    required this.id,
    required this.title,
    required this.seasonNumber,
    this.episodeNumber,
    this.plot,
    this.duration,
    this.containerExtension,
  });

  final String id;
  final String title;
  final int seasonNumber;
  final int? episodeNumber;
  final String? plot;
  final String? duration;
  final String? containerExtension;

  factory SeriesEpisodeDto.fromApi(
    Map<String, dynamic> json,
    int seasonNumber,
  ) {
    final info = XtreamParsers.asMap(json['info']) ?? const {};

    return SeriesEpisodeDto(
      id:
          XtreamParsers.asString(json['id']) ??
          XtreamParsers.asString(json['stream_id']) ??
          '',
      title:
          XtreamParsers.asString(info['title']) ??
          XtreamParsers.asString(json['title']) ??
          'Episódio sem título',
      seasonNumber: XtreamParsers.asInt(info['season']) ?? seasonNumber,
      episodeNumber:
          XtreamParsers.asInt(info['episode_num']) ??
          XtreamParsers.asInt(json['episode_num']),
      plot:
          XtreamParsers.asString(info['plot']) ??
          XtreamParsers.asString(json['plot']),
      duration:
          XtreamParsers.asString(info['duration']) ??
          XtreamParsers.asString(json['duration']),
      containerExtension:
          XtreamParsers.asString(info['container_extension']) ??
          XtreamParsers.asString(json['container_extension']),
    );
  }

  factory SeriesEpisodeDto.fromJson(Map<String, dynamic> json) {
    return SeriesEpisodeDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Episódio sem título',
      seasonNumber: json['seasonNumber'] as int? ?? 0,
      episodeNumber: json['episodeNumber'] as int?,
      plot: json['plot'] as String?,
      duration: json['duration'] as String?,
      containerExtension: json['containerExtension'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'plot': plot,
      'duration': duration,
      'containerExtension': containerExtension,
    };
  }
}
