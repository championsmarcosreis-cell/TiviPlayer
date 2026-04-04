import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/live/domain/entities/live_stream.dart';
import '../../../../features/live/presentation/providers/live_providers.dart';
import '../../../../features/live/presentation/support/live_playback_context.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
import '../../../../features/series/domain/entities/series_item.dart';
import '../../../../features/series/presentation/providers/series_providers.dart';
import '../../../../features/series/presentation/screens/series_details_screen.dart';
import '../../../../features/vod/domain/entities/vod_stream.dart';
import '../../../../features/vod/presentation/providers/vod_providers.dart';
import '../../../../features/vod/presentation/screens/vod_details_screen.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/presentation/screens/home_screen.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/branded_artwork.dart';
import '../../../../shared/widgets/mobile_primary_dock.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  static const routePath = '/search';

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _kMinSearchLength = 2;
  static const _kSearchDebounce = Duration(milliseconds: 320);

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _debouncedQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim();
    if (_query == nextQuery) {
      return;
    }

    _debounceTimer?.cancel();
    setState(() {
      _query = nextQuery;
    });
    _debounceTimer = Timer(_kSearchDebounce, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _debouncedQuery = nextQuery;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final shouldSearch = _debouncedQuery.length >= _kMinSearchLength;
    final liveAsync = shouldSearch
        ? ref.watch(liveStreamsProvider(null))
        : const AsyncValue<List<LiveStream>>.data(<LiveStream>[]);
    final vodAsync = shouldSearch
        ? ref.watch(vodStreamsProvider(null))
        : const AsyncValue<List<VodStream>>.data(<VodStream>[]);
    final seriesAsync = shouldSearch
        ? ref.watch(seriesItemsProvider(null))
        : const AsyncValue<List<SeriesItem>>.data(<SeriesItem>[]);

    final liveItems = _asyncDataOrEmpty(liveAsync);
    final vodItems = _asyncDataOrEmpty(vodAsync);
    final seriesItems = _asyncDataOrEmpty(seriesAsync);
    final liveMatches = _filterLiveResults(liveItems, _debouncedQuery);
    final vodMatches = _filterVodResults(vodItems, _debouncedQuery);
    final seriesMatches = _filterSeriesResults(seriesItems, _debouncedQuery);
    final isLoading =
        liveAsync.isLoading || vodAsync.isLoading || seriesAsync.isLoading;
    final hasAnyError =
        liveAsync.hasError || vodAsync.hasError || seriesAsync.hasError;
    final isTypingAhead =
        _query.length >= _kMinSearchLength && _query != _debouncedQuery;
    final isQueryTooShort =
        _query.isNotEmpty && _query.length < _kMinSearchLength;

    return AppScaffold(
      title: 'Busca',
      subtitle: 'Encontre TV ao vivo, filmes e séries em um só lugar.',
      showBack: true,
      showBrand: false,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(HomeScreen.routePath);
      },
      mobileBottomBar: const MobilePrimaryDock(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = DeviceLayout.of(context, constraints: constraints);

          return ListView(
            padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
            children: [
              _SearchFieldCard(
                controller: _searchController,
                hasText: _query.isNotEmpty,
                onClear: () => _searchController.clear(),
              ),
              SizedBox(height: layout.sectionSpacing),
              if (_query.isEmpty)
                const _SearchEmptyPrompt()
              else if (isQueryTooShort)
                const _SearchMinLengthPrompt()
              else if (isTypingAhead)
                _SearchWaitingPrompt(query: _query)
              else if (isLoading &&
                  liveItems.isEmpty &&
                  vodItems.isEmpty &&
                  seriesItems.isEmpty)
                const Center(child: CircularProgressIndicator())
              else ...[
                _SearchResultsSummary(
                  query: _debouncedQuery,
                  liveCount: liveMatches.length,
                  vodCount: vodMatches.length,
                  seriesCount: seriesMatches.length,
                ),
                SizedBox(height: layout.cardSpacing),
                if (liveMatches.isNotEmpty) ...[
                  _SearchSectionHeader(
                    title: 'TV ao vivo',
                    subtitle: '${liveMatches.length} resultado(s)',
                  ),
                  SizedBox(height: layout.cardSpacing),
                  ...liveMatches
                      .take(8)
                      .map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: layout.cardSpacing),
                          child: _SearchResultTile(
                            title: item.name,
                            subtitle: 'Canal ao vivo',
                            badge: 'AO VIVO',
                            artworkUrl: item.iconUrl,
                            icon: Icons.live_tv_rounded,
                            onTap: () =>
                                _openLiveResult(context, liveItems, item),
                          ),
                        ),
                      ),
                  SizedBox(height: layout.sectionSpacing),
                ],
                if (vodMatches.isNotEmpty) ...[
                  _SearchSectionHeader(
                    title: 'Filmes',
                    subtitle: '${vodMatches.length} resultado(s)',
                  ),
                  SizedBox(height: layout.cardSpacing),
                  ...vodMatches
                      .take(8)
                      .map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: layout.cardSpacing),
                          child: _SearchResultTile(
                            title: item.name,
                            subtitle: 'Filme',
                            badge: 'FILME',
                            artworkUrl: item.coverUrl,
                            icon: Icons.local_movies_rounded,
                            onTap: () => context.push(
                              VodDetailsScreen.buildLocation(item.id),
                            ),
                          ),
                        ),
                      ),
                  SizedBox(height: layout.sectionSpacing),
                ],
                if (seriesMatches.isNotEmpty) ...[
                  _SearchSectionHeader(
                    title: 'Séries',
                    subtitle: '${seriesMatches.length} resultado(s)',
                  ),
                  SizedBox(height: layout.cardSpacing),
                  ...seriesMatches
                      .take(8)
                      .map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: layout.cardSpacing),
                          child: _SearchResultTile(
                            title: item.name,
                            subtitle: item.plot?.trim().isNotEmpty == true
                                ? item.plot!.trim()
                                : 'Série',
                            badge: 'SÉRIE',
                            artworkUrl: item.coverUrl,
                            icon: Icons.tv_rounded,
                            onTap: () => context.push(
                              SeriesDetailsScreen.buildLocation(item.id),
                            ),
                          ),
                        ),
                      ),
                ],
                if (liveMatches.isEmpty &&
                    vodMatches.isEmpty &&
                    seriesMatches.isEmpty)
                  _SearchNoResults(query: _debouncedQuery),
              ],
              if (hasAnyError &&
                  liveItems.isEmpty &&
                  vodItems.isEmpty &&
                  seriesItems.isEmpty) ...[
                SizedBox(height: layout.sectionSpacing),
                const _SearchErrorCard(),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openLiveResult(
    BuildContext context,
    List<LiveStream> liveItems,
    LiveStream item,
  ) {
    final currentIndex = liveItems.indexWhere(
      (candidate) => candidate.id == item.id,
    );
    if (currentIndex < 0) {
      return;
    }

    context.push(
      PlayerScreen.routePath,
      extra: buildLivePlaybackContext(liveItems, currentIndex),
    );
  }
}

