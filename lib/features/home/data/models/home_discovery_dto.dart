import '../../../../core/network/xtream_parsers.dart';

class HomeDiscoveryDto {
  const HomeDiscoveryDto({
    required this.generatedAt,
    required this.heroSlider,
    required this.hero,
    required this.highlights,
    required this.continueWatching,
    required this.hasContinueWatchingField,
    required this.moviesLibrary,
    required this.seriesLibrary,
    required this.animeLibrary,
    required this.liveLibrary,
    required this.libraries,
    required this.liveNow,
    required this.trendingNow,
    required this.moviesForToday,
    required this.seriesToBinge,
    required this.animeSpotlight,
    required this.rails,
  });

  final String? generatedAt;
  final HomeDiscoveryRailDto? heroSlider;
  final HomeDiscoveryHeroDto? hero;
  final HomeDiscoveryRailDto? highlights;
  final HomeDiscoveryItemDto? continueWatching;
  final bool hasContinueWatchingField;
  final HomeDiscoveryRailDto? moviesLibrary;
  final HomeDiscoveryRailDto? seriesLibrary;
  final HomeDiscoveryRailDto? animeLibrary;
  final HomeDiscoveryRailDto? liveLibrary;
  final List<HomeDiscoveryRailDto> libraries;
  final HomeDiscoveryRailDto? liveNow;
  final HomeDiscoveryRailDto? trendingNow;
  final HomeDiscoveryRailDto? moviesForToday;
  final HomeDiscoveryRailDto? seriesToBinge;
  final HomeDiscoveryRailDto? animeSpotlight;
  final List<HomeDiscoveryRailDto> rails;

  factory HomeDiscoveryDto.fromApi(Map<String, dynamic> payload) {
    final home = XtreamParsers.asMap(payload['home']) ?? <String, dynamic>{};

    return HomeDiscoveryDto(
      generatedAt: XtreamParsers.asString(home['generated_at']),
      heroSlider: HomeDiscoveryRailDto.fromApi(home['hero_slider']),
      hero: HomeDiscoveryHeroDto.fromApi(home['hero']),
      highlights: HomeDiscoveryRailDto.fromApi(home['highlights']),
      continueWatching: _parseContinueWatching(home['continue_watching']),
      hasContinueWatchingField: home.containsKey('continue_watching'),
      moviesLibrary: HomeDiscoveryRailDto.fromApi(home['movies_library']),
      seriesLibrary: HomeDiscoveryRailDto.fromApi(home['series_library']),
      animeLibrary: HomeDiscoveryRailDto.fromApi(home['anime_library']),
      liveLibrary: HomeDiscoveryRailDto.fromApi(home['live_library']),
      libraries: _parseRails(home['libraries']),
      liveNow: HomeDiscoveryRailDto.fromApi(home['live_now']),
      trendingNow: HomeDiscoveryRailDto.fromApi(home['trending_now']),
      moviesForToday: HomeDiscoveryRailDto.fromApi(home['movies_for_today']),
      seriesToBinge: HomeDiscoveryRailDto.fromApi(home['series_to_binge']),
      animeSpotlight: HomeDiscoveryRailDto.fromApi(home['anime_spotlight']),
      rails: _parseRails(home['rails']),
    );
  }

  static HomeDiscoveryItemDto? _parseContinueWatching(dynamic raw) {
    if (raw == null) {
      return null;
    }

    final asMap = XtreamParsers.asMap(raw);
    if (asMap != null) {
      final directItem = HomeDiscoveryItemDto.fromApi(raw);
      if (directItem != null) {
        return directItem;
      }

      final nestedItem = HomeDiscoveryItemDto.fromApi(asMap['item']);
      if (nestedItem != null) {
        return nestedItem;
      }

      final items = XtreamParsers.asList(asMap['items']);
      if (items.isNotEmpty) {
        return HomeDiscoveryItemDto.fromApi(items.first);
      }
      return null;
    }

    final asList = XtreamParsers.asList(raw);
    if (asList.isEmpty) {
      return null;
    }
    return HomeDiscoveryItemDto.fromApi(asList.first);
  }

