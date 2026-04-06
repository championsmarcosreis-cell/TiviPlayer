import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/tv/tv_focusable.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/presentation/screens/home_screen.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/branded_artwork.dart';
import '../../../../shared/widgets/mobile_primary_dock.dart';
import '../../domain/entities/live_category.dart';
import '../../domain/entities/live_epg_entry.dart';
import '../../domain/entities/live_stream.dart';
import '../providers/live_providers.dart';
import '../support/live_playback_context.dart';
import 'live_tv_guide_screen.dart';

const _kGuideMobileAccent = Color(0xFF27C2FF);
const _kGuideMobileAccentSoft = Color(0x3327C2FF);
const _kGuideMobileAccentGlow = Color(0x1A27C2FF);
const _kGuideMobileAction = Color(0xFFFF7A1A);
const _kGuideMobilePanelTop = Color(0xFF142338);
const _kGuideMobilePanelBottom = Color(0xFF0E1828);

class LiveCategoriesScreen extends StatelessWidget {
  const LiveCategoriesScreen({super.key});

  static const routePath = '/live';

  @override
  Widget build(BuildContext context) {
    return const _LiveCategoriesView();
  }
}

class _LiveCategoriesView extends ConsumerStatefulWidget {
  const _LiveCategoriesView();

  @override
  ConsumerState<_LiveCategoriesView> createState() =>
      _LiveCategoriesViewState();
}

