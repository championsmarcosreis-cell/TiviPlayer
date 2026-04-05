import 'package:flutter/material.dart';

enum OnDemandLibraryKind {
  movies,
  series,
  anime,
  kids;

  String get slug => name;

  static OnDemandLibraryKind? tryParse(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final kind in values) {
      if (kind.slug == normalized) {
        return kind;
      }
    }
    return null;
  }

  static OnDemandLibraryKind parse(
    String? value, {
    required OnDemandLibraryKind fallback,
  }) {
    return tryParse(value) ?? fallback;
  }
}

class OnDemandLibrarySpec {
  const OnDemandLibrarySpec._({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.catalogLabel,
    required this.icon,
    required this.categoryKeywords,
    required this.contentKeywords,
    this.badge,
  });

  final OnDemandLibraryKind kind;
  final String title;
  final String subtitle;
  final String description;
  final String catalogLabel;
  final IconData icon;
  final String? badge;
  final List<String> categoryKeywords;
  final List<String> contentKeywords;

  bool get isFilteredVariant =>
      kind == OnDemandLibraryKind.anime || kind == OnDemandLibraryKind.kids;
  bool get requiresExplicitServerSignal => kind == OnDemandLibraryKind.kids;

  bool matchesCategory({required String value, String? libraryKind}) {
    final canonicalKind = OnDemandLibraryKind.tryParse(libraryKind);
    if (canonicalKind != null) {
      return canonicalKind == kind;
    }

    if (requiresExplicitServerSignal) {
      return false;
    }

    if (_shouldKeepCategoryByDefault(value)) {
      return true;
    }

    return _matchesCategoryFallback(value);
  }

  bool matchesTextContent({
    required String primary,
    String secondary = '',
    String? libraryKind,
  }) {
    final canonicalKind = OnDemandLibraryKind.tryParse(libraryKind);
    if (canonicalKind != null) {
      return canonicalKind == kind;
    }

    if (requiresExplicitServerSignal) {
      return false;
    }

    if (_shouldKeepContentByDefault(primary, secondary)) {
      return true;
    }

    return _matchesContentFallback(primary, secondary);
  }

  bool hasExplicitSignal(String? libraryKind) {
    return OnDemandLibraryKind.tryParse(libraryKind) == kind;
  }

  bool _matchesCategoryFallback(String value) {
    final haystack = _normalize(value);
    if (haystack.isEmpty) {
      return false;
    }

    return categoryKeywords.any(haystack.contains);
  }

  bool _matchesContentFallback(String primary, [String secondary = '']) {
    final haystack = _normalize('$primary $secondary');
    if (haystack.isEmpty) {
      return false;
    }

    return contentKeywords.any(haystack.contains);
  }

  bool _shouldKeepCategoryByDefault(String value) {
    return switch (kind) {
      OnDemandLibraryKind.movies => !_matchesOtherVariantByCategory(
        value,
        const {OnDemandLibraryKind.kids},
      ),
      OnDemandLibraryKind.series => !_matchesOtherVariantByCategory(
        value,
        const {OnDemandLibraryKind.anime, OnDemandLibraryKind.kids},
      ),
      OnDemandLibraryKind.anime || OnDemandLibraryKind.kids => false,
    };
  }

  bool _shouldKeepContentByDefault(String primary, [String secondary = '']) {
    return switch (kind) {
      OnDemandLibraryKind.movies => true,
      OnDemandLibraryKind.series => !_matchesOtherVariantByContent(
        primary,
        secondary,
        const {OnDemandLibraryKind.anime, OnDemandLibraryKind.kids},
      ),
      OnDemandLibraryKind.anime || OnDemandLibraryKind.kids => false,
    };
  }

  bool _matchesOtherVariantByCategory(
    String value,
    Set<OnDemandLibraryKind> variants,
  ) {
    final haystack = _normalize(value);
    if (haystack.isEmpty) {
      return false;
    }

    for (final variant in variants) {
      final spec = OnDemandLibrarySpec.resolve(variant);
      if (spec.categoryKeywords.any(haystack.contains)) {
        return true;
      }
    }
    return false;
  }

  bool _matchesOtherVariantByContent(
    String primary,
    String secondary,
    Set<OnDemandLibraryKind> variants,
  ) {
    final haystack = _normalize('$primary $secondary');
    if (haystack.isEmpty) {
      return false;
    }

    for (final variant in variants) {
      final spec = OnDemandLibrarySpec.resolve(variant);
      if (spec.contentKeywords.any(haystack.contains)) {
        return true;
      }
    }
    return false;
  }

