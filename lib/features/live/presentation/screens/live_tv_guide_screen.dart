import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/tv/tv_focusable.dart';
import '../../../../features/favorites/presentation/controllers/favorites_controller.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/presentation/screens/home_screen.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../../shared/widgets/branded_artwork.dart';
import '../../../../shared/widgets/tv_stage.dart';
import '../../domain/entities/live_category.dart';
import '../../domain/entities/live_epg_entry.dart';
import '../../domain/entities/live_stream.dart';
import '../providers/live_providers.dart';
import '../support/live_playback_context.dart';

const _favoritesFilterKey = 'guide_filter_favorites';
const _guideWindowMinutes = 180;
const _guideSlotMinutes = 30;
const _guideRowHeight = 60.0;
const _guideRowSpacing = 0.0;
const _guideTimeAxisHeight = 46.0;
const _kGuideTvProgress = Color(0xFFFF8A3D);
const _kGuideTvAccent = Color(0xFFAF7BFF);
const _kGuideTvAccentSoft = Color(0x665E35B1);
const _kGuideTvAccentAlt = Color(0xFF6C4CCF);
const _kGuideTvFocusSurface = Color(0xFF3A245F);
const _kGuideTvFocusText = Color(0xFFF8F2FF);

class LiveTvGuideScreen extends ConsumerStatefulWidget {
  const LiveTvGuideScreen({
    super.key,
    this.initialCategoryId,
    this.showBack = true,
  });

  final String? initialCategoryId;
  final bool showBack;

  @override
  ConsumerState<LiveTvGuideScreen> createState() => _LiveTvGuideScreenState();
}