class _LiveCategoriesViewState extends ConsumerState<_LiveCategoriesView> {
  final TextEditingController _searchController = TextEditingController();
  late final DateTime _guideWindowStart;
  late final DateTime _guideWindowEnd;
  late final List<_MobileGuideTimeSlot> _timeSlots;
  late String _selectedTimeSlotId;
  String _selectedCategoryId = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _guideWindowStart = _resolveGuideWindowStart(now);
    _guideWindowEnd = _guideWindowStart.add(const Duration(minutes: 180));
    _timeSlots = _buildMobileGuideTimeSlots(now);
    _selectedTimeSlotId = _timeSlots.first.id;
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextValue = _searchController.text.trim();
    if (_searchQuery == nextValue) {
      return;
    }
    setState(() {
      _searchQuery = nextValue;
    });
  }

  _MobileGuideTimeSlot get _selectedTimeSlot {
    return _timeSlots.firstWhere(
      (slot) => slot.id == _selectedTimeSlotId,
      orElse: () => _timeSlots.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);
    if (layout.isTv) {
      return const LiveTvGuideScreen();
    }

    final categoriesAsync = ref.watch(liveCategoriesProvider);
    final requestCategoryId = _selectedCategoryId == 'all'
        ? null
        : _selectedCategoryId;
    final streamsAsync = ref.watch(liveStreamsProvider(requestCategoryId));

    return AppScaffold(
      title: 'Guia ao vivo',
      subtitle: 'Busca, filtros e canais no mesmo fluxo mobile.',
      showBack: true,
      showBrand: false,
      decoratedHeader: false,
      mobileBottomBar: const MobilePrimaryDock(),
      onBack: () => context.go(HomeScreen.routePath),
      child: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _MobileGuideStateCard(
          title: 'Falha ao carregar filtros',
          message: 'Nao foi possivel abrir o guia ao vivo.',
          icon: Icons.error_outline_rounded,
        ),
        data: (categories) {
          final filters = _buildGuideFilters(categories);
          if (!filters.any((item) => item.id == _selectedCategoryId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _selectedCategoryId = 'all';
              });
            });
          }

          return streamsAsync.when(
            loading: () => _MobileGuideSkeleton(
              layout: layout,
              filters: filters,
              selectedCategoryId: _selectedCategoryId,
              searchController: _searchController,
              windowLabel:
                  '${_formatGuideClock(_guideWindowStart)}-${_formatGuideClock(_guideWindowEnd)}',
              timeSlots: _timeSlots,
              selectedTimeSlotId: _selectedTimeSlot.id,
              onSelectTimeSlot: _handleTimeSlotSelected,
            ),
            error: (_, _) => _MobileGuideFrame(
              layout: layout,
              filters: filters,
              selectedCategoryId: _selectedCategoryId,
              searchController: _searchController,
              onSelectCategory: _handleCategorySelected,
              windowLabel:
                  '${_formatGuideClock(_guideWindowStart)}-${_formatGuideClock(_guideWindowEnd)}',
              timeSlots: _timeSlots,
              selectedTimeSlotId: _selectedTimeSlot.id,
              onSelectTimeSlot: _handleTimeSlotSelected,
              body: const _MobileGuideStateCard(
                title: 'Falha ao carregar canais',
                message: 'Nao foi possivel montar a lista de canais agora.',
                icon: Icons.signal_wifi_connected_no_internet_4_rounded,
              ),
            ),
            data: (streams) {
              final visibleStreams = _filterGuideStreams(
                streams: streams,
                searchQuery: _searchQuery,
              );
              final liveWithEpg = visibleStreams
                  .where((item) => item.epgChannelId?.trim().isNotEmpty == true)
                  .length;
              final liveWithReplay = visibleStreams
                  .where((item) => item.hasArchive)
                  .length;
              final selectedTimeSlot = _selectedTimeSlot;

              return _MobileGuideFrame(
                layout: layout,
                filters: filters,
                selectedCategoryId: _selectedCategoryId,
                searchController: _searchController,
                onSelectCategory: _handleCategorySelected,
                windowLabel:
                    '${_formatGuideClock(_guideWindowStart)}-${_formatGuideClock(_guideWindowEnd)}',
                timeSlots: _timeSlots,
                selectedTimeSlotId: selectedTimeSlot.id,
                onSelectTimeSlot: _handleTimeSlotSelected,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MobileGuideSummaryCard(
                      layout: layout,
                      visibleCount: visibleStreams.length,
                      totalFilters: filters.length,
                      liveWithEpg: liveWithEpg,
                      liveWithReplay: liveWithReplay,
                    ),
                    SizedBox(height: layout.sectionSpacing + 6),
                    if (visibleStreams.isEmpty)
                      _MobileGuideStateCard(
                        title: 'Nenhum canal neste recorte',
                        message: _searchQuery.isNotEmpty
                            ? 'Nenhum canal corresponde a "$_searchQuery".'
                            : 'Nao ha canais para este filtro no momento.',
                        icon: Icons.filter_alt_off_rounded,
                      )
                    else ...[
                      _MobileGuideSectionHeader(
                        title: 'Canais no guia',
                        subtitle: selectedTimeSlot.isNow
                            ? 'O canal e o programa atual ficam no mesmo contexto.'
                            : 'Os cards mostram o que acontece em ${selectedTimeSlot.label}.',
                      ),
                      SizedBox(height: layout.cardSpacing),
                      Column(
                        children: [
                          for (
                            var index = 0;
                            index < visibleStreams.length;
                            index++
                          ) ...[
                            _MobileGuideChannelTile(
                              item: visibleStreams[index],
                              visibleStreams: visibleStreams,
                              channelIndex: index,
                              autofocus: index == 0,
                              selectedTimeSlot: selectedTimeSlot,
                            ),
                            if (index < visibleStreams.length - 1)
                              SizedBox(height: layout.cardSpacing),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleCategorySelected(String categoryId) {
    if (_selectedCategoryId == categoryId) {
      return;
    }
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  void _handleTimeSlotSelected(String slotId) {
    if (_selectedTimeSlotId == slotId) {
      return;
    }
    setState(() {
      _selectedTimeSlotId = slotId;
    });
  }
}

class _MobileGuideFrame extends StatelessWidget {
  const _MobileGuideFrame({
    required this.layout,
    required this.filters,
    required this.selectedCategoryId,
    required this.searchController,
    required this.onSelectCategory,
    required this.windowLabel,
    required this.timeSlots,
    required this.selectedTimeSlotId,
    required this.onSelectTimeSlot,
    required this.body,
  });

  final DeviceLayout layout;
  final List<_GuideCategoryFilter> filters;
  final String selectedCategoryId;
  final TextEditingController searchController;
  final ValueChanged<String> onSelectCategory;
  final String windowLabel;
  final List<_MobileGuideTimeSlot> timeSlots;
  final String selectedTimeSlotId;
  final ValueChanged<String> onSelectTimeSlot;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MobileGuideSearchField(controller: searchController),
              SizedBox(height: layout.sectionSpacing + 2),
              _MobileGuideSectionHeader(
                title: 'Filtros do guia',
                subtitle: 'Troque de recorte sem sair da tela.',
              ),
              SizedBox(height: layout.cardSpacing),
              _MobileGuideFilterStrip(
                layout: layout,
                filters: filters,
                selectedCategoryId: selectedCategoryId,
                onSelectCategory: onSelectCategory,
              ),
              SizedBox(height: layout.sectionSpacing + 10),
            ],
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _MobileGuideTimelineHeaderDelegate(
            extent: 136,
            child: _MobileGuidePinnedTimeline(
              layout: layout,
              windowLabel: windowLabel,
              slots: timeSlots,
              selectedSlotId: selectedTimeSlotId,
              onSelectSlot: onSelectTimeSlot,
            ),
          ),
        ),
        SliverToBoxAdapter(child: body),
        SliverToBoxAdapter(child: SizedBox(height: layout.pageBottomPadding)),
      ],
    );
  }
}

class _MobileGuideSearchField extends StatelessWidget {
  const _MobileGuideSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface.withValues(alpha: 0.9),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.68),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar canal...',
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.54),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorScheme.onSurface.withValues(alpha: 0.68),
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: controller.clear,
                  icon: Icon(
                    Icons.close_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.66),
                  ),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: _kGuideMobileAccent, width: 1.3),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _MobileGuideSectionHeader extends StatelessWidget {
  const _MobileGuideSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.68),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _MobileGuideTimelineHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  const _MobileGuideTimelineHeaderDelegate({
    required this.extent,
    required this.child,
  });

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _MobileGuideTimelineHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}