  static List<HomeDiscoveryRailDto> _parseRails(dynamic raw) {
    return XtreamParsers.asList(raw)
        .map(HomeDiscoveryRailDto.fromApi)
        .whereType<HomeDiscoveryRailDto>()
        .toList();
  }
}

class HomeDiscoveryHeroDto {
  const HomeDiscoveryHeroDto({
    required this.item,
    required this.source,
    required this.rationale,
  });

  final HomeDiscoveryItemDto? item;
  final String? source;
  final String? rationale;

  static HomeDiscoveryHeroDto? fromApi(dynamic raw) {
    final map = XtreamParsers.asMap(raw);
    if (map == null) {
      return null;
    }

    return HomeDiscoveryHeroDto(
      item: HomeDiscoveryItemDto.fromApi(map['item']),
      source: XtreamParsers.asString(map['source']),
      rationale: XtreamParsers.asString(map['rationale']),
    );
  }
}

class HomeDiscoveryRailDto {
  const HomeDiscoveryRailDto({
    required this.slug,
    required this.title,
    required this.description,
    required this.layout,
    required this.items,
  });

  final String? slug;
  final String? title;
  final String? description;
  final String? layout;
  final List<HomeDiscoveryItemDto> items;

  static HomeDiscoveryRailDto? fromApi(dynamic raw) {
    final map = XtreamParsers.asMap(raw);
    if (map == null) {
      return null;
    }

    final items = XtreamParsers.asList(map['items'])
        .map(HomeDiscoveryItemDto.fromApi)
        .whereType<HomeDiscoveryItemDto>()
        .toList();

    return HomeDiscoveryRailDto(
      slug: XtreamParsers.asString(map['slug']),
      title: XtreamParsers.asString(map['title']),
      description: XtreamParsers.asString(map['description']),
      layout: XtreamParsers.asString(map['layout']),
      items: items,
    );
  }
}

class HomeDiscoveryItemDto {
  const HomeDiscoveryItemDto({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.image,
    required this.backdrop,
    required this.mediaType,
    required this.contentId,
    required this.tmdbId,
    required this.rating,
    required this.year,
    required this.genres,
    required this.runtime,
    required this.provider,
    required this.channelNumber,
    required this.progress,
    required this.badges,
    required this.genreIds,
  });

  final String? id;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? image;
  final String? backdrop;
  final String? mediaType;
  final String? contentId;
  final int? tmdbId;
  final double? rating;
  final int? year;
  final List<String> genres;
  final int? runtime;
  final String? provider;
  final int? channelNumber;
  final double? progress;
  final List<String> badges;
  final List<int> genreIds;

  String? get preferredArtwork => image ?? backdrop;

  static HomeDiscoveryItemDto? fromApi(dynamic raw) {
    final map = XtreamParsers.asMap(raw);
    if (map == null) {
      return null;
    }

    return HomeDiscoveryItemDto(
      id: XtreamParsers.asString(map['id']),
      title: XtreamParsers.asString(map['title']),
      subtitle: XtreamParsers.asString(map['subtitle']),
      description: XtreamParsers.asString(map['description']),
      image: XtreamParsers.asString(map['image']),
      backdrop: XtreamParsers.asString(map['backdrop']),
      mediaType: XtreamParsers.asString(map['media_type']),
      contentId: XtreamParsers.asString(map['content_id']),
      tmdbId: XtreamParsers.asInt(map['tmdb_id']),
      rating: _asDouble(map['rating']),
      year: XtreamParsers.asInt(map['year']),
      genres: XtreamParsers.asList(
        map['genres'],
      ).map(XtreamParsers.asString).whereType<String>().toList(),
      runtime: XtreamParsers.asInt(map['runtime']),
      provider: XtreamParsers.asString(map['provider']),
      channelNumber: XtreamParsers.asInt(map['channel_number']),
      progress: _asDouble(map['progress']),
      badges: XtreamParsers.asList(
        map['badges'],
      ).map(XtreamParsers.asString).whereType<String>().toList(),
      genreIds: XtreamParsers.asList(
        map['genre_ids'],
      ).map(XtreamParsers.asInt).whereType<int>().toList(),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