  String countLabel(int totalItems) {
    final noun = switch (kind) {
      OnDemandLibraryKind.series => totalItems == 1 ? 'série' : 'séries',
      OnDemandLibraryKind.anime => totalItems == 1 ? 'anime' : 'animes',
      _ => totalItems == 1 ? 'título' : 'títulos',
    };
    return '$totalItems $noun';
  }

  static OnDemandLibrarySpec resolve(OnDemandLibraryKind kind) {
    return switch (kind) {
      OnDemandLibraryKind.movies => const OnDemandLibrarySpec._(
        kind: OnDemandLibraryKind.movies,
        title: 'Filmes',
        subtitle: 'Catálogo sob demanda',
        description:
            'Entre direto no catálogo e navegue por coleções sem passar por um hub pesado antes dos posters.',
        catalogLabel: 'Filmes em catálogo',
        icon: Icons.movie_creation_outlined,
        categoryKeywords: <String>[],
        contentKeywords: <String>[],
      ),
      OnDemandLibraryKind.series => const OnDemandLibrarySpec._(
        kind: OnDemandLibraryKind.series,
        title: 'Séries',
        subtitle: 'Catálogo sob demanda',
        description:
            'Abra séries, temporadas e episódios com uma entrada mais direta e visual de catálogo mais consistente com a Home.',
        catalogLabel: 'Séries em catálogo',
        icon: Icons.tv_rounded,
        categoryKeywords: <String>[],
        contentKeywords: <String>[],
      ),
      OnDemandLibraryKind.anime => const OnDemandLibrarySpec._(
        kind: OnDemandLibraryKind.anime,
        title: 'Anime',
        subtitle: 'Biblioteca dedicada',
        description:
            'Biblioteca filtrada para anime, com navegação por coleções relevantes e foco total nos posters.',
        catalogLabel: 'Animes em catálogo',
        icon: Icons.auto_awesome_rounded,
        badge: 'ANIME',
        categoryKeywords: <String>[
          'anime',
          'animes',
          'otaku',
          'donghua',
          'animacao japonesa',
          'animacao japonesa',
        ],
        contentKeywords: <String>['anime', 'animes', 'otaku', 'donghua'],
      ),
      OnDemandLibraryKind.kids => const OnDemandLibrarySpec._(
        kind: OnDemandLibraryKind.kids,
        title: 'Kids',
        subtitle: 'Biblioteca infantil',
        description:
            'Uma entrada própria para conteúdo infantil, com acesso rápido a filmes e séries em um fluxo de descoberta mais leve.',
        catalogLabel: 'Catálogo Kids',
        icon: Icons.rocket_launch_rounded,
        badge: 'KIDS',
        categoryKeywords: <String>[
          'kids',
          'kid',
          'infantil',
          'criancas',
          'crianca',
          'children',
          'child',
          'family',
          'familia',
          'cartoon',
          'disney',
          'pixar',
          'animacao',
        ],
        contentKeywords: <String>[
          'kids',
          'kid',
          'infantil',
          'criancas',
          'crianca',
          'children',
          'child',
          'family',
          'familia',
          'cartoon',
          'disney',
          'pixar',
          'animacao',
        ],
      ),
    };
  }
}

String buildLibraryLocation(
  String path, {
  required OnDemandLibraryKind kind,
  required OnDemandLibraryKind defaultKind,
}) {
  if (kind == defaultKind) {
    return path;
  }

  return Uri(path: path, queryParameters: {'library': kind.slug}).toString();
}

String normalizeLibraryText(String value) => _normalize(value);

List<String> splitLibraryGenres(String? value) {
  final source = value?.trim();
  if (source == null || source.isEmpty) {
    return const <String>[];
  }

  final seen = <String>{};
  final genres = <String>[];
  for (final rawPart in source.split(RegExp(r'[,/;|]'))) {
    final genre = rawPart.trim();
    if (genre.isEmpty) {
      continue;
    }

    final key = _normalize(genre);
    if (key.isEmpty || !seen.add(key)) {
      continue;
    }

    genres.add(genre);
  }

  return genres;
}

bool matchesLibraryGenre(String? rawGenres, String selectedGenre) {
  final selectedKey = _normalize(selectedGenre);
  if (selectedKey.isEmpty) {
    return true;
  }

  for (final genre in splitLibraryGenres(rawGenres)) {
    if (_normalize(genre) == selectedKey) {
      return true;
    }
  }

  return false;
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ì', 'i')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ò', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ç', 'c');
}