class _MobileGuideFilterStrip extends StatelessWidget {
  const _MobileGuideFilterStrip({
    required this.layout,
    required this.filters,
    required this.selectedCategoryId,
    required this.onSelectCategory,
  });

  final DeviceLayout layout;
  final List<_GuideCategoryFilter> filters;
  final String selectedCategoryId;
  final ValueChanged<String> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter.id == selectedCategoryId;

          return TvFocusable(
            autofocus: false,
            onPressed: () => onSelectCategory(filter.id),
            builder: (context, focused) {
              final active = focused || selected;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: active
                      ? _kGuideMobileAccentSoft
                      : colorScheme.surface.withValues(alpha: 0.42),
                  border: Border.all(
                    color: active
                        ? _kGuideMobileAccent
                        : Colors.white.withValues(alpha: 0.14),
                    width: active ? 1.4 : 1,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: _kGuideMobileAccentGlow,
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    filter.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: active
                          ? _kGuideMobileAccent
                          : colorScheme.onSurface.withValues(alpha: 0.86),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MobileGuideSummaryCard extends StatelessWidget {
  const _MobileGuideSummaryCard({
    required this.layout,
    required this.visibleCount,
    required this.totalFilters,
    required this.liveWithEpg,
    required this.liveWithReplay,
  });

  final DeviceLayout layout;
  final int visibleCount;
  final int totalFilters;
  final int liveWithEpg;
  final int liveWithReplay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface.withValues(alpha: 0.74),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MobileGuideStatChip(label: '$visibleCount canais'),
            _MobileGuideStatChip(label: '$totalFilters filtros'),
            if (liveWithEpg > 0)
              _MobileGuideStatChip(label: '$liveWithEpg com EPG'),
            if (liveWithReplay > 0)
              _MobileGuideStatChip(label: '$liveWithReplay com replay'),
          ],
        ),
      ),
    );
  }
}

class _MobileGuidePinnedTimeline extends StatelessWidget {
  const _MobileGuidePinnedTimeline({
    required this.layout,
    required this.windowLabel,
    required this.slots,
    required this.selectedSlotId,
    required this.onSelectSlot,
  });