List<T> _asyncDataOrEmpty<T>(AsyncValue<List<T>> value) {
  return value.maybeWhen(data: (items) => items, orElse: () => <T>[]);
}

List<LiveStream> _filterLiveResults(List<LiveStream> items, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return const <LiveStream>[];
  }

  return items
      .where((item) => item.name.toLowerCase().contains(normalizedQuery))
      .toList(growable: false);
}

List<VodStream> _filterVodResults(List<VodStream> items, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return const <VodStream>[];
  }

  return items
      .where((item) => item.name.toLowerCase().contains(normalizedQuery))
      .toList(growable: false);
}

List<SeriesItem> _filterSeriesResults(List<SeriesItem> items, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return const <SeriesItem>[];
  }

  return items
      .where((item) {
        final plot = item.plot?.toLowerCase() ?? '';
        return item.name.toLowerCase().contains(normalizedQuery) ||
            plot.contains(normalizedQuery);
      })
      .toList(growable: false);
}

class _SearchFieldCard extends StatelessWidget {
  const _SearchFieldCard({
    required this.controller,
    required this.hasText,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.24)),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        autofocus: true,
        style: Theme.of(context).textTheme.titleMedium,
        decoration: InputDecoration(
          hintText: 'Busque por canal, filme ou série',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _SearchEmptyPrompt extends StatelessWidget {
  const _SearchEmptyPrompt();

  @override
  Widget build(BuildContext context) {
    return const _SearchMessageCard(
      icon: Icons.search_rounded,
      title: 'Busca geral do app',
      message: 'Digite para procurar em TV ao vivo, filmes e séries.',
    );
  }
}

class _SearchMinLengthPrompt extends StatelessWidget {
  const _SearchMinLengthPrompt();

  @override
  Widget build(BuildContext context) {
    return const _SearchMessageCard(
      icon: Icons.keyboard_rounded,
      title: 'Digite mais um pouco',
      message: 'Use pelo menos 2 caracteres para iniciar a busca.',
    );
  }
}

class _SearchWaitingPrompt extends StatelessWidget {
  const _SearchWaitingPrompt({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return _SearchMessageCard(
      icon: Icons.search_rounded,
      title: 'Procurando',
      message: 'Preparando resultados para "$query"...',
    );
  }
}

class _SearchNoResults extends StatelessWidget {
  const _SearchNoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return _SearchMessageCard(
      icon: Icons.search_off_rounded,
      title: 'Nada encontrado',
      message: 'Nenhum resultado corresponde a "$query".',
    );
  }
}

class _SearchErrorCard extends StatelessWidget {
  const _SearchErrorCard();

  @override
  Widget build(BuildContext context) {
    return const _SearchMessageCard(
      icon: Icons.signal_wifi_connected_no_internet_4_rounded,
      title: 'Busca indisponível',
      message: 'Não foi possível carregar a busca agora.',
    );
  }
}

class _SearchMessageCard extends StatelessWidget {
  const _SearchMessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsSummary extends StatelessWidget {
  const _SearchResultsSummary({
    required this.query,
    required this.liveCount,
    required this.vodCount,
    required this.seriesCount,
  });

  final String query;
  final int liveCount;
  final int vodCount;
  final int seriesCount;

  @override
  Widget build(BuildContext context) {
    final total = liveCount + vodCount + seriesCount;

    return Text(
      total == 1
          ? '1 resultado para "$query"'
          : '$total resultados para "$query"',
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _SearchSectionHeader extends StatelessWidget {
  const _SearchSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.artworkUrl,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String? artworkUrl;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: BrandedArtwork(
                    imageUrl: artworkUrl,
                    aspectRatio: 1,
                    borderRadius: 16,
                    icon: icon,
                    placeholderLabel: title,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Text(
                            badge,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.primary,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