class _LiveTvGuideScreenState extends ConsumerState<LiveTvGuideScreen> {
  late final DateTime _guideWindowStart;
  late final DateTime _guideWindowEnd;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _channelsVerticalController = ScrollController();
  final ScrollController _programVerticalController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'guide.search');
  final FocusNode _backActionFocusNode = FocusNode(debugLabel: 'guide.back');
  final Map<String, FocusNode> _filterFocusNodes = <String, FocusNode>{};
  final FocusNode _primaryGridFocusNode = FocusNode(
    debugLabel: 'guide.primary.grid',
  );
  String? _selectedFilterKey;
  String _searchQuery = '';
  _GuideFocusedProgram? _focusedProgram;
  bool _syncFromPrograms = false;
  bool _syncFromChannels = false;
  bool _pendingGridFocusRequest = false;
  double _programViewportWidth = 0;
  double _programViewportHeight = 0;
  int _lastSearchKeyboardRequestMs = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _guideWindowStart = _resolveGuideWindowStart(now);
    _guideWindowEnd = _guideWindowStart.add(
      const Duration(minutes: _guideWindowMinutes),
    );
    _searchController.addListener(_handleSearchQueryChanged);
    _channelsVerticalController.addListener(_syncProgramScroll);
    _programVerticalController.addListener(_syncChannelScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchQueryChanged);
    _channelsVerticalController.removeListener(_syncProgramScroll);
    _programVerticalController.removeListener(_syncChannelScroll);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _backActionFocusNode.dispose();
    _horizontalController.dispose();
    _channelsVerticalController.dispose();
    _programVerticalController.dispose();
    _primaryGridFocusNode.dispose();
    for (final node in _filterFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncProgramScroll() {
    if (_syncFromPrograms) {
      return;
    }
    if (!_channelsVerticalController.hasClients ||
        !_programVerticalController.hasClients) {
      return;
    }
    _syncFromChannels = true;
    final target = _channelsVerticalController.offset.clamp(
      0.0,
      _programVerticalController.position.maxScrollExtent,
    );
    if ((_programVerticalController.offset - target).abs() > 0.5) {
      _programVerticalController.jumpTo(target);
    }
    _syncFromChannels = false;
  }

  void _syncChannelScroll() {
    if (_syncFromChannels) {
      return;
    }
    if (!_channelsVerticalController.hasClients ||
        !_programVerticalController.hasClients) {
      return;
    }
    _syncFromPrograms = true;
    final target = _programVerticalController.offset.clamp(
      0.0,
      _channelsVerticalController.position.maxScrollExtent,
    );
    if ((_channelsVerticalController.offset - target).abs() > 0.5) {
      _channelsVerticalController.jumpTo(target);
    }
    _syncFromPrograms = false;
  }

  FocusNode _filterFocusNodeFor(String key) {
    return _filterFocusNodes.putIfAbsent(
      key,
      () => FocusNode(debugLabel: 'guide.filter.$key'),
    );
  }

  void _syncFilterFocusNodes(List<_GuideFilterOption> filters) {
    final validKeys = filters.map((item) => item.key).toSet();
    final staleKeys = _filterFocusNodes.keys
        .where((key) => !validKeys.contains(key))
        .toList();
    for (final key in staleKeys) {
      _filterFocusNodes.remove(key)?.dispose();
    }
  }

  void _handleSearchQueryChanged() {
    final nextQuery = _searchController.text.trim();
    if (_searchQuery == nextQuery) {
      return;
    }
    setState(() {
      _searchQuery = nextQuery;
    });
  }

  bool _isDownEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    return event.logicalKey == LogicalKeyboardKey.arrowDown;
  }

  bool _isUpEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    return event.logicalKey == LogicalKeyboardKey.arrowUp;
  }

  void _requestPrimaryGridFocus({bool allowQueue = true}) {
    if (_primaryGridFocusNode.context == null) {
      if (allowQueue) {
        _pendingGridFocusRequest = true;
      }
      return;
    }
    _pendingGridFocusRequest = false;
    FocusScope.of(context).requestFocus(_primaryGridFocusNode);
  }

  void _requestSearchKeyboard({bool force = false}) {
    if (!_searchFocusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    }
    final usesDirectionalNavigation =
        MediaQuery.navigationModeOf(context) == NavigationMode.directional;
    if (!usesDirectionalNavigation) {
      return;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force && (nowMs - _lastSearchKeyboardRequestMs) < 220) {
      return;
    }
    _lastSearchKeyboardRequestMs = nowMs;
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  void _focusBackAction() {
    if (!widget.showBack) {
      return;
    }
    if (_backActionFocusNode.context == null) {
      return;
    }
    FocusScope.of(context).requestFocus(_backActionFocusNode);
  }

  KeyEventResult _handleFilterKeyEvent(
    _GuideFilterOption selectedFilter,
    KeyEvent event,
  ) {
    if (!_isDownEvent(event)) {
      return KeyEventResult.ignored;
    }
    _requestPrimaryGridFocus();
    return KeyEventResult.handled;
  }

  KeyEventResult _handleGridTopRowKeyEvent(
    _GuideFilterOption selectedFilter,
    KeyEvent event,
  ) {
    if (!_isUpEvent(event)) {
      return KeyEventResult.ignored;
    }
    final filterNode = _filterFocusNodeFor(selectedFilter.key);
    FocusScope.of(context).requestFocus(filterNode);
    return KeyEventResult.handled;
  }

  void _onFilterSelected(_GuideFilterOption option) {
    if (_selectedFilterKey == option.key) {
      return;
    }
    setState(() {
      _selectedFilterKey = option.key;
      _focusedProgram = null;
      _pendingGridFocusRequest = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_horizontalController.hasClients) {
        _horizontalController.jumpTo(0);
      }
      if (_channelsVerticalController.hasClients) {
        _channelsVerticalController.jumpTo(0);
      }
      if (_programVerticalController.hasClients) {
        _programVerticalController.jumpTo(0);
      }
    });
  }

  void _onProgramFocused(_GuideProgramBlock block, int rowIndex) {
    final nextFocused = _GuideFocusedProgram.fromBlock(block);
    if (_focusedProgram?.key == nextFocused.key) {
      return;
    }
    setState(() {
      _focusedProgram = nextFocused;
    });
    _ensureProgramVisible(block, rowIndex);
  }

  void _ensureProgramVisible(_GuideProgramBlock block, int rowIndex) {
    const horizontalMargin = 42.0;
    if (_horizontalController.hasClients && _programViewportWidth > 1) {
      final left = block.startOffset;
      final right = block.startOffset + block.width;
      final current = _horizontalController.offset;
      final viewportRight = current + _programViewportWidth;
      double? targetOffset;
      if (left < current + horizontalMargin) {
        targetOffset = left - horizontalMargin;
      } else if (right > viewportRight - horizontalMargin) {
        targetOffset = right - _programViewportWidth + horizontalMargin;
      }
      if (targetOffset != null) {
        final clamped = targetOffset.clamp(
          0.0,
          _horizontalController.position.maxScrollExtent,
        );
        _horizontalController.animateTo(
          clamped,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        );
      }
    }

    if (_programVerticalController.hasClients && _programViewportHeight > 1) {
      final rowExtent = _guideRowHeight + _guideRowSpacing;
      final top = rowIndex * rowExtent;
      final bottom = top + _guideRowHeight;
      final current = _programVerticalController.offset;
      final viewportBottom = current + _programViewportHeight;
      double? targetOffset;
      if (top < current + _guideRowHeight) {
        targetOffset = top - _guideRowHeight;
      } else if (bottom > viewportBottom - _guideRowHeight) {
        targetOffset = bottom - _programViewportHeight + _guideRowHeight;
      }
      if (targetOffset != null) {
        final clamped = targetOffset.clamp(
          0.0,
          _programVerticalController.position.maxScrollExtent,
        );
        _programVerticalController.animateTo(
          clamped,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  void _openLivePlayer(List<LiveStream> streams, LiveStream stream) {
    final currentIndex = streams.indexWhere((item) => item.id == stream.id);
    if (currentIndex < 0) {
      return;
    }
    context.push(
      PlayerScreen.routePath,
      extra: buildLivePlaybackContext(streams, currentIndex),
    );
  }

  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(HomeScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);
    final categoriesAsync = ref.watch(liveCategoriesProvider);

    final body = categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const _GuideStateCard(
        title: 'Falha ao carregar filtros',
        message: 'Nao foi possivel obter as categorias live.',
        icon: Icons.error_outline_rounded,
      ),
      data: (categories) {
        final filters = _buildFilterOptions(categories);
        _syncFilterFocusNodes(filters);
        final selectedFilter = _resolveSelectedFilter(filters);
        final favoriteLiveIds =
            selectedFilter.kind == _GuideFilterKind.favorites
            ? ref
                  .watch(favoritesControllerProvider)
                  .where((item) => item.contentType == 'live')
                  .map((item) => item.contentId)
                  .toSet()
            : const <String>{};
        final requestCategoryId =
            selectedFilter.kind == _GuideFilterKind.category
            ? selectedFilter.categoryId
            : null;
        final streamsAsync = ref.watch(liveStreamsProvider(requestCategoryId));

        return streamsAsync.when(
          loading: () => _LiveTvGuideShell(
            layout: layout,
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            onRequestSearchKeyboard: _requestSearchKeyboard,
            onNavigateSearchUp: _focusBackAction,
            onClearSearch: () => _searchController.clear(),
            guideWindowStart: _guideWindowStart,
            guideWindowEnd: _guideWindowEnd,
            focusedProgram: _resolvePanelProgram(const <LiveStream>[]),
            selectedFilter: selectedFilter,
            streamsCount: 0,
            filters: filters,
            onFilterSelected: _onFilterSelected,
            filterFocusNodeForKey: _filterFocusNodeFor,
            onFilterKeyEvent: _handleFilterKeyEvent,
            onPlayFocused: null,
            body: const _GuideStateCard(
              title: 'Carregando canais',
              message: 'Montando a grade ao vivo.',
              icon: Icons.live_tv_rounded,
            ),
          ),
          error: (_, _) => _LiveTvGuideShell(
            layout: layout,
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            onRequestSearchKeyboard: _requestSearchKeyboard,
            onNavigateSearchUp: _focusBackAction,
            onClearSearch: () => _searchController.clear(),
            guideWindowStart: _guideWindowStart,
            guideWindowEnd: _guideWindowEnd,
            focusedProgram: _resolvePanelProgram(const <LiveStream>[]),
            selectedFilter: selectedFilter,
            streamsCount: 0,
            filters: filters,
            onFilterSelected: _onFilterSelected,
            filterFocusNodeForKey: _filterFocusNodeFor,
            onFilterKeyEvent: _handleFilterKeyEvent,
            onPlayFocused: null,
            body: const _GuideStateCard(
              title: 'Falha ao carregar canais',
              message: 'Nao foi possivel abrir a grade para este filtro.',
              icon: Icons.signal_wifi_connected_no_internet_4_rounded,
            ),
          ),
          data: (items) {
            final query = _searchQuery.toLowerCase();
            final visibleStreams =
                selectedFilter.kind == _GuideFilterKind.favorites
                ? items
                      .where((item) => favoriteLiveIds.contains(item.id))
                      .toList()
                : items.toList();
            if (query.isNotEmpty) {
              visibleStreams.retainWhere(
                (item) => item.name.toLowerCase().contains(query),
              );
            }
            visibleStreams.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

            final panelProgram = _resolvePanelProgram(visibleStreams);
            final activeStreamId = panelProgram?.stream.id;
            if (_pendingGridFocusRequest && visibleStreams.isNotEmpty) {
              _pendingGridFocusRequest = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                _requestPrimaryGridFocus(allowQueue: false);
              });
            }

            final guideBody = visibleStreams.isEmpty
                ? _GuideStateCard(
                    title: 'Nenhum canal neste filtro',
                    message: query.isNotEmpty
                        ? 'Nenhum canal corresponde a "$_searchQuery" em ${selectedFilter.label}.'
                        : selectedFilter.kind == _GuideFilterKind.favorites
                        ? 'Marque canais ao vivo como favoritos para usar este filtro.'
                        : 'Nao foram encontrados canais para ${selectedFilter.label}.',
                    icon: Icons.filter_alt_off_rounded,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final colorScheme = Theme.of(context).colorScheme;
                      final maxWidth = constraints.maxWidth.isFinite
                          ? constraints.maxWidth
                          : layout.width;
                      final channelColumnWidth =
                          ((layout.isTvCompact
                                  ? maxWidth * 0.198
                                  : maxWidth * 0.192))
                              .clamp(
                                layout.isTvCompact ? 184.0 : 194.0,
                                layout.isTvCompact ? 232.0 : 242.0,
                              );
                      const interColumnGap = 0.0;
                      const rowTimeBandWidth = 0.0;
                      final timelineViewportWidth = math.max(
                        360.0,
                        maxWidth - channelColumnWidth - interColumnGap,
                      );
                      final minimumPixelsPerMinute = layout.isTvCompact
                          ? 4.8
                          : 5.3;
                      final programTrackWidth = math.max(
                        timelineViewportWidth - rowTimeBandWidth,
                        _guideWindowMinutes * minimumPixelsPerMinute,
                      );
                      final timelineWidth =
                          programTrackWidth + rowTimeBandWidth;
                      final pixelsPerMinute =
                          programTrackWidth / _guideWindowMinutes;
                      final guideHeight = constraints.maxHeight.isFinite
                          ? constraints.maxHeight
                          : (layout.isTvCompact ? 568.0 : 644.0);
                      final contentHeight = math.max(280.0, guideHeight);
                      final currentTimeOffset = _resolveCurrentTimeOffset(
                        now: DateTime.now(),
                        windowStart: _guideWindowStart,
                        windowEnd: _guideWindowEnd,
                        pixelsPerMinute: pixelsPerMinute,
                      );
                      _programViewportWidth = timelineViewportWidth;
                      _programViewportHeight = math.max(
                        120,
                        contentHeight - _guideTimeAxisHeight,
                      );

                      return SizedBox(
                        height: guideHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.surface.withValues(alpha: 0.86),
                                  colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.72),
                                ],
                              ),
                              border: Border.all(
                                color: colorScheme.outline.withValues(
                                  alpha: 0.32,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: channelColumnWidth,
                                  child: Column(
                                    children: [
                                      _GuideChannelHeader(
                                        title: 'Canais',
                                        subtitle:
                                            '${visibleStreams.length} linhas',
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          controller:
                                              _channelsVerticalController,
                                          itemCount: visibleStreams.length,
                                          itemBuilder: (context, index) {
                                            return _GuideChannelCell(
                                              stream: visibleStreams[index],
                                              isActive:
                                                  visibleStreams[index].id ==
                                                  activeStreamId,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: interColumnGap),
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: _horizontalController,
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: timelineWidth,
                                      height: contentHeight,
                                      child: Stack(
                                        children: [
                                          Column(
                                            children: [
                                              _GuideTimeAxis(
                                                start: _guideWindowStart,
                                                end: _guideWindowEnd,
                                                pixelsPerMinute:
                                                    pixelsPerMinute,
                                                leadingWidth: rowTimeBandWidth,
                                              ),
                                              Expanded(
                                                child: Stack(
                                                  children: [
                                                    Positioned.fill(
                                                      child: _GuideTimelineGrid(
                                                        start:
                                                            _guideWindowStart,
                                                        pixelsPerMinute:
                                                            pixelsPerMinute,
                                                        windowMinutes:
                                                            _guideWindowMinutes,
                                                        leadingWidth:
                                                            rowTimeBandWidth,
                                                        rowExtent:
                                                            _guideRowHeight +
                                                            _guideRowSpacing,
                                                      ),
                                                    ),
                                                    ListView.builder(
                                                      controller:
                                                          _programVerticalController,
                                                      itemCount:
                                                          visibleStreams.length,
                                                      itemBuilder: (context, index) {
                                                        final stream =
                                                            visibleStreams[index];
                                                        return _GuideProgramRow(
                                                          stream: stream,
                                                          rowIndex: index,
                                                          windowStart:
                                                              _guideWindowStart,
                                                          windowEnd:
                                                              _guideWindowEnd,
                                                          pixelsPerMinute:
                                                              pixelsPerMinute,
                                                          leadingWidth:
                                                              rowTimeBandWidth,
                                                          isTopRow: index == 0,
                                                          selectedFilter:
                                                              selectedFilter,
                                                          primaryGridFocusNode:
                                                              _primaryGridFocusNode,
                                                          onTopRowNavigateUp:
                                                              _handleGridTopRowKeyEvent,
                                                          onProgramFocused:
                                                              _onProgramFocused,
                                                          onOpenChannel:
                                                              (
                                                                stream,
                                                              ) => _openLivePlayer(
                                                                visibleStreams,
                                                                stream,
                                                              ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (currentTimeOffset != null)
                                            Positioned(
                                              left: currentTimeOffset,
                                              top: 0,
                                              child: const _GuideNowIndicator(
                                                axisHeight:
                                                    _guideTimeAxisHeight,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );

            return _LiveTvGuideShell(
              layout: layout,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              onRequestSearchKeyboard: _requestSearchKeyboard,
              onNavigateSearchUp: _focusBackAction,
              onClearSearch: () => _searchController.clear(),
              guideWindowStart: _guideWindowStart,
              guideWindowEnd: _guideWindowEnd,
              focusedProgram: panelProgram,
              selectedFilter: selectedFilter,
              streamsCount: visibleStreams.length,
              filters: filters,
              onFilterSelected: _onFilterSelected,
              filterFocusNodeForKey: _filterFocusNodeFor,
              onFilterKeyEvent: _handleFilterKeyEvent,
              onPlayFocused: panelProgram == null
                  ? null
                  : () => _openLivePlayer(visibleStreams, panelProgram.stream),
              body: guideBody,
            );
          },
        );
      },
    );

    if (!layout.isTv) {
      return AppScaffold(
        title: 'TV ao vivo',
        subtitle: null,
        showBack: widget.showBack,
        showBrand: false,
        decoratedHeader: false,
        onBack: _handleBackNavigation,
        child: body,
      );
    }

    return TvStageScaffold(
      backdrop: const TvStageBackdrop(
        gradientColors: [
          Color(0xFF020305),
          Color(0xFF060A12),
          Color(0xFF020305),
        ],
        topGlowColor: Color(0x2E355E9A),
        bottomGlowColor: Color(0x223A2211),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuideTopBar(
            showBack: widget.showBack,
            onBack: _handleBackNavigation,
            backFocusNode: _backActionFocusNode,
          ),
          SizedBox(height: layout.isTvCompact ? 8 : 10),
          Expanded(child: body),
        ],
      ),
    );
  }

  List<_GuideFilterOption> _buildFilterOptions(List<LiveCategory> categories) {
    final dedup = <String>{};
    final categoryFilters = <_GuideFilterOption>[];
    for (final category in categories) {
      final id = category.id.trim();
      final name = category.name.trim();
      if (id.isEmpty || name.isEmpty) {
        continue;
      }
      if (dedup.contains(id)) {
        continue;
      }
      dedup.add(id);
      categoryFilters.add(
        _GuideFilterOption(
          key: 'cat:$id',
          label: name,
          kind: _GuideFilterKind.category,
          categoryId: id,
        ),
      );
    }

    categoryFilters.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );

    return [
      const _GuideFilterOption(
        key: 'all',
        label: 'Todos',
        kind: _GuideFilterKind.all,
      ),
      const _GuideFilterOption(
        key: _favoritesFilterKey,
        label: 'Favoritos',
        kind: _GuideFilterKind.favorites,
      ),
      ...categoryFilters,
    ];
  }

  _GuideFilterOption _resolveSelectedFilter(List<_GuideFilterOption> options) {
    final selected = _selectedFilterKey;
    if (selected != null) {
      return options.firstWhere(
        (option) => option.key == selected,
        orElse: () => options.first,
      );
    }

    final initialCategoryId = widget.initialCategoryId?.trim();
    if (initialCategoryId != null && initialCategoryId.isNotEmpty) {
      final targetKey = 'cat:$initialCategoryId';
      return options.firstWhere(
        (option) => option.key == targetKey,
        orElse: () => options.first,
      );
    }
    return options.first;
  }

  _GuideFocusedProgram? _resolvePanelProgram(List<LiveStream> visibleStreams) {
    if (visibleStreams.isEmpty) {
      return null;
    }
    final focused = _focusedProgram;
    if (focused != null &&
        visibleStreams.any((stream) => stream.id == focused.stream.id)) {
      return focused;
    }

    final fallbackStream = visibleStreams.first;
    return _GuideFocusedProgram(
      key: 'fallback:${fallbackStream.id}:${_selectedFilterKey ?? 'all'}',
      stream: fallbackStream,
      title: fallbackStream.name,
      description:
          'Canal em destaque para este filtro. Use o D-pad para focar um programa na grade.',
      startAt: _guideWindowStart,
      endAt: _guideWindowEnd,
    );
  }
}

class _LiveTvGuideShell extends StatelessWidget {
  const _LiveTvGuideShell({
    required this.layout,
    required this.searchController,
    required this.searchFocusNode,
    required this.onRequestSearchKeyboard,
    required this.onNavigateSearchUp,
    required this.onClearSearch,
    required this.guideWindowStart,
    required this.guideWindowEnd,
    required this.focusedProgram,
    required this.selectedFilter,
    required this.streamsCount,
    required this.filters,
    required this.onFilterSelected,
    required this.filterFocusNodeForKey,
    required this.onFilterKeyEvent,
    required this.onPlayFocused,
    required this.body,
  });

  final DeviceLayout layout;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final void Function({bool force}) onRequestSearchKeyboard;
  final VoidCallback onNavigateSearchUp;
  final VoidCallback onClearSearch;
  final DateTime guideWindowStart;
  final DateTime guideWindowEnd;
  final _GuideFocusedProgram? focusedProgram;
  final _GuideFilterOption selectedFilter;
  final int streamsCount;
  final List<_GuideFilterOption> filters;
  final ValueChanged<_GuideFilterOption> onFilterSelected;
  final FocusNode Function(String key) filterFocusNodeForKey;
  final KeyEventResult Function(
    _GuideFilterOption selectedFilter,
    KeyEvent event,
  )
  onFilterKeyEvent;
  final VoidCallback? onPlayFocused;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final onAirProgress = focusedProgram == null
        ? null
        : _currentProgress(
            now: now,
            start: focusedProgram!.startAt,
            end: focusedProgram!.endAt,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 32,
              child: _GuideSearchPanel(
                layout: layout,
                controller: searchController,
                focusNode: searchFocusNode,
                onRequestKeyboard: onRequestSearchKeyboard,
                onNavigateUp: onNavigateSearchUp,
                onClear: onClearSearch,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 68,
              child: TvStagePanel(
                radius: 13,
                padding: EdgeInsets.symmetric(
                  horizontal: layout.isTvCompact ? 10 : 12,
                  vertical: layout.isTvCompact ? 7 : 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: _kGuideTvAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Guia ao vivo • ${_formatClock(guideWindowStart)}-${_formatClock(guideWindowEnd)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    _GuideChip(
                      label: selectedFilter.label.toUpperCase(),
                      color: _kGuideTvAccent,
                    ),
                    const SizedBox(width: 6),
                    _GuideChip(
                      label: '$streamsCount canais',
                      color: _kGuideTvAccentAlt,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: layout.isTvCompact ? 8 : 10),
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    final isSelected = filter.key == selectedFilter.key;
                    return TvFocusable(
                      autofocus: filter.key == selectedFilter.key,
                      focusNode: filterFocusNodeForKey(filter.key),
                      onPressed: () => onFilterSelected(filter),
                      onKeyEvent: (node, event) =>
                          onFilterKeyEvent(selectedFilter, event),
                      builder: (context, focused) {
                        final background = focused
                            ? _kGuideTvAccent.withValues(alpha: 0.22)
                            : isSelected
                            ? _kGuideTvAccentAlt.withValues(alpha: 0.18)
                            : colorScheme.surface.withValues(alpha: 0.52);
                        final borderColor = focused
                            ? _kGuideTvAccent
                            : isSelected
                            ? _kGuideTvAccentAlt
                            : colorScheme.outline.withValues(alpha: 0.4);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: background,
                            border: Border.all(
                              color: borderColor,
                              width: focused ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            filter.label,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: focused
                                      ? _kGuideTvAccent
                                      : isSelected
                                      ? _kGuideTvAccentAlt
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.88,
                                        ),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: layout.isTvCompact ? 6 : 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panelWidth = (constraints.maxWidth * 0.092).clamp(
                layout.isTvCompact ? 112.0 : 120.0,
                layout.isTvCompact ? 136.0 : 148.0,
              );

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: body),
                  SizedBox(width: layout.isTvCompact ? 3 : 5),
                  SizedBox(
                    width: panelWidth,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _GuideFocusedSidePanel(
                        focusedProgram: focusedProgram,
                        onAirProgress: onAirProgress,
                        onPlayFocused: onPlayFocused,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GuideTopBar extends StatelessWidget {
  const _GuideTopBar({
    required this.showBack,
    required this.onBack,
    this.backFocusNode,
  });

  final bool showBack;
  final VoidCallback onBack;
  final FocusNode? backFocusNode;

  @override
  Widget build(BuildContext context) {
    return TvStagePanel(
      radius: 13,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      child: Row(
        children: [
          if (showBack) ...[
            _GuideTopAction(
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
              focusNode: backFocusNode,
            ),
            const SizedBox(width: 8),
          ],
          const BrandWordmark(height: 30, compact: true, showTagline: false),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'TV ao vivo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const TvStageClock(),
        ],
      ),
    );
  }
}

class _GuideTopAction extends StatelessWidget {
  const _GuideTopAction({
    required this.icon,
    required this.onPressed,
    this.focusNode,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 50,
      child: TvFocusable(
        focusNode: focusNode,
        onPressed: onPressed,
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: focused
                  ? _kGuideTvFocusSurface
                  : colorScheme.surface.withValues(alpha: 0.6),
              border: Border.all(
                color: focused
                    ? _kGuideTvAccent
                    : colorScheme.outline.withValues(alpha: 0.36),
                width: focused ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: focused ? _kGuideTvFocusText : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GuideSearchPanel extends StatelessWidget {
  const _GuideSearchPanel({
    required this.layout,
    required this.controller,
    required this.focusNode,
    required this.onRequestKeyboard,
    required this.onNavigateUp,
    required this.onClear,
  });

  final DeviceLayout layout;
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function({bool force}) onRequestKeyboard;
  final VoidCallback onNavigateUp;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final hasQuery = controller.text.trim().isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: layout.isTvCompact ? 56 : 58,
          padding: EdgeInsets.symmetric(
            horizontal: layout.isTvCompact ? 16 : 18,
            vertical: layout.isTvCompact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: focused
                  ? [
                      colorScheme.surface.withValues(alpha: 0.88),
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.78,
                      ),
                    ]
                  : [
                      colorScheme.surface.withValues(alpha: 0.72),
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.58,
                      ),
                    ],
            ),
            border: Border.all(
              color: focused
                  ? _kGuideTvAccent
                  : Colors.white.withValues(alpha: 0.2),
              width: focused ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.72),
                size: 22,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: CallbackShortcuts(
                  bindings: <ShortcutActivator, VoidCallback>{
                    const SingleActivator(LogicalKeyboardKey.arrowUp): () {
                      onNavigateUp();
                    },
                    const SingleActivator(LogicalKeyboardKey.arrowDown): () {
                      FocusScope.of(context).nextFocus();
                    },
                    const SingleActivator(LogicalKeyboardKey.select): () {
                      onRequestKeyboard();
                    },
                    const SingleActivator(LogicalKeyboardKey.enter): () {
                      onRequestKeyboard();
                    },
                    const SingleActivator(LogicalKeyboardKey.space): () {
                      onRequestKeyboard();
                    },
                    const SingleActivator(LogicalKeyboardKey.gameButtonA): () {
                      onRequestKeyboard();
                    },
                  },
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0,
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onTap: () => onRequestKeyboard(),
                            showCursor: false,
                            enableSuggestions: false,
                            autocorrect: false,
                            textInputAction: TextInputAction.search,
                            style: const TextStyle(
                              color: Colors.transparent,
                              height: 1,
                            ),
                            cursorColor: Colors.transparent,
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        hasQuery ? controller.text : 'Buscar canal...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(
                            alpha: hasQuery ? 0.92 : 0.72,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasQuery)
                IconButton(
                  onPressed: () {
                    onClear();
                    onRequestKeyboard(force: true);
                  },
                  splashRadius: 18,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.66),
                  ),
                  tooltip: 'Limpar busca',
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GuideFocusedSidePanel extends StatelessWidget {
  const _GuideFocusedSidePanel({
    required this.focusedProgram,
    required this.onAirProgress,
    required this.onPlayFocused,
  });

  final _GuideFocusedProgram? focusedProgram;
  final double? onAirProgress;
  final VoidCallback? onPlayFocused;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvStagePanel(
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
      radius: 11,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < 560 || constraints.maxWidth < 164;
          final showAction =
              onPlayFocused != null && !compact && constraints.maxWidth >= 188;
          final content = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.22,
                  ),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  'EM FOCO',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    letterSpacing: 0.48,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              BrandedArtwork(
                imageUrl: focusedProgram?.stream.iconUrl,
                aspectRatio: compact ? 16 / 12.2 : 16 / 11.6,
                fit: BoxFit.contain,
                imagePadding: const EdgeInsets.all(5),
                icon: Icons.live_tv_rounded,
                placeholderLabel: 'Canal ao vivo',
                borderRadius: 8,
              ),
              const SizedBox(height: 6),
              Text(
                focusedProgram?.stream.name ?? 'Selecione um canal',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: colorScheme.onSurface.withValues(alpha: 0.76),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                focusedProgram?.title ?? 'Use o D-pad para navegar na grade.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 13.5 : 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.92),
                  height: 1.04,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                focusedProgram == null
                    ? 'Selecione um programa para ver detalhes.'
                    : _formatTimeRange(
                        focusedProgram!.startAt,
                        focusedProgram!.endAt,
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10.5,
                  color: colorScheme.onSurface.withValues(alpha: 0.66),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onAirProgress != null) ...[
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: onAirProgress,
                    minHeight: 2.5,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    valueColor: const AlwaysStoppedAnimation(_kGuideTvProgress),
                  ),
                ),
              ],
              if (showAction) ...[
                const SizedBox(height: 12),
                TvFocusable(
                  onPressed: onPlayFocused,
                  builder: (context, focused) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: focused
                            ? _kGuideTvFocusSurface
                            : colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.52,
                              ),
                        border: Border.all(
                          color: focused
                              ? _kGuideTvAccent
                              : colorScheme.outline.withValues(alpha: 0.36),
                          width: focused ? 2.0 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 20,
                            color: focused
                                ? _kGuideTvFocusText
                                : _kGuideTvAccent,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Assistir agora',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: focused
                                        ? _kGuideTvFocusText
                                        : colorScheme.onSurface,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          );

          if (compact) {
            return SingleChildScrollView(child: content);
          }

          return content;
        },
      ),
    );
  }
}

class _GuideProgramRow extends ConsumerWidget {
  const _GuideProgramRow({
    required this.stream,
    required this.rowIndex,
    required this.windowStart,
    required this.windowEnd,
    required this.pixelsPerMinute,
    required this.leadingWidth,
    required this.isTopRow,
    required this.selectedFilter,
    required this.primaryGridFocusNode,
    required this.onTopRowNavigateUp,
    required this.onProgramFocused,
    required this.onOpenChannel,
  });

  final LiveStream stream;
  final int rowIndex;
  final DateTime windowStart;
  final DateTime windowEnd;
  final double pixelsPerMinute;
  final double leadingWidth;
  final bool isTopRow;
  final _GuideFilterOption selectedFilter;
  final FocusNode primaryGridFocusNode;
  final KeyEventResult Function(
    _GuideFilterOption selectedFilter,
    KeyEvent event,
  )
  onTopRowNavigateUp;
  final void Function(_GuideProgramBlock block, int rowIndex) onProgramFocused;
  final ValueChanged<LiveStream> onOpenChannel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasEpgSignal = stream.epgChannelId?.trim().isNotEmpty == true;
    final epgAsync = hasEpgSignal
        ? ref.watch(liveGuideEpgProvider(stream.id))
        : const AsyncValue<List<LiveEpgEntry>>.data(<LiveEpgEntry>[]);

    final blocks = epgAsync.when(
      data: (entries) => _buildGuideBlocks(
        stream: stream,
        entries: entries,
        windowStart: windowStart,
        windowEnd: windowEnd,
        pixelsPerMinute: pixelsPerMinute,
        noEpgLabel: hasEpgSignal ? 'Grade indisponivel' : 'Sem grade',
      ),
      loading: () => _buildGuideBlocks(
        stream: stream,
        entries: const <LiveEpgEntry>[],
        windowStart: windowStart,
        windowEnd: windowEnd,
        pixelsPerMinute: pixelsPerMinute,
        noEpgLabel: 'Carregando grade',
      ),
      error: (_, _) => _buildGuideBlocks(
        stream: stream,
        entries: const <LiveEpgEntry>[],
        windowStart: windowStart,
        windowEnd: windowEnd,
        pixelsPerMinute: pixelsPerMinute,
        noEpgLabel: 'Grade indisponivel',
      ),
    );

    final now = DateTime.now();
    var preferredIndex = 0;
    if (isTopRow) {
      for (var index = 0; index < blocks.length; index++) {
        if (blocks[index].contains(now) && !blocks[index].isGap) {
          preferredIndex = index;
          break;
        }
      }
    }

    final leadingBlock = blocks.firstWhere(
      (block) => !block.isGap,
      orElse: () => blocks.first,
    );
    final timelineTrackWidth = _guideWindowMinutes * pixelsPerMinute;
    final rowBackground = rowIndex.isEven
        ? colorScheme.surface.withValues(alpha: 0.05)
        : colorScheme.surface.withValues(alpha: 0.025);

    return SizedBox(
      height: _guideRowHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(color: rowBackground),
        child: Row(
          children: [
            if (leadingWidth > 0)
              _GuideRowTimeCell(
                width: leadingWidth,
                start: leadingBlock.startAt,
                end: leadingBlock.endAt,
              ),
            SizedBox(
              width: timelineTrackWidth,
              child: Row(
                children: [
                  for (var index = 0; index < blocks.length; index++)
                    _GuideProgramCell(
                      block: blocks[index],
                      focusNode: isTopRow && index == preferredIndex
                          ? primaryGridFocusNode
                          : null,
                      handleArrowUpToFilter: isTopRow,
                      selectedFilter: selectedFilter,
                      onTopRowNavigateUp: onTopRowNavigateUp,
                      onFocused: (block) => onProgramFocused(block, rowIndex),
                      onPressed: () => onOpenChannel(stream),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideProgramCell extends StatelessWidget {
  const _GuideProgramCell({
    required this.block,
    this.focusNode,
    required this.handleArrowUpToFilter,
    required this.selectedFilter,
    required this.onTopRowNavigateUp,
    required this.onFocused,
    required this.onPressed,
  });

  final _GuideProgramBlock block;
  final FocusNode? focusNode;
  final bool handleArrowUpToFilter;
  final _GuideFilterOption selectedFilter;
  final KeyEventResult Function(
    _GuideFilterOption selectedFilter,
    KeyEvent event,
  )
  onTopRowNavigateUp;
  final ValueChanged<_GuideProgramBlock> onFocused;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isOnAir = block.contains(now);
    final isScheduleGap = block.kind == _GuideProgramBlockKind.scheduleGap;
    final isNoGuide = block.kind == _GuideProgramBlockKind.noGuide;
    final isFirstBlock = block.startOffset <= 0.5;
    final onAirProgress = isOnAir
        ? _currentProgress(now: now, start: block.startAt, end: block.endAt)
        : null;

    return SizedBox(
      width: block.width,
      child: TvFocusable(
        focusNode: focusNode,
        onPressed: onPressed,
        onKeyEvent: (node, event) {
          if (!handleArrowUpToFilter) {
            return KeyEventResult.ignored;
          }
          return onTopRowNavigateUp(selectedFilter, event);
        },
        onFocusChanged: (focused) {
          if (focused) {
            onFocused(block);
          }
        },
        builder: (context, focused) {
          final dividerColor = colorScheme.outline.withValues(
            alpha: block.isGap ? 0.1 : 0.18,
          );
          final backgroundGradient = focused
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _kGuideTvAccentSoft,
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.76),
                  ],
                )
              : isNoGuide
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
                    colorScheme.surface.withValues(alpha: 0.12),
                  ],
                )
              : isScheduleGap
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface.withValues(alpha: 0.01),
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
                  ],
                )
              : isOnAir
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _kGuideTvAccentAlt.withValues(alpha: 0.2),
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.46),
                  ],
                );
          final titleColor = block.isGap
              ? colorScheme.onSurface.withValues(alpha: isNoGuide ? 0.74 : 0.6)
              : colorScheme.onSurface.withValues(alpha: focused ? 0.98 : 0.92);
          final metaColor = colorScheme.onSurface.withValues(
            alpha: block.isGap ? 0.52 : 0.64,
          );
          final focusBorder = _kGuideTvAccent;
          final gapTitle = isNoGuide ? 'Grade indisponivel' : 'Sem programacao';
          final showGapLabel = block.width >= 94;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              gradient: backgroundGradient,
              border: Border(
                left: isFirstBlock
                    ? BorderSide(color: dividerColor, width: 1)
                    : BorderSide.none,
                right: BorderSide(color: dividerColor, width: 1),
                bottom: BorderSide(color: dividerColor, width: 1),
              ),
            ),
            child: Stack(
              children: [
                if (block.isGap)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GuideGapPatternPainter(
                        lineColor: colorScheme.outline.withValues(
                          alpha: isNoGuide ? 0.13 : 0.08,
                        ),
                        spacing: isNoGuide ? 16 : 22,
                      ),
                    ),
                  ),
                if (!block.isGap && isOnAir)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: Container(
                      height: 2.5,
                      color: _kGuideTvProgress.withValues(
                        alpha: focused ? 0.96 : 0.78,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(9, 7, 8, 7),
                  child: block.isGap
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: showGapLabel
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      gapTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: titleColor,
                                            fontSize: block.width < 156
                                                ? 12.1
                                                : 12.8,
                                          ),
                                    ),
                                    if (block.width >= 168) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTimeRange(
                                          block.startAt,
                                          block.endAt,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontSize: 10.4,
                                              fontWeight: FontWeight.w700,
                                              color: metaColor,
                                            ),
                                      ),
                                    ],
                                  ],
                                )
                              : const SizedBox.shrink(),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              block.title,
                              maxLines: block.width < 220 ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: focused
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    color: titleColor,
                                    fontSize: block.width < 190 ? 13.0 : 13.8,
                                    height: 1.02,
                                  ),
                            ),
                            const Spacer(),
                            if (block.width >= 146)
                              Text(
                                _formatTimeRange(block.startAt, block.endAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontSize: 10.4,
                                      color: metaColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                          ],
                        ),
                ),
                if (onAirProgress != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: onAirProgress,
                        child: Container(
                          height: 2.5,
                          color: _kGuideTvProgress.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ),
                if (focused)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: focusBorder, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _kGuideTvAccent.withValues(alpha: 0.18),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GuideTimeAxis extends StatelessWidget {
  const _GuideTimeAxis({
    required this.start,
    required this.end,
    required this.pixelsPerMinute,
    required this.leadingWidth,
  });

  final DateTime start;
  final DateTime end;
  final double pixelsPerMinute;
  final double leadingWidth;

  @override
  Widget build(BuildContext context) {
    final segments = <DateTime>[];
    var cursor = start;
    while (cursor.isBefore(end)) {
      segments.add(cursor);
      cursor = cursor.add(const Duration(minutes: _guideSlotMinutes));
    }
    final slotWidth = _guideSlotMinutes * pixelsPerMinute;

    return SizedBox(
      height: _guideTimeAxisHeight,
      child: Row(
        children: [
          if (leadingWidth > 0) _GuideTimeAxisLeadingCell(width: leadingWidth),
          for (var index = 0; index < segments.length; index++)
            _GuideTimeAxisCell(
              time: segments[index],
              width: slotWidth,
              isHourTick: segments[index].minute == 0,
            ),
        ],
      ),
    );
  }
}

class _GuideTimeAxisLeadingCell extends StatelessWidget {
  const _GuideTimeAxisLeadingCell({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(8, 5, 4, 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.28),
            width: 1,
          ),
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'HOJE',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _GuideTimeAxisCell extends StatelessWidget {
  const _GuideTimeAxisCell({
    required this.time,
    required this.width,
    required this.isHourTick,
  });

  final DateTime time;
  final double width;
  final bool isHourTick;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isHourTick
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
        : colorScheme.surface.withValues(alpha: 0.08);
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withValues(
              alpha: isHourTick ? 0.26 : 0.1,
            ),
            width: 1,
          ),
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatClock(time),
            maxLines: 1,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface.withValues(
                alpha: isHourTick ? 0.92 : 0.7,
              ),
              fontWeight: isHourTick ? FontWeight.w800 : FontWeight.w700,
              fontSize: isHourTick ? 13.5 : 12.5,
              height: 1,
              letterSpacing: isHourTick ? 0.18 : 0.04,
            ),
          ),
          if (isHourTick) ...[
            const SizedBox(height: 2),
            Container(
              width: 18,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: _kGuideTvAccentAlt.withValues(alpha: 0.64),
              ),
            ),
          ] else ...[
            const SizedBox(height: 2),
            Text(
              ':30',
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.44),
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: 0.24,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuideTimelineGrid extends StatelessWidget {
  const _GuideTimelineGrid({
    required this.start,
    required this.pixelsPerMinute,
    required this.windowMinutes,
    required this.leadingWidth,
    required this.rowExtent,
  });

  final DateTime start;
  final double pixelsPerMinute;
  final int windowMinutes;
  final double leadingWidth;
  final double rowExtent;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GuideTimelineGridPainter(
          start: start,
          slotWidth: _guideSlotMinutes * pixelsPerMinute,
          segmentCount: windowMinutes ~/ _guideSlotMinutes,
          leadingWidth: leadingWidth,
          rowExtent: rowExtent,
          majorColor: Theme.of(
            context,
          ).colorScheme.outline.withValues(alpha: 0.24),
          minorColor: Theme.of(
            context,
          ).colorScheme.outline.withValues(alpha: 0.08),
          rowColor: Theme.of(
            context,
          ).colorScheme.outline.withValues(alpha: 0.12),
          hourBandColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
          halfHourBandColor: Theme.of(
            context,
          ).colorScheme.surface.withValues(alpha: 0.015),
        ),
      ),
    );
  }
}

class _GuideTimelineGridPainter extends CustomPainter {
  const _GuideTimelineGridPainter({
    required this.start,
    required this.slotWidth,
    required this.segmentCount,
    required this.leadingWidth,
    required this.rowExtent,
    required this.majorColor,
    required this.minorColor,
    required this.rowColor,
    required this.hourBandColor,
    required this.halfHourBandColor,
  });

  final DateTime start;
  final double slotWidth;
  final int segmentCount;
  final double leadingWidth;
  final double rowExtent;
  final Color majorColor;
  final Color minorColor;
  final Color rowColor;
  final Color hourBandColor;
  final Color halfHourBandColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bandPaint = Paint()..style = PaintingStyle.fill;
    final majorPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = majorColor;
    final minorPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = minorColor;
    final rowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = rowColor;

    for (var i = 0; i < segmentCount; i++) {
      final segmentStart = start.add(Duration(minutes: i * _guideSlotMinutes));
      final x = leadingWidth + (i * slotWidth);
      if (x >= size.width) {
        continue;
      }
      final nextX = math.min(size.width, x + slotWidth);
      bandPaint.color = segmentStart.minute == 0
          ? hourBandColor
          : halfHourBandColor;
      canvas.drawRect(Rect.fromLTRB(x, 0, nextX, size.height), bandPaint);
    }

    if (leadingWidth > 0) {
      canvas.drawLine(
        Offset(leadingWidth, 0),
        Offset(leadingWidth, size.height),
        majorPaint,
      );
    }
    for (var i = 0; i <= segmentCount; i++) {
      final segmentStart = start.add(Duration(minutes: i * _guideSlotMinutes));
      final x = leadingWidth + (i * slotWidth);
      if (x > size.width) {
        continue;
      }
      final paint = segmentStart.minute == 0 ? majorPaint : minorPaint;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += rowExtent) {
      canvas.drawLine(Offset(leadingWidth, y), Offset(size.width, y), rowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GuideTimelineGridPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.slotWidth != slotWidth ||
        oldDelegate.segmentCount != segmentCount ||
        oldDelegate.leadingWidth != leadingWidth ||
        oldDelegate.rowExtent != rowExtent ||
        oldDelegate.majorColor != majorColor ||
        oldDelegate.minorColor != minorColor ||
        oldDelegate.rowColor != rowColor ||
        oldDelegate.hourBandColor != hourBandColor ||
        oldDelegate.halfHourBandColor != halfHourBandColor;
  }
}

class _GuideNowIndicator extends StatelessWidget {
  const _GuideNowIndicator({required this.axisHeight});

  final double axisHeight;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 8,
        height: axisHeight,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: const Offset(0, 3),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kGuideTvAccent,
                boxShadow: [
                  BoxShadow(
                    color: _kGuideTvAccent.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideGapPatternPainter extends CustomPainter {
  const _GuideGapPatternPainter({
    required this.lineColor,
    required this.spacing,
  });

  final Color lineColor;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = lineColor;
    for (double x = -size.height; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GuideGapPatternPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor || oldDelegate.spacing != spacing;
  }
}

class _GuideChannelHeader extends StatelessWidget {
  const _GuideChannelHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: _guideTimeAxisHeight,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface.withValues(alpha: 0.12),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.18),
            width: 1,
          ),
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 10.4,
              color: colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: 0.24,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideChannelCell extends StatelessWidget {
  const _GuideChannelCell({required this.stream, required this.isActive});

  final LiveStream stream;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final logoUrl = BrandedArtwork.normalizeArtworkUrl(stream.iconUrl);
    return Container(
      height: _guideRowHeight,
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isActive
              ? [
                  _kGuideTvAccent.withValues(alpha: 0.16),
                  colorScheme.surface.withValues(alpha: 0.05),
                ]
              : [
                  colorScheme.surface.withValues(alpha: 0.04),
                  colorScheme.surface.withValues(alpha: 0.02),
                ],
        ),
        border: Border(
          left: BorderSide(
            color: isActive ? _kGuideTvAccent : Colors.transparent,
            width: 3,
          ),
          right: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.16),
            width: 1,
          ),
          bottom: BorderSide(
            color: colorScheme.outline.withValues(
              alpha: isActive ? 0.18 : 0.12,
            ),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: BrandedArtwork(
              imageUrl: logoUrl,
              aspectRatio: 16 / 11,
              fit: BoxFit.contain,
              imagePadding: const EdgeInsets.all(2),
              icon: Icons.live_tv_rounded,
              placeholderLabel: _channelBadgeLabel(stream.name),
              borderRadius: 5,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              stream.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                fontSize: 13.5,
                color: isActive
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.86),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideRowTimeCell extends StatelessWidget {
  const _GuideRowTimeCell({
    required this.width,
    required this.start,
    required this.end,
  });

  final double width;
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: _guideRowHeight,
      padding: const EdgeInsets.fromLTRB(5, 4, 4, 4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.2),
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatClock(start),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 10,
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.24),
          ),
          const SizedBox(height: 2),
          Text(
            _formatClock(end),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideChip extends StatelessWidget {
  const _GuideChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.36,
        ),
      ),
    );
  }
}

class _GuideStateCard extends StatelessWidget {
  const _GuideStateCard({
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
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: colorScheme.surface.withValues(alpha: 0.64),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.38),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: _kGuideTvAccent),
              const SizedBox(width: 14),
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
                        color: colorScheme.onSurface.withValues(alpha: 0.78),
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

enum _GuideFilterKind { all, favorites, category }

class _GuideFilterOption {
  const _GuideFilterOption({
    required this.key,
    required this.label,
    required this.kind,
    this.categoryId,
  });

  final String key;
  final String label;
  final _GuideFilterKind kind;
  final String? categoryId;
}

class _GuideProgramBlock {
  const _GuideProgramBlock({
    required this.stream,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.startOffset,
    required this.width,
    required this.isGap,
    required this.kind,
  });

  final LiveStream stream;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final double startOffset;
  final double width;
  final bool isGap;
  final _GuideProgramBlockKind kind;

  bool contains(DateTime instant) =>
      !instant.isBefore(startAt) && instant.isBefore(endAt);
}

enum _GuideProgramBlockKind { program, scheduleGap, noGuide }

class _GuideFocusedProgram {
  const _GuideFocusedProgram({
    required this.key,
    required this.stream,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
  });

  final String key;
  final LiveStream stream;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;

  factory _GuideFocusedProgram.fromBlock(_GuideProgramBlock block) {
    final key =
        '${block.stream.id}:${block.startAt.millisecondsSinceEpoch}:${block.endAt.millisecondsSinceEpoch}:${block.title}';
    return _GuideFocusedProgram(
      key: key,
      stream: block.stream,
      title: block.title,
      description: block.description,
      startAt: block.startAt,
      endAt: block.endAt,
    );
  }
}

List<_GuideProgramBlock> _buildGuideBlocks({
  required LiveStream stream,
  required List<LiveEpgEntry> entries,
  required DateTime windowStart,
  required DateTime windowEnd,
  required double pixelsPerMinute,
  required String noEpgLabel,
}) {
  final timelineWidth = _guideWindowMinutes * pixelsPerMinute;

  if (entries.isEmpty) {
    return [
      _GuideProgramBlock(
        stream: stream,
        title: noEpgLabel,
        description: 'Dados de grade indisponiveis neste horario.',
        startAt: windowStart,
        endAt: windowEnd,
        startOffset: 0,
        width: timelineWidth,
        isGap: true,
        kind: _GuideProgramBlockKind.noGuide,
      ),
    ];
  }

  final sortedEntries = [...entries]
    ..sort((a, b) => a.startAt.compareTo(b.startAt));
  final blocks = <_GuideProgramBlock>[];
  var cursor = windowStart;

  for (final entry in sortedEntries) {
    if (!entry.endAt.isAfter(windowStart) ||
        !entry.startAt.isBefore(windowEnd)) {
      continue;
    }
    final start = entry.startAt.isBefore(windowStart)
        ? windowStart
        : entry.startAt;
    final end = entry.endAt.isAfter(windowEnd) ? windowEnd : entry.endAt;
    if (!end.isAfter(start)) {
      continue;
    }

    if (start.isAfter(cursor)) {
      final gapWidth = _timeOffset(
        start,
        start: cursor,
        pixelsPerMinute: pixelsPerMinute,
      );
      blocks.add(
        _GuideProgramBlock(
          stream: stream,
          title: 'Sem programacao',
          description: 'Sem eventos cadastrados neste trecho.',
          startAt: cursor,
          endAt: start,
          startOffset: _timeOffset(
            cursor,
            start: windowStart,
            pixelsPerMinute: pixelsPerMinute,
          ),
          width: math.max(1, gapWidth),
          isGap: true,
          kind: _GuideProgramBlockKind.scheduleGap,
        ),
      );
    }

    blocks.add(
      _GuideProgramBlock(
        stream: stream,
        title: entry.title,
        description: entry.description,
        startAt: start,
        endAt: end,
        startOffset: _timeOffset(
          start,
          start: windowStart,
          pixelsPerMinute: pixelsPerMinute,
        ),
        width: math.max(
          1,
          _timeOffset(end, start: start, pixelsPerMinute: pixelsPerMinute),
        ),
        isGap: false,
        kind: _GuideProgramBlockKind.program,
      ),
    );
    cursor = end;
  }

  if (blocks.isEmpty) {
    return [
      _GuideProgramBlock(
        stream: stream,
        title: noEpgLabel,
        description: 'Nao ha dados de grade nesta janela.',
        startAt: windowStart,
        endAt: windowEnd,
        startOffset: 0,
        width: timelineWidth,
        isGap: true,
        kind: _GuideProgramBlockKind.noGuide,
      ),
    ];
  }

  if (cursor.isBefore(windowEnd)) {
    blocks.add(
      _GuideProgramBlock(
        stream: stream,
        title: 'Sem programacao',
        description: 'Sem eventos cadastrados no restante desta faixa.',
        startAt: cursor,
        endAt: windowEnd,
        startOffset: _timeOffset(
          cursor,
          start: windowStart,
          pixelsPerMinute: pixelsPerMinute,
        ),
        width: math.max(
          1,
          _timeOffset(
            windowEnd,
            start: cursor,
            pixelsPerMinute: pixelsPerMinute,
          ),
        ),
        isGap: true,
        kind: _GuideProgramBlockKind.scheduleGap,
      ),
    );
  }

  return blocks;
}

DateTime _resolveGuideWindowStart(DateTime now) {
  final rounded = now.minute < 30 ? 0 : 30;
  final anchor = DateTime(now.year, now.month, now.day, now.hour, rounded);
  return anchor.subtract(const Duration(minutes: 30));
}

double _timeOffset(
  DateTime instant, {
  required DateTime start,
  required double pixelsPerMinute,
}) {
  final diffMinutes = instant.difference(start).inSeconds / 60;
  return diffMinutes * pixelsPerMinute;
}

double? _resolveCurrentTimeOffset({
  required DateTime now,
  required DateTime windowStart,
  required DateTime windowEnd,
  required double pixelsPerMinute,
}) {
  if (now.isBefore(windowStart) || !now.isBefore(windowEnd)) {
    return null;
  }
  return _timeOffset(now, start: windowStart, pixelsPerMinute: pixelsPerMinute);
}

double? _currentProgress({
  required DateTime now,
  required DateTime start,
  required DateTime end,
}) {
  final total = end.difference(start).inMilliseconds;
  if (total <= 0 || now.isBefore(start) || !now.isBefore(end)) {
    return null;
  }
  final elapsed = now.difference(start).inMilliseconds;
  final progress = elapsed / total;
  return progress.clamp(0.0, 1.0);
}

String _channelBadgeLabel(String name) {
  final cleaned = name.trim();
  if (cleaned.isEmpty) {
    return 'TV';
  }
  final words = cleaned
      .split(RegExp(r'\s+'))
      .where((word) => word.trim().isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return 'TV';
  }
  if (words.length == 1) {
    final token = words.first.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (token.isEmpty) {
      return 'TV';
    }
    return token.substring(0, math.min(token.length, 3)).toUpperCase();
  }
  final initials = words
      .take(3)
      .map((word) => word.replaceAll(RegExp(r'[^A-Za-z0-9]'), ''))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase())
      .join();
  return initials.isEmpty ? 'TV' : initials;
}

String _formatClock(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatTimeRange(DateTime start, DateTime end) {
  return '${_formatClock(start)} - ${_formatClock(end)}';
}