  final DeviceLayout layout;
  final String windowLabel;
  final List<_MobileGuideTimeSlot> slots;
  final String selectedSlotId;
  final ValueChanged<String> onSelectSlot;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF060B15), Color(0xF10A1220), Color(0xEA08111D)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: layout.cardSpacing),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kGuideMobilePanelTop, _kGuideMobilePanelBottom],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MobileGuideStatChip(label: 'Guia $windowLabel', accent: true),
                SizedBox(height: layout.cardSpacing),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: colorScheme.surface.withValues(alpha: 0.26),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _MobileGuideTimeSlotStrip(
                      layout: layout,
                      slots: slots,
                      selectedSlotId: selectedSlotId,
                      onSelectSlot: onSelectSlot,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileGuideTimeSlotStrip extends StatelessWidget {
  const _MobileGuideTimeSlotStrip({
    required this.layout,
    required this.slots,
    required this.selectedSlotId,
    required this.onSelectSlot,
  });

  final DeviceLayout layout;
  final List<_MobileGuideTimeSlot> slots;
  final String selectedSlotId;
  final ValueChanged<String> onSelectSlot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final slot = slots[index];
          return _MobileGuideTimeSlotChip(
            slot: slot,
            selected: slot.id == selectedSlotId,
            onTap: () => onSelectSlot(slot.id),
          );
        },
      ),
    );
  }
}

