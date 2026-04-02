import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/tv/tv_focusable.dart';
import '../../../../features/live/domain/entities/live_epg_entry.dart';
import '../../../../features/live/domain/entities/live_stream.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/branded_artwork.dart';
import '../../../../shared/widgets/content_list_tile.dart';
import '../providers/live_providers.dart';
import '../support/live_playback_context.dart';
import 'live_tv_guide_screen.dart';

class LiveStreamsScreen extends ConsumerWidget {
  const LiveStreamsScreen({super.key, required this.categoryId});

  static const routePath = '/live/category/:categoryId';

  static String buildLocation(String categoryId) =>
      '/live/category/$categoryId';

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveCategoryId = categoryId == 'all' ? null : categoryId;
    final headerLayout = DeviceLayout.of(context);
    final isTvHeader = headerLayout.isTv;
    if (isTvHeader) {
      return LiveTvGuideScreen(initialCategoryId: effectiveCategoryId);
    }

    final streams = ref.watch(liveStreamsProvider(effectiveCategoryId));

    return AppScaffold(
      title: 'Ao vivo',
      subtitle: effectiveCategoryId == null
          ? 'Lista completa de canais com acesso imediato.'
          : 'Canais filtrados para este recorte ao vivo.',
      showBack: true,
      showBrand: false,
      decoratedHeader: true,
      child: AsyncStateBuilder(
        value: streams,
        isEmpty: (items) => items.isEmpty,
        emptyTitle: 'Sem canais disponíveis',
        emptyMessage: 'Nenhum canal foi encontrado para o filtro selecionado.',
        dataBuilder: (items) {
          final featured = _resolveFeatured(items);

          return LayoutBuilder(
            builder: (context, constraints) {
              final layout = DeviceLayout.of(context, constraints: constraints);
              if (layout.isTv) {
                return _LiveTvStreamsView(
                  layout: layout,
                  maxWidth: constraints.maxWidth,
                  items: items,
                  onOpenChannel: (item) =>
                      _openLivePlayer(context, items, item),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
                cacheExtent: layout.isTv ? 2200 : 1200,
                itemCount: items.length + 2,
                separatorBuilder: (context, index) =>
                    SizedBox(height: layout.cardSpacing),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _LiveHeroShelf(
                      layout: layout,
                      item: featured,
                      totalItems: items.length,
                      onPlay: () =>
                          _openLivePlayer(context, items, featured),
                    );
                  }

                  if (index == 1) {
                    return _LiveCatalogHeader(
                      layout: layout,
                      totalItems: items.length,
                    );
                  }

                  final item = items[index - 2];
                  return _LiveMobileChannelTile(
                    item: item,
                    autofocus: index == 2,
                    onPressed: () => _openLivePlayer(context, items, item),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

LiveStream _resolveFeatured(List<LiveStream> items) {
  return items.firstWhere(
    (item) => BrandedArtwork.normalizeArtworkUrl(item.iconUrl) != null,
    orElse: () => items.first,
  );
}

void _openLivePlayer(
  BuildContext context,
  List<LiveStream> streams,
  LiveStream item,
) {
  final currentIndex = streams.indexWhere((stream) => stream.id == item.id);
  if (currentIndex < 0) {
    return;
  }
  context.push(
    PlayerScreen.routePath,
    extra: buildLivePlaybackContext(streams, currentIndex),
  );
}

class _LiveTvStreamsView extends ConsumerStatefulWidget {
  const _LiveTvStreamsView({
    required this.layout,
    required this.maxWidth,
    required this.items,
    required this.onOpenChannel,
  });

  final DeviceLayout layout;
  final double maxWidth;
  final List<LiveStream> items;
  final ValueChanged<LiveStream> onOpenChannel;

  @override
  ConsumerState<_LiveTvStreamsView> createState() => _LiveTvStreamsViewState();
}

class _LiveTvStreamsViewState extends ConsumerState<_LiveTvStreamsView> {
  static const _focusSettleDelay = Duration(milliseconds: 220);
  final _focusedIndexNotifier = ValueNotifier<int>(0);
  String? _settledEpgStreamId;
  Timer? _focusSettleTimer;

  @override
  void initState() {
    super.initState();
    if (widget.items.isNotEmpty) {
      _settledEpgStreamId = widget.items.first.id;
      _prefetchNearbyEpg(0);
    }
  }

  @override
  void didUpdateWidget(covariant _LiveTvStreamsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.isEmpty) {
      _focusedIndexNotifier.value = 0;
      _settledEpgStreamId = null;
      _focusSettleTimer?.cancel();
      return;
    }
    if (_focusedIndexNotifier.value >= widget.items.length) {
      _focusedIndexNotifier.value = widget.items.length - 1;
    }
    final hasSettledItem = widget.items.any(
      (item) => item.id == _settledEpgStreamId,
    );
    if (!hasSettledItem) {
      _settledEpgStreamId = widget.items[_focusedIndexNotifier.value].id;
    }
  }

  @override
  void dispose() {
    _focusSettleTimer?.cancel();
    _focusedIndexNotifier.dispose();
    super.dispose();
  }

  void _setFocusedIndex(int index) {
    if (index < 0 || index >= widget.items.length) {
      return;
    }
    if (index != _focusedIndexNotifier.value) {
      _focusedIndexNotifier.value = index;
    }
    _scheduleSettledEpg(widget.items[index].id);
    _prefetchNearbyEpg(index);
  }

  void _scheduleSettledEpg(String streamId) {
    _focusSettleTimer?.cancel();
    if (_settledEpgStreamId == null) {
      setState(() {
        _settledEpgStreamId = streamId;
      });
      return;
    }
    _focusSettleTimer = Timer(_focusSettleDelay, () {
      if (!mounted || _settledEpgStreamId == streamId) {
        return;
      }
      setState(() {
        _settledEpgStreamId = streamId;
      });
    });
  }

  void _prefetchNearbyEpg(int index) {
    final candidates = <int>{index, index - 1, index + 1};
    for (final itemIndex in candidates) {
      if (itemIndex < 0 || itemIndex >= widget.items.length) {
        continue;
      }
      final item = widget.items[itemIndex];
      if (item.epgChannelId?.trim().isNotEmpty != true) {
        continue;
      }
      unawaited(ref.read(liveShortEpgProvider(item.id).future));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final layout = widget.layout;
    final spacing = layout.cardSpacing;
    final columns = layout.columnsForWidth(
      widget.maxWidth,
      minTileWidth: 232,
      maxColumns: 6,
    );
    final itemWidth = layout.itemWidth(
      widget.maxWidth,
      columns: columns,
      spacing: spacing,
    );
    final channelsGrid = Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (var index = 0; index < widget.items.length; index++)
          SizedBox(
            width: itemWidth,
            child: _LiveTvChannelCard(
              layout: layout,
              item: widget.items[index],
              autofocus: index == 0,
              onFocused: () => _setFocusedIndex(index),
              onPressed: () => widget.onOpenChannel(widget.items[index]),
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<int>(
          valueListenable: _focusedIndexNotifier,
          builder: (context, focusedIndex, _) {
            final safeIndex = focusedIndex.clamp(0, widget.items.length - 1);
            final focusedItem = widget.items[safeIndex];
            final settledEpgStreamId = _settledEpgStreamId ?? focusedItem.id;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutQuad,
                  child: _LiveFocusContextPanel(
                    key: ValueKey('focus-panel-${focusedItem.id}'),
                    layout: layout,
                    item: focusedItem,
                    totalItems: widget.items.length,
                    focusPosition: safeIndex + 1,
                    settledEpgStreamId: settledEpgStreamId,
                    onPlay: () => widget.onOpenChannel(focusedItem),
                  ),
                ),
                SizedBox(height: spacing),
                _LiveCatalogHeader(
                  layout: layout,
                  totalItems: widget.items.length,
                  focusPosition: safeIndex + 1,
                ),
              ],
            );
          },
        ),
        SizedBox(height: spacing),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
            child: channelsGrid,
          ),
        ),
      ],
    );
  }
}

class _LiveFocusContextPanel extends ConsumerWidget {
  const _LiveFocusContextPanel({
    super.key,
    required this.layout,
    required this.item,
    required this.totalItems,
    required this.focusPosition,
    required this.settledEpgStreamId,
    required this.onPlay,
  });

  final DeviceLayout layout;
  final LiveStream item;
  final int totalItems;
  final int focusPosition;
  final String settledEpgStreamId;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasEpgSignal = item.epgChannelId?.trim().isNotEmpty == true;
    final settledFocus = settledEpgStreamId == item.id;
    final shouldFetchEpg = hasEpgSignal && settledFocus;
    final epgAsync = shouldFetchEpg
        ? ref.watch(liveShortEpgProvider(item.id))
        : const AsyncValue<List<LiveEpgEntry>>.data(<LiveEpgEntry>[]);
    final resolved = shouldFetchEpg
        ? epgAsync.whenData(_resolveEpgState).value
        : null;
    final nowEntry = resolved?.current;
    final nowProgress = nowEntry == null
        ? null
        : _epgProgress(nowEntry, now: DateTime.now());
    final showProgress =
        !layout.isTvCompact && settledFocus && nowProgress != null;
    final contextLine = _resolveFocusContextLine(
      item: item,
      hasEpgSignal: hasEpgSignal,
      settledFocus: settledFocus,
      epgAsync: epgAsync,
      state: resolved,
    );
    final nowLabel = _resolveNowLabel(
      item: item,
      hasEpgSignal: hasEpgSignal,
      settledFocus: settledFocus,
      epgAsync: epgAsync,
      state: resolved,
    );
    final nextLabel = _resolveNextLabel(
      hasEpgSignal: hasEpgSignal,
      settledFocus: settledFocus,
      epgAsync: epgAsync,
      state: resolved,
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF091527),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.82),
            const Color(0xFF0D1B31),
          ],
        ),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: EdgeInsets.all(layout.isTvCompact ? 16 : 18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showSideArtwork = constraints.maxWidth >= 1040;
            final showHorizontalEpg = constraints.maxWidth >= 760;
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _LiveHeroChip(label: 'AO VIVO', layout: layout),
                    _LiveHeroChip(
                      label: '$focusPosition/$totalItems em foco',
                      layout: layout,
                    ),
                    if (item.hasArchive)
                      _LiveHeroChip(label: 'Com replay', layout: layout),
                    if (hasEpgSignal)
                      _LiveHeroChip(label: 'Agora e proximo', layout: layout),
                  ],
                ),
                SizedBox(height: layout.isTvCompact ? 8 : 10),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: layout.isTvCompact ? 33 : 37,
                    fontWeight: FontWeight.w800,
                    height: 1.02,
                  ),
                ),
                SizedBox(height: layout.isTvCompact ? 6 : 7),
                Text(
                  contextLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.83),
                    fontSize: layout.isTvCompact ? 14.5 : 15.5,
                  ),
                ),
                SizedBox(height: layout.isTvCompact ? 12 : 14),
                if (showHorizontalEpg)
                  Row(
                    children: [
                      Expanded(
                        child: _LiveContextSlot(
                          layout: layout,
                          title: 'Agora',
                          value: nowLabel,
                          progress: showProgress ? nowProgress : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _LiveContextSlot(
                          layout: layout,
                          title: 'Proximo',
                          value: nextLabel,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _LiveContextSlot(
                    layout: layout,
                    title: 'Agora',
                    value: nowLabel,
                    progress: showProgress ? nowProgress : null,
                  ),
                  const SizedBox(height: 8),
                  _LiveContextSlot(
                    layout: layout,
                    title: 'Proximo',
                    value: nextLabel,
                  ),
                ],
                SizedBox(height: layout.isTvCompact ? 12 : 14),
                FilledButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Assistir canal'),
                  style: ButtonStyle(
                    minimumSize: WidgetStatePropertyAll(
                      Size(0, layout.isTvCompact ? 52 : 56),
                    ),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ],
            );

            if (!showSideArtwork) {
              return content;
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: content),
                const SizedBox(width: 14),
                SizedBox(
                  width: 144,
                  child: BrandedArtwork(
                    imageUrl: item.iconUrl,
                    aspectRatio: 1,
                    fit: BoxFit.contain,
                    imagePadding: const EdgeInsets.all(14),
                    icon: Icons.live_tv_rounded,
                    placeholderLabel: 'Canal',
                    borderRadius: 16,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LiveContextSlot extends StatelessWidget {
  const _LiveContextSlot({
    required this.layout,
    required this.title,
    required this.value,
    this.progress,
  });

  final DeviceLayout layout;
  final String title;
  final String value;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.isTvCompact ? 10 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 0.6,
              color: onSurface.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: layout.isTvCompact ? 4 : 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.93),
              fontSize: layout.isTvCompact ? 14 : 15,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (progress != null) ...[
            SizedBox(height: layout.isTvCompact ? 5 : 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: layout.isTvCompact ? 3 : 4,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.78),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _resolveFocusContextLine({
  required LiveStream item,
  required bool hasEpgSignal,
  required bool settledFocus,
  required AsyncValue<List<LiveEpgEntry>> epgAsync,
  required _ResolvedEpgState? state,
}) {
  if (!settledFocus) {
    if (hasEpgSignal) {
      return 'Atualizando contexto do canal em foco';
    }
    return item.hasArchive
        ? 'Canal ao vivo com replay disponivel'
        : 'Canal ao vivo pronto para assistir';
  }
  if (state?.current != null) {
    return 'Em exibicao agora';
  }
  if (hasEpgSignal) {
    if (epgAsync.isLoading) {
      return 'Atualizando programacao deste canal';
    }
    return 'Programacao parcial disponivel quando informada';
  }
  return item.hasArchive
      ? 'Canal ao vivo com replay disponivel'
      : 'Canal ao vivo pronto para assistir';
}

String _resolveNowLabel({
  required LiveStream item,
  required bool hasEpgSignal,
  required bool settledFocus,
  required AsyncValue<List<LiveEpgEntry>> epgAsync,
  required _ResolvedEpgState? state,
}) {
  if (!settledFocus && hasEpgSignal) {
    return 'Carregando agora';
  }
  if (state?.current != null) {
    return state!.current!.title;
  }
  if (!hasEpgSignal) {
    return item.hasArchive
        ? 'Transmissao ao vivo com replay'
        : 'Transmissao ao vivo disponivel';
  }
  if (epgAsync.isLoading) {
    return 'Atualizando programacao';
  }
  return 'Programacao ainda nao informada';
}

String _resolveNextLabel({
  required bool hasEpgSignal,
  required bool settledFocus,
  required AsyncValue<List<LiveEpgEntry>> epgAsync,
  required _ResolvedEpgState? state,
}) {
  if (!settledFocus && hasEpgSignal) {
    return 'Carregando proximo horario';
  }
  if (state?.next != null) {
    return state!.next!.title;
  }
  if (!hasEpgSignal) {
    return 'Proximo horario indisponivel';
  }
  if (epgAsync.isLoading) {
    return 'Buscando proximo horario';
  }
  return 'Proximo horario ainda nao informado';
}

class _LiveHeroShelf extends ConsumerWidget {
  const _LiveHeroShelf({
    required this.layout,
    required this.item,
    required this.totalItems,
    required this.onPlay,
  });

  final DeviceLayout layout;
  final LiveStream item;
  final int totalItems;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = BrandedArtwork.normalizeArtworkUrl(item.iconUrl);
    final epgState = ref.watch(liveShortEpgProvider(item.id));
    final playButtonStyle = layout.isTv
        ? ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(0, layout.isTv ? 60 : 52)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.focused)) {
                return const Color(0xFFFFF3E7);
              }
              if (states.contains(WidgetState.pressed)) {
                return colorScheme.primary.withValues(alpha: 0.86);
              }
              return colorScheme.primary;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.focused)) {
                return const Color(0xFF161005);
              }
              return colorScheme.onPrimary;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.focused)) {
                return BorderSide(color: colorScheme.secondary, width: 2.8);
              }
              return BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.9),
              );
            }),
            elevation: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.focused) ? 11 : 2;
            }),
          )
        : null;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 28 : 22),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.45)),
      ),
      child: AspectRatio(
        aspectRatio: layout.isTv ? 16 / 5.8 : 16 / 8.4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF081224),
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.82),
                    const Color(0xFF0E1A2F),
                  ],
                ),
              ),
            ),
            if (image != null)
              Opacity(
                opacity: 0.18,
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  headers: const {'Accept-Encoding': 'identity'},
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xEE050B16),
                    const Color(0xC4050B16),
                    const Color(0x33050B16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(layout.isTv ? 24 : 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compactHero =
                      constraints.maxHeight < (layout.isTv ? 280 : 210);
                  final verticalGap = compactHero
                      ? (layout.isTv ? 6.0 : 4.0)
                      : (layout.isTv ? 8.0 : 6.0);
                  final sectionGap = compactHero
                      ? (layout.isTv ? 10.0 : 8.0)
                      : (layout.isTv ? 14.0 : 10.0);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Canal em destaque',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    letterSpacing: 1,
                                    color: colorScheme.secondary,
                                  ),
                            ),
                            SizedBox(height: verticalGap),
                            Text(
                              item.name,
                              maxLines: compactHero ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontSize: layout.isTv
                                        ? (compactHero ? 29 : 34)
                                        : (compactHero ? 20 : 24),
                                    height: 1.02,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            SizedBox(height: verticalGap),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _LiveHeroChip(
                                  label: '$totalItems canais',
                                  layout: layout,
                                ),
                                if (!compactHero)
                                  _LiveHeroChip(
                                    label: 'Grade Xtream',
                                    layout: layout,
                                  ),
                                if (!compactHero && item.hasArchive)
                                  _LiveHeroChip(
                                    label: 'Com replay',
                                    layout: layout,
                                  ),
                              ],
                            ),
                            SizedBox(height: sectionGap),
                            FilledButton.icon(
                              onPressed: onPlay,
                              style: playButtonStyle,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Assistir agora'),
                            ),
                            if (!compactHero) ...[
                              SizedBox(height: sectionGap),
                              _LiveEpgPanel(
                                asyncEntries: epgState,
                                compact: compactHero,
                                layout: layout,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (layout.isTv && !compactHero) ...[
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 132,
                          child: BrandedArtwork(
                            imageUrl: item.iconUrl,
                            aspectRatio: 1,
                            fit: BoxFit.contain,
                            imagePadding: const EdgeInsets.all(14),
                            icon: Icons.live_tv_rounded,
                            placeholderLabel: 'Canal',
                            borderRadius: 16,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveHeroChip extends StatelessWidget {
  const _LiveHeroChip({required this.label, required this.layout});

  final String label;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.isTv ? 11 : 9,
        vertical: layout.isTv ? 6 : 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: layout.isTv ? 12.5 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LiveCatalogHeader extends StatelessWidget {
  const _LiveCatalogHeader({
    required this.layout,
    required this.totalItems,
    this.focusPosition,
  });

  final DeviceLayout layout;
  final int totalItems;
  final int? focusPosition;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (layout.isTv) {
      return Row(
        children: [
          Text(
            'Canais',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: layout.isTvCompact ? 26 : 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          _LiveHeroChip(label: '$totalItems canais', layout: layout),
          if (focusPosition != null) ...[
            const SizedBox(width: 8),
            _LiveHeroChip(
              label: 'Foco ${focusPosition!}/$totalItems',
              layout: layout,
            ),
          ],
        ],
      );
    }

    return Container(
      padding: EdgeInsets.all(layout.isTv ? 18 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 20 : 16),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Container(
            width: layout.isTv ? 44 : 36,
            height: layout.isTv ? 44 : 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
            child: Icon(
              Icons.grid_view_rounded,
              color: colorScheme.primary,
              size: layout.isTv ? 24 : 20,
            ),
          ),
          SizedBox(width: layout.isTv ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Canais disponíveis • $totalItems',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: layout.isTv ? 21 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: layout.isTv ? 4 : 2),
                Text(
                  'Deslize, escolha um canal e entre direto no ao vivo.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.76),
                    fontSize: layout.isTv ? 13 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveMobileChannelTile extends ConsumerWidget {
  const _LiveMobileChannelTile({
    required this.item,
    required this.autofocus,
    required this.onPressed,
  });

  final LiveStream item;
  final bool autofocus;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epgAsync = ref.watch(liveShortEpgProvider(item.id));
    final epgState = epgAsync.value == null
        ? null
        : _resolveEpgState(epgAsync.value!);

    final defaultSubtitle = item.hasArchive
        ? 'Canal com replay disponível'
        : 'Canal disponível para assistir';
    final subtitle = epgState?.current != null
        ? 'Agora: ${epgState!.current!.title}'
        : defaultSubtitle;
    final metadata = <String>[
      'Ao vivo',
      if (item.hasArchive) 'Replay',
      if (item.isAdult) '18+' else 'Livre',
      if (item.epgChannelId?.trim().isNotEmpty == true) 'EPG',
      if (item.containerExtension?.trim().isNotEmpty == true)
        item.containerExtension!.trim().toUpperCase(),
      if (epgState?.next != null) 'Prox: ${epgState!.next!.title}',
    ];

    return ContentListTile(
      autofocus: autofocus,
      overline: 'Canal ao vivo',
      title: item.name,
      subtitle: subtitle,
      metadata: metadata,
      badge: item.hasArchive ? 'REPLAY' : 'LIVE',
      icon: Icons.live_tv_rounded,
      imageUrl: item.iconUrl,
      thumbnailAspectRatio: 1,
      thumbnailWidth: DeviceLayout.of(context).isTv ? 82 : 64,
      thumbnailFit: BoxFit.contain,
      imagePadding: EdgeInsets.all(DeviceLayout.of(context).isTv ? 12 : 14),
      thumbnailLabel: 'Canal',
      onPressed: onPressed,
    );
  }
}

class _LiveEpgPanel extends StatelessWidget {
  const _LiveEpgPanel({
    required this.asyncEntries,
    required this.compact,
    required this.layout,
  });

  final AsyncValue<List<LiveEpgEntry>> asyncEntries;
  final bool compact;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return asyncEntries.when(
      loading: () => Text(
        compact ? 'Carregando guia...' : 'Carregando programacao ao vivo...',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.72),
        ),
      ),
      error: (error, stackTrace) => Text(
        compact ? 'Guia indisponivel' : 'Programacao indisponivel no momento',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.72),
        ),
      ),
      data: (entries) {
        final state = _resolveEpgState(entries);
        if (state.current == null && state.next == null) {
          return Text(
            compact
                ? 'Programacao nao informada'
                : 'Programacao nao informada no momento',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          );
        }

        final current = state.current;
        final next = state.next;
        final progress = current == null
            ? null
            : _epgProgress(current, now: DateTime.now());

        if (compact) {
          return Text(
            current != null
                ? 'Agora: ${current.title}'
                : 'Proximo: ${next!.title}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.82),
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(layout.isTv ? 12 : 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.isTv ? 14 : 12),
            color: Colors.black.withValues(alpha: 0.28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (current != null) ...[
                Text(
                  'Agora: ${current.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.94),
                  ),
                ),
                if (progress != null) ...[
                  SizedBox(height: layout.isTv ? 7 : 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: layout.isTv ? 8 : 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ],
              if (next != null) ...[
                SizedBox(height: layout.isTv ? 8 : 7),
                Text(
                  'Proximo: ${next.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ResolvedEpgState {
  const _ResolvedEpgState({this.current, this.next});

  final LiveEpgEntry? current;
  final LiveEpgEntry? next;
}

_ResolvedEpgState _resolveEpgState(List<LiveEpgEntry> entries) {
  if (entries.isEmpty) {
    return const _ResolvedEpgState();
  }

  final now = DateTime.now();
  LiveEpgEntry? current;
  LiveEpgEntry? next;

  for (final entry in entries) {
    if (entry.isOnAirAt(now)) {
      current = entry;
      continue;
    }
    if (entry.startAt.isAfter(now)) {
      next = entry;
      break;
    }
  }

  if (current != null && next == null) {
    final currentIndex = entries.indexOf(current);
    if (currentIndex >= 0 && currentIndex + 1 < entries.length) {
      next = entries[currentIndex + 1];
    }
  }

  return _ResolvedEpgState(current: current, next: next);
}

double? _epgProgress(LiveEpgEntry entry, {required DateTime now}) {
  final total = entry.endAt.difference(entry.startAt).inMilliseconds;
  if (total <= 0) {
    return null;
  }
  final elapsed = now.difference(entry.startAt).inMilliseconds;
  final progress = elapsed / total;
  return progress.clamp(0.0, 1.0);
}

class _LiveTvChannelCard extends StatelessWidget {
  const _LiveTvChannelCard({
    required this.layout,
    required this.item,
    required this.onPressed,
    this.onFocused,
    this.autofocus = false,
  });

  final DeviceLayout layout;
  final LiveStream item;
  final VoidCallback onPressed;
  final VoidCallback? onFocused;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = item.hasArchive ? 'Replay disponivel' : 'Canal ao vivo';

    return TvFocusable(
      autofocus: autofocus,
      onPressed: onPressed,
      onFocusChanged: (focused) {
        if (focused) {
          onFocused?.call();
        }
      },
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: focused
                  ? [
                      colorScheme.primary.withValues(alpha: 0.22),
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.92,
                      ),
                    ]
                  : [
                      colorScheme.surface.withValues(alpha: 0.9),
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.74,
                      ),
                    ],
            ),
            border: Border.all(
              color: focused
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.44),
              width: focused ? 2 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  BrandedArtwork(
                    imageUrl: item.iconUrl,
                    aspectRatio: 16 / 9,
                    fit: BoxFit.contain,
                    imagePadding: const EdgeInsets.all(16),
                    borderRadius: 16,
                    placeholderLabel: 'Canal',
                    icon: Icons.live_tv_rounded,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: item.hasArchive
                            ? const Color(0xCC1FB7E7)
                            : const Color(0xCCFF4A57),
                      ),
                      child: Text(
                        item.hasArchive ? 'REPLAY' : 'LIVE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.76),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