class _MobileGuideTimeSlotChip extends StatelessWidget {
  const _MobileGuideTimeSlotChip({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final _MobileGuideTimeSlot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvFocusable(
      autofocus: false,
      onPressed: onTap,
      builder: (context, focused) {
        final active = selected || focused;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: slot.isNow ? 94 : 84,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            color: active
                ? Colors.white.withValues(alpha: 0.08)
                : colorScheme.surface.withValues(alpha: 0.28),
            border: Border.all(
              color: active
                  ? _kGuideMobileAccent
                  : Colors.white.withValues(alpha: 0.12),
              width: active ? 1.4 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _kGuideMobileAccentGlow,
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              slot.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: active
                    ? _kGuideMobileAccent
                    : colorScheme.onSurface.withValues(alpha: 0.86),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MobileGuideStatChip extends StatelessWidget {
  const _MobileGuideStatChip({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent
            ? _kGuideMobileAccentSoft
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        border: Border.all(
          color: accent
              ? _kGuideMobileAccent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: accent
              ? _kGuideMobileAccent
              : colorScheme.onSurface.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

class _MobileGuideChannelTile extends ConsumerWidget {
  const _MobileGuideChannelTile({
    required this.item,
    required this.visibleStreams,
    required this.channelIndex,
    required this.autofocus,
    required this.selectedTimeSlot,
  });

  final LiveStream item;
  final List<LiveStream> visibleStreams;
  final int channelIndex;
  final bool autofocus;
  final _MobileGuideTimeSlot selectedTimeSlot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final epgAsync = ref.watch(liveShortEpgProvider(item.id));
    final epgState = epgAsync.when(
      data: (entries) => _resolveGuideTileEpgState(
        entries,
        referenceTime: selectedTimeSlot.moment,
      ),
      loading: () => const _GuideTileEpgState(),
      error: (_, _) => const _GuideTileEpgState(),
    );
    final current = epgState.current;
    final next = epgState.next;
    final progress = current == null
        ? null
        : _guideTileProgress(current, now: selectedTimeSlot.moment);
    final selectedHeadline = current?.title ?? 'Sem programa neste horario';
    final selectedSupportingLine = current != null
        ? '${_formatGuideClock(current.startAt)} - ${_formatGuideClock(current.endAt)}'
        : next != null
        ? 'Proximo ${_formatGuideClock(next.startAt)} • ${next.title}'
        : item.hasArchive
        ? 'Canal com replay disponivel'
        : 'Canal disponivel agora';
    final selectedChipLabel = selectedTimeSlot.isNow
        ? 'AGORA'
        : selectedTimeSlot.label;

    return TvFocusable(
      autofocus: autofocus,
      onPressed: () => _openLivePlayer(context, visibleStreams, channelIndex),
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: focused
                  ? [
                      _kGuideMobileAccentSoft,
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.9,
                      ),
                    ]
                  : [
                      colorScheme.surface.withValues(alpha: 0.84),
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.68,
                      ),
                    ],
            ),
            border: Border.all(
              color: focused
                  ? _kGuideMobileAccent
                  : Colors.white.withValues(alpha: 0.1),
              width: focused ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: focused ? 0.22 : 0.14),
                blurRadius: focused ? 24 : 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: SizedBox(
                  width: 66,
                  child: BrandedArtwork(
                    imageUrl: item.iconUrl,
                    aspectRatio: 1,
                    fit: BoxFit.contain,
                    imagePadding: const EdgeInsets.all(9),
                    icon: Icons.live_tv_rounded,
                    placeholderLabel: 'Canal',
                    borderRadius: 18,
                    chrome: BrandedArtworkChrome.subtle,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MobileGuideMetaChip(
                          label: selectedChipLabel,
                          primary: true,
                        ),
                        _MobileGuideMetaChip(
                          label: item.hasArchive ? 'REPLAY' : 'LIVE',
                        ),
                        if (item.epgChannelId?.trim().isNotEmpty == true)
                          const _MobileGuideMetaChip(label: 'EPG'),
                        if (item.isAdult)
                          const _MobileGuideMetaChip(label: '18+'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.94),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedHeadline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedSupportingLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(
                            _kGuideMobileAction,
                          ),
                        ),
                      ),
                    ],
                    if (next != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Depois ${_formatGuideClock(next.startAt)} • ${next.title}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.68),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _kGuideMobileAction.withValues(alpha: 0.96),
                      _kGuideMobileAction.withValues(alpha: 0.76),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kGuideMobileAction.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileGuideMetaChip extends StatelessWidget {
  const _MobileGuideMetaChip({required this.label, this.primary = false});

  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: primary
            ? _kGuideMobileAccentSoft
            : colorScheme.secondary.withValues(alpha: 0.08),
        border: Border.all(
          color: primary
              ? _kGuideMobileAccent.withValues(alpha: 0.48)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 0.5,
          fontWeight: FontWeight.w700,
          color: primary
              ? _kGuideMobileAccent
              : colorScheme.onSurface.withValues(alpha: 0.76),
        ),
      ),
    );
  }
}

class _MobileGuideSkeleton extends StatelessWidget {
  const _MobileGuideSkeleton({
    required this.layout,
    required this.filters,
    required this.selectedCategoryId,
    required this.searchController,
    required this.windowLabel,
    required this.timeSlots,
    required this.selectedTimeSlotId,
    required this.onSelectTimeSlot,
  });

  final DeviceLayout layout;
  final List<_GuideCategoryFilter> filters;
  final String selectedCategoryId;
  final TextEditingController searchController;
  final String windowLabel;
  final List<_MobileGuideTimeSlot> timeSlots;
  final String selectedTimeSlotId;
  final ValueChanged<String> onSelectTimeSlot;

  @override
  Widget build(BuildContext context) {
    return _MobileGuideFrame(
      layout: layout,
      filters: filters,
      selectedCategoryId: selectedCategoryId,
      searchController: searchController,
      onSelectCategory: (_) {},
      windowLabel: windowLabel,
      timeSlots: timeSlots,
      selectedTimeSlotId: selectedTimeSlotId,
      onSelectTimeSlot: onSelectTimeSlot,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _MobileGuideStateCard extends StatelessWidget {
  const _MobileGuideStateCard({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface.withValues(alpha: 0.74),
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.secondary, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.76),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideCategoryFilter {
  const _GuideCategoryFilter({required this.id, required this.label});

  final String id;
  final String label;
}

class _MobileGuideTimeSlot {
  const _MobileGuideTimeSlot({
    required this.id,
    required this.label,
    required this.moment,
    this.isNow = false,
  });

  final String id;
  final String label;
  final DateTime moment;
  final bool isNow;
}

List<_GuideCategoryFilter> _buildGuideFilters(List<LiveCategory> categories) {
  final normalized =
      categories
          .where(
            (item) => item.id.trim().isNotEmpty && item.name.trim().isNotEmpty,
          )
          .map((item) => _GuideCategoryFilter(id: item.id, label: item.name))
          .toList()
        ..sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
        );

  return [const _GuideCategoryFilter(id: 'all', label: 'Todos'), ...normalized];
}

List<LiveStream> _filterGuideStreams({
  required List<LiveStream> streams,
  required String searchQuery,
}) {
  final normalizedQuery = searchQuery.trim().toLowerCase();
  final filtered = streams.where((item) {
    if (normalizedQuery.isEmpty) {
      return true;
    }
    return item.name.toLowerCase().contains(normalizedQuery);
  }).toList();

  filtered.sort((a, b) {
    final scoreA = _guideStreamScore(a);
    final scoreB = _guideStreamScore(b);
    if (scoreA != scoreB) {
      return scoreB.compareTo(scoreA);
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  return filtered;
}

int _guideStreamScore(LiveStream item) {
  var score = 0;
  if (item.epgChannelId?.trim().isNotEmpty == true) {
    score += 4;
  }
  if (item.hasArchive) {
    score += 2;
  }
  if (BrandedArtwork.normalizeArtworkUrl(item.iconUrl) != null) {
    score += 1;
  }
  if (!item.isAdult) {
    score += 1;
  }
  return score;
}

class _GuideTileEpgState {
  const _GuideTileEpgState({this.current, this.next});

  final LiveEpgEntry? current;
  final LiveEpgEntry? next;
}

_GuideTileEpgState _resolveGuideTileEpgState(
  List<LiveEpgEntry> entries, {
  required DateTime referenceTime,
}) {
  if (entries.isEmpty) {
    return const _GuideTileEpgState();
  }

  final sorted = [...entries]..sort((a, b) => a.startAt.compareTo(b.startAt));
  LiveEpgEntry? current;
  LiveEpgEntry? next;

  for (final entry in sorted) {
    if (entry.isOnAirAt(referenceTime)) {
      current = entry;
      continue;
    }
    if (entry.startAt.isAfter(referenceTime)) {
      next = entry;
      break;
    }
  }

  if (current != null && next == null) {
    final currentIndex = sorted.indexOf(current);
    if (currentIndex >= 0 && currentIndex + 1 < sorted.length) {
      next = sorted[currentIndex + 1];
    }
  }

  return _GuideTileEpgState(current: current, next: next);
}

List<_MobileGuideTimeSlot> _buildMobileGuideTimeSlots(DateTime now) {
  final slots = <_MobileGuideTimeSlot>[
    _MobileGuideTimeSlot(id: 'now', label: 'Agora', moment: now, isNow: true),
  ];
  var candidate = _resolveGuideWindowStart(now);

  while (slots.length < 4) {
    candidate = candidate.add(const Duration(minutes: 30));
    if (!candidate.isAfter(now)) {
      continue;
    }
    slots.add(
      _MobileGuideTimeSlot(
        id: 'slot-${candidate.millisecondsSinceEpoch}',
        label: _formatGuideClock(candidate),
        moment: candidate,
      ),
    );
  }

  return slots;
}

double? _guideTileProgress(LiveEpgEntry entry, {required DateTime now}) {
  final total = entry.endAt.difference(entry.startAt).inMilliseconds;
  if (total <= 0) {
    return null;
  }
  final elapsed = now.difference(entry.startAt).inMilliseconds;
  return (elapsed / total).clamp(0.0, 1.0);
}

DateTime _resolveGuideWindowStart(DateTime now) {
  final roundedMinute = now.minute < 30 ? 0 : 30;
  final anchor = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    roundedMinute,
  );
  return anchor.subtract(const Duration(minutes: 30));
}

String _formatGuideClock(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

void _openLivePlayer(
  BuildContext context,
  List<LiveStream> streams,
  int currentIndex,
) {
  context.push(
    PlayerScreen.routePath,
    extra: buildLivePlaybackContext(streams, currentIndex),
  );
}
