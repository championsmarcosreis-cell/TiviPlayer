import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/errors/failure.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/testing/app_test_keys.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/playback_history_entry.dart';
import '../controllers/playback_history_controller.dart';
import '../../domain/entities/playback_context.dart';
import '../../domain/entities/player_recovery_policy.dart';
import '../../domain/entities/resolved_playback.dart';
import '../providers/player_providers.dart';
import '../widgets/player_control_button.dart';

class PlayerPreviewState {
  const PlayerPreviewState({
    required this.title,
    required this.isLive,
    required this.position,
    required this.duration,
    this.isPlaying = true,
  });

  final String title;
  final bool isLive;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
}

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    required this.playbackContext,
    this.previewState,
    this.recoveryPolicy = const PlayerRecoveryPolicy(),
  });

  static const routePath = '/player';

  final PlaybackContext? playbackContext;
  final PlayerPreviewState? previewState;
  final PlayerRecoveryPolicy recoveryPolicy;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  VideoPlayerController? _controller;
  ResolvedPlayback? _resolvedPlayback;
  String? _errorMessage;
  String? _statusMessage;
  bool _isInitializing = true;
  bool _isDisposing = false;
  bool _isRecoveringRuntime = false;
  bool _showPlaybackUi = true;
  bool _lastKnownPlaying = false;
  DateTime? _bufferingSince;
  Timer? _overlayHideTimer;
  DateTime? _lastProgressSaveAt;
  Duration _lastSavedPosition = Duration.zero;
  int _runtimeRecoveryAttempts = 0;
  int _initializationVersion = 0;
  late final PlaybackHistoryController _playbackHistoryController;

  @override
  void initState() {
    super.initState();
    _playbackHistoryController = ref.read(
      playbackHistoryControllerProvider.notifier,
    );
    if (widget.previewState != null) {
      _isInitializing = false;
      return;
    }
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    Future<void>.microtask(_initializePlayer);
  }

  @override
  void dispose() {
    _isDisposing = true;
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _overlayHideTimer?.cancel();
    _controller?.removeListener(_handleControllerUpdate);
    _persistPlaybackProgress(force: true);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedPlayback = _resolvedPlayback;
    final controller = _controller;
    final playerValue = controller?.value;
    final hasReadyVideo = playerValue?.isInitialized == true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _revealPlaybackUi,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = DeviceLayout.of(context, constraints: constraints);
            final previewState = widget.previewState;
            final showOverlayUi =
                previewState != null ||
                _showPlaybackUi ||
                _isInitializing ||
                _errorMessage != null ||
                !(playerValue?.isPlaying ?? false);

            if (previewState != null) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFF05080F)),
                  _PlayerPreviewStage(
                    previewState: previewState,
                    layout: layout,
                  ),
                  const _PlayerOverlayGradients(),
                  _PlayerTopBar(
                    title: previewState.title,
                    isLive: previewState.isLive,
                    layout: layout,
                    onBack: () => context.pop(),
                  ),
                  _PreviewControlDeck(
                    previewState: previewState,
                    layout: layout,
                  ),
                ],
              );
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                _PlayerSurface(controller: controller),
                if (hasReadyVideo)
                  const Positioned(
                    top: 0,
                    left: 0,
                    child: SizedBox(
                      key: AppTestKeys.playerLoadedState,
                      width: 1,
                      height: 1,
                    ),
                  ),
                if (showOverlayUi) const _PlayerOverlayGradients(),
                if (_isInitializing)
                  Center(
                    child: _LoadingPanel(
                      message: _statusMessage ?? 'Carregando video...',
                    ),
                  ),
                if (!_isInitializing && _errorMessage != null)
                  Center(
                    child: _ErrorPanel(
                      key: AppTestKeys.playerErrorState,
                      message: _errorMessage!,
                      onRetry: _initializePlayer,
                    ),
                  ),
                if (!_isInitializing && _errorMessage == null && showOverlayUi)
                  _PlayerTopBar(
                    title:
                        resolvedPlayback?.context.title ??
                        widget.playbackContext?.title ??
                        'Player',
                    isLive: resolvedPlayback?.isLive ?? false,
                    layout: layout,
                    onBack: () => context.pop(),
                  ),
                if (!_isInitializing &&
                    _errorMessage == null &&
                    showOverlayUi &&
                    hasReadyVideo &&
                    controller != null &&
                    resolvedPlayback != null)
                  _PlayerControlDeck(
                    controller: controller,
                    resolvedPlayback: resolvedPlayback,
                    layout: layout,
                    title: resolvedPlayback.context.title,
                    onTogglePlayback: _togglePlayPause,
                    onSeekBackward: () =>
                        _seekRelative(const Duration(seconds: -10)),
                    onSeekForward: () =>
                        _seekRelative(const Duration(seconds: 10)),
                  ),
                if (!_isInitializing &&
                    _errorMessage == null &&
                    _statusMessage != null)
                  Positioned(
                    left: layout.pageHorizontalPadding,
                    top: layout.pageTopPadding + 84,
                    child: _StatusBanner(message: _statusMessage!),
                  ),
                if (playerValue?.isBuffering == true && _errorMessage == null)
                  Positioned(
                    right: layout.pageHorizontalPadding,
                    top: layout.pageTopPadding + 78,
                    child: _BufferingBadge(recovering: _isRecoveringRuntime),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _initializePlayer() async {
    if (!mounted || _isDisposing) {
      return;
    }

    final playbackContext = widget.playbackContext;

    if (playbackContext == null) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Contexto de playback ausente.';
      });
      return;
    }

    final wasRecoveringRuntime = _isRecoveringRuntime;
    _runtimeRecoveryAttempts = widget.recoveryPolicy
        .runtimeAttemptsAfterInitializationStart(
          currentAttempts: _runtimeRecoveryAttempts,
          fromRuntimeRecovery: wasRecoveringRuntime,
        );
    final requestVersion = ++_initializationVersion;
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _statusMessage = wasRecoveringRuntime
          ? widget.recoveryPolicy.runtimeRecoveryLabel(
              attemptNumber: _runtimeRecoveryAttempts,
              isLive: playbackContext.isLive,
            )
          : null;
      _showPlaybackUi = true;
    });

    _controller?.removeListener(_handleControllerUpdate);
    await _controller?.dispose();
    _controller = null;
    _bufferingSince = null;

    final session = ref.read(currentSessionProvider);
    if (session == null) {
      if (!mounted ||
          _isDisposing ||
          requestVersion != _initializationVersion) {
        return;
      }
      setState(() {
        _resolvedPlayback = null;
        _isInitializing = false;
        _errorMessage = 'Sessao indisponivel.';
      });
      return;
    }

    Object? lastError;
    for (
      var attempt = 0;
      attempt < widget.recoveryPolicy.totalInitializationAttempts;
      attempt++
    ) {
      if (!mounted ||
          _isDisposing ||
          requestVersion != _initializationVersion) {
        return;
      }

      if (attempt > 0) {
        setState(() {
          _statusMessage = widget.recoveryPolicy.initializationRetryLabel(
            attemptNumber: attempt + 1,
            isLive: playbackContext.isLive,
          );
        });
        await Future<void>.delayed(
          widget.recoveryPolicy.initializationRetryDelay(attempt - 1),
        );
        if (!mounted ||
            _isDisposing ||
            requestVersion != _initializationVersion) {
          return;
        }
      }

      VideoPlayerController? attemptController;
      try {
        final resolvedPlayback = ref
            .read(resolvePlaybackUseCaseProvider)
            .call(session, playbackContext);

        final controller = VideoPlayerController.networkUrl(
          resolvedPlayback.uri,
        );
        attemptController = controller;
        await controller.initialize();
        final resumePosition = playbackContext.resumePosition;
        if (resumePosition != null &&
            resolvedPlayback.isSeekable &&
            resumePosition > Duration.zero) {
          final maxResume =
              controller.value.duration - const Duration(seconds: 2);
          final clampedResume = maxResume > Duration.zero
              ? (resumePosition > maxResume ? maxResume : resumePosition)
              : Duration.zero;
          if (clampedResume > Duration.zero) {
            await controller.seekTo(clampedResume);
          }
        }
        controller.addListener(_handleControllerUpdate);
        await controller.play();

        if (!mounted ||
            _isDisposing ||
            requestVersion != _initializationVersion) {
          await controller.dispose();
          return;
        }

        setState(() {
          _resolvedPlayback = resolvedPlayback;
          _controller = controller;
          _isInitializing = false;
          _errorMessage = null;
          _statusMessage = null;
          _isRecoveringRuntime = false;
        });
        _runtimeRecoveryAttempts = 0;
        _lastKnownPlaying = controller.value.isPlaying;
        _revealPlaybackUi(autoHide: controller.value.isPlaying);
        return;
      } catch (error) {
        final danglingController = attemptController;
        if (danglingController != null) {
          danglingController.removeListener(_handleControllerUpdate);
          await danglingController.dispose();
        }
        lastError = error;
      }
    }

    if (!mounted || _isDisposing || requestVersion != _initializationVersion) {
      return;
    }

    setState(() {
      _resolvedPlayback = null;
      _isInitializing = false;
      _isRecoveringRuntime = false;
      _statusMessage = null;
      _errorMessage = Failure.fromError(
        lastError ?? StateError('Falha ao carregar stream.'),
      ).message;
    });
  }

  void _handleControllerUpdate() {
    final controller = _controller;
    if (!mounted || _isDisposing || controller == null) {
      return;
    }

    final value = controller.value;
    if (value.hasError) {
      unawaited(
        _attemptRuntimeRecovery(
          value.errorDescription ?? 'Falha ao carregar o stream no player.',
        ),
      );
      return;
    }
    _trackBufferingRecovery(value);

    if (value.isPlaying != _lastKnownPlaying) {
      _lastKnownPlaying = value.isPlaying;
      if (value.isPlaying) {
        _scheduleOverlayHide();
      } else {
        _revealPlaybackUi(autoHide: false);
      }
    }

    _persistPlaybackProgress();
    setState(() {});
  }

  void _trackBufferingRecovery(VideoPlayerValue value) {
    if (!value.isInitialized || !value.isPlaying || !value.isBuffering) {
      _bufferingSince = null;
      return;
    }

    _bufferingSince ??= DateTime.now();
    final stalledFor = DateTime.now().difference(_bufferingSince!);
    if (stalledFor < widget.recoveryPolicy.bufferingStallThreshold) {
      return;
    }

    _bufferingSince = null;
    unawaited(
      _attemptRuntimeRecovery('Buffering prolongado ao reproduzir o stream.'),
    );
  }

  Future<void> _attemptRuntimeRecovery(String fallbackError) async {
    final playbackContext = widget.playbackContext;
    if (!mounted ||
        _isDisposing ||
        _isInitializing ||
        _isRecoveringRuntime ||
        playbackContext == null) {
      return;
    }

    final nextAttempt = widget.recoveryPolicy.nextRuntimeRecoveryAttempt(
      _runtimeRecoveryAttempts,
    );
    if (nextAttempt == null) {
      if (_errorMessage == null) {
        setState(() {
          _statusMessage = null;
          _errorMessage = fallbackError;
          _showPlaybackUi = true;
        });
      }
      return;
    }

    _runtimeRecoveryAttempts = nextAttempt;
    final currentAttempt = nextAttempt;
    setState(() {
      _showPlaybackUi = true;
      _isRecoveringRuntime = true;
      _errorMessage = null;
      _statusMessage = widget.recoveryPolicy.runtimeRecoveryLabel(
        attemptNumber: currentAttempt,
        isLive: playbackContext.isLive,
      );
    });

    await Future<void>.delayed(widget.recoveryPolicy.runtimeRecoveryDelay);
    if (!mounted || _isDisposing) {
      return;
    }
    await _initializePlayer();
  }

  void _persistPlaybackProgress({bool force = false}) {
    final controller = _controller;
    final resolved = _resolvedPlayback;
    if (controller == null || resolved == null || !resolved.isSeekable) {
      return;
    }

    final value = controller.value;
    if (!value.isInitialized) {
      return;
    }

    final duration = value.duration;
    final position = value.position;
    if (duration <= Duration.zero || position <= Duration.zero) {
      return;
    }

    if (!force) {
      final now = DateTime.now();
      final enoughTime =
          _lastProgressSaveAt == null ||
          now.difference(_lastProgressSaveAt!) >= const Duration(seconds: 4);
      final positionDelta =
          (position - _lastSavedPosition).abs() >= const Duration(seconds: 4);

      if (!enoughTime || !positionDelta) {
        return;
      }
    }

    _lastProgressSaveAt = DateTime.now();
    _lastSavedPosition = position;

    final isComplete =
        position.inMilliseconds >= (duration.inMilliseconds * 0.95).round();
    final contextData = resolved.context;

    if (isComplete) {
      unawaited(
        _playbackHistoryController.remove(
          contextData.contentType,
          contextData.itemId,
        ),
      );
      return;
    }

    final entry = PlaybackHistoryEntry(
      contentType: contextData.contentType,
      itemId: contextData.itemId,
      title: contextData.title,
      positionMs: position.inMilliseconds,
      durationMs: duration.inMilliseconds,
      updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      containerExtension: contextData.containerExtension,
      artworkUrl: contextData.artworkUrl,
    );
    unawaited(_playbackHistoryController.upsert(entry));
  }

  Future<void> _togglePlayPause() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    _revealPlaybackUi();

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> _seekRelative(Duration offset) async {
    final controller = _controller;
    final resolvedPlayback = _resolvedPlayback;

    if (controller == null ||
        resolvedPlayback == null ||
        !resolvedPlayback.isSeekable) {
      return;
    }
    _revealPlaybackUi();

    final position = controller.value.position;
    final duration = controller.value.duration;
    final target = position + offset;

    final clamped = target < Duration.zero
        ? Duration.zero
        : target > duration
        ? duration
        : target;

    await controller.seekTo(clamped);
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (!mounted || _isDisposing || widget.previewState != null) {
      return false;
    }
    if (event is KeyDownEvent) {
      _revealPlaybackUi();
    }
    return false;
  }

  void _revealPlaybackUi({bool autoHide = true}) {
    if (!mounted || widget.previewState != null) {
      return;
    }

    if (!_showPlaybackUi) {
      setState(() {
        _showPlaybackUi = true;
      });
    }

    if (autoHide) {
      _scheduleOverlayHide();
    } else {
      _overlayHideTimer?.cancel();
    }
  }

  void _scheduleOverlayHide() {
    _overlayHideTimer?.cancel();
    final directionalNavigation =
        MediaQuery.navigationModeOf(context) == NavigationMode.directional;
    if (!directionalNavigation) {
      return;
    }

    final controller = _controller;
    final canHide =
        !_isInitializing &&
        _errorMessage == null &&
        _statusMessage == null &&
        controller != null &&
        controller.value.isInitialized &&
        controller.value.isPlaying;

    if (!canHide) {
      return;
    }

    _overlayHideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _isDisposing) {
        return;
      }
      setState(() {
        _showPlaybackUi = false;
      });
    });
  }
}

class _PlayerSurface extends StatelessWidget {
  const _PlayerSurface({required this.controller});

  final VideoPlayerController? controller;

  @override
  Widget build(BuildContext context) {
    final value = controller?.value;
    if (controller == null || value?.isInitialized != true) {
      return const ColoredBox(color: Colors.black);
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: value!.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
          child: VideoPlayer(controller!),
        ),
      ),
    );
  }
}

class _PlayerPreviewStage extends StatelessWidget {
  const _PlayerPreviewStage({required this.previewState, required this.layout});

  final PlayerPreviewState previewState;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: layout.isTv ? 120 : 34,
          vertical: layout.isTv ? 140 : 120,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.isTv ? 30 : 22),
            gradient: LinearGradient(
              colors: [const Color(0x7A1A263A), const Color(0x3D132033)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  previewState.isLive
                      ? Icons.wifi_tethering_rounded
                      : Icons.movie_filter_rounded,
                  color: Colors.white.withValues(alpha: 0.78),
                  size: layout.isTv ? 62 : 40,
                ),
                SizedBox(height: layout.isTv ? 14 : 10),
                Text(
                  previewState.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: layout.isTv ? 30 : 20,
                    fontWeight: FontWeight.w700,
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

class _PlayerOverlayGradients extends StatelessWidget {
  const _PlayerOverlayGradients();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xE4000000),
                  const Color(0x95030A16),
                  Colors.transparent,
                  const Color(0xC0101A2A),
                  const Color(0xF0000000),
                ],
                stops: const [0, 0.18, 0.58, 0.82, 1],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [const Color(0x1E6CD8FF), const Color(0x003DA8FF)],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: 330,
              height: 210,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [const Color(0x24FF874D), const Color(0x00FF874D)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerTopBar extends StatelessWidget {
  const _PlayerTopBar({
    required this.title,
    required this.isLive,
    required this.layout,
    required this.onBack,
  });

  final String title;
  final bool isLive;
  final DeviceLayout layout;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final chipStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Colors.white.withValues(alpha: 0.9),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.7,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          layout.pageHorizontalPadding,
          layout.pageTopPadding,
          layout.pageHorizontalPadding,
          0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(layout.isTv ? 24 : 18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: layout.isTv ? 16 : 12,
                vertical: layout.isTv ? 12 : 9,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xC9152234), const Color(0xA60A111E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              ),
              child: Row(
                children: [
                  PlayerControlButton(
                    interactiveKey: AppTestKeys.playerCloseButton,
                    icon: Icons.arrow_back_rounded,
                    label: 'Sair',
                    testId: AppTestKeys.playerCloseButtonId,
                    autofocus: true,
                    kind: PlayerControlButtonKind.subtle,
                    onPressed: onBack,
                  ),
                  SizedBox(width: layout.cardSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: layout.isTv ? 30 : 19.5,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          isLive
                              ? 'Transmissao ao vivo'
                              : 'Reproducao sob demanda',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: layout.isTv ? 14 : 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLive && layout.isTv)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0x4D3A8AFF),
                        border: Border.all(color: const Color(0x8873B4FF)),
                      ),
                      child: Text('VOD', style: chipStyle),
                    ),
                  if (isLive) ...[
                    if (layout.isTv) const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xCCFF5E69),
                        border: Border.all(color: const Color(0xFFFF9AA2)),
                      ),
                      child: Text('AO VIVO', style: chipStyle),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerControlDeck extends StatelessWidget {
  const _PlayerControlDeck({
    required this.controller,
    required this.resolvedPlayback,
    required this.layout,
    required this.title,
    required this.onTogglePlayback,
    required this.onSeekBackward,
    required this.onSeekForward,
  });

  final VideoPlayerController controller;
  final ResolvedPlayback resolvedPlayback;
  final DeviceLayout layout;
  final String title;
  final VoidCallback onTogglePlayback;
  final VoidCallback onSeekBackward;
  final VoidCallback onSeekForward;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final isSeekable = resolvedPlayback.isSeekable;
    final isPlaying = value.isPlaying;
    final total = value.duration;
    final current = value.position;
    final remaining = total - current;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            layout.pageHorizontalPadding,
            0,
            layout.pageHorizontalPadding,
            layout.pageBottomPadding,
          ),
          child: _PlayerDeckContainer(
            layout: layout,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      resolvedPlayback.isLive
                          ? Icons.wifi_tethering_rounded
                          : Icons.movie_filter_rounded,
                      color: Colors.white.withValues(alpha: 0.86),
                      size: layout.isTv ? 24 : 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontSize: layout.isTv ? 22 : 16.5,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (resolvedPlayback.isLive)
                      Text(
                        'LIVE',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: const Color(0xFFFF8D95),
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                  ],
                ),
                SizedBox(height: layout.isTv ? 14 : 10),
                if (isSeekable) ...[
                  _TimelinePanel(
                    layout: layout,
                    child: Column(
                      children: [
                        _PlayerTimeline(controller: controller, layout: layout),
                        SizedBox(height: layout.isTv ? 10 : 8),
                        Row(
                          children: [
                            Text(
                              _formatDuration(current),
                              style: _timeStyle(context, layout),
                            ),
                            const Spacer(),
                            Text(
                              '-${_formatDuration(remaining.isNegative ? Duration.zero : remaining)}',
                              style: _timeStyle(context, layout),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(total),
                              style: _timeStyle(context, layout).copyWith(
                                color: Colors.white.withValues(alpha: 0.74),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'Sinal ao vivo em reproducao',
                    style: _timeStyle(
                      context,
                      layout,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
                SizedBox(height: layout.isTv ? 14 : 10),
                _ControlsPanel(
                  layout: layout,
                  child: layout.isTv
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSeekable)
                              PlayerControlButton(
                                icon: Icons.replay_10_rounded,
                                label: '-10s',
                                onPressed: onSeekBackward,
                                kind: PlayerControlButtonKind.secondary,
                              ),
                            if (isSeekable) const SizedBox(width: 10),
                            PlayerControlButton(
                              icon: isPlaying
                                  ? Icons.pause_circle_rounded
                                  : Icons.play_circle_rounded,
                              label: isPlaying ? 'Pausar' : 'Reproduzir',
                              onPressed: onTogglePlayback,
                              kind: PlayerControlButtonKind.primary,
                              prominent: true,
                            ),
                            if (isSeekable) const SizedBox(width: 10),
                            if (isSeekable)
                              PlayerControlButton(
                                icon: Icons.forward_10_rounded,
                                label: '+10s',
                                onPressed: onSeekForward,
                                kind: PlayerControlButtonKind.secondary,
                              ),
                          ],
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (isSeekable)
                              PlayerControlButton(
                                icon: Icons.replay_10_rounded,
                                label: '-10s',
                                onPressed: onSeekBackward,
                                kind: PlayerControlButtonKind.secondary,
                              ),
                            PlayerControlButton(
                              icon: isPlaying
                                  ? Icons.pause_circle_rounded
                                  : Icons.play_circle_rounded,
                              label: isPlaying ? 'Pausar' : 'Reproduzir',
                              onPressed: onTogglePlayback,
                              kind: PlayerControlButtonKind.primary,
                              prominent: true,
                            ),
                            if (isSeekable)
                              PlayerControlButton(
                                icon: Icons.forward_10_rounded,
                                label: '+10s',
                                onPressed: onSeekForward,
                                kind: PlayerControlButtonKind.secondary,
                              ),
                          ],
                        ),
                ),
                if (isSeekable && layout.isTv) ...[
                  SizedBox(height: layout.isTv ? 10 : 8),
                  Text(
                    'Use esquerda/direita para avancar 10s',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.66),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _timeStyle(BuildContext context, DeviceLayout layout) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      color: Colors.white.withValues(alpha: 0.86),
      fontSize: layout.isTv ? 15 : 12.5,
      fontWeight: FontWeight.w600,
    );
  }
}

class _PreviewControlDeck extends StatelessWidget {
  const _PreviewControlDeck({required this.previewState, required this.layout});

  final PlayerPreviewState previewState;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    final total = previewState.duration;
    final current = previewState.position;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : current.inMilliseconds / total.inMilliseconds;
    final remaining = total - current;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            layout.pageHorizontalPadding,
            0,
            layout.pageHorizontalPadding,
            layout.pageBottomPadding,
          ),
          child: _PlayerDeckContainer(
            layout: layout,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      previewState.isLive
                          ? Icons.wifi_tethering_rounded
                          : Icons.movie_filter_rounded,
                      color: Colors.white.withValues(alpha: 0.86),
                      size: layout.isTv ? 24 : 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        previewState.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontSize: layout.isTv ? 22 : 16.5,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (previewState.isLive)
                      Text(
                        'LIVE',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: const Color(0xFFFF8D95),
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                  ],
                ),
                SizedBox(height: layout.isTv ? 14 : 10),
                if (!previewState.isLive) ...[
                  _TimelinePanel(
                    layout: layout,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            minHeight: layout.isTv ? 14 : 10,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        SizedBox(height: layout.isTv ? 10 : 8),
                        Row(
                          children: [
                            Text(
                              _formatDuration(current),
                              style: _timeStyle(context, layout),
                            ),
                            const Spacer(),
                            Text(
                              '-${_formatDuration(remaining.isNegative ? Duration.zero : remaining)}',
                              style: _timeStyle(context, layout),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(total),
                              style: _timeStyle(context, layout).copyWith(
                                color: Colors.white.withValues(alpha: 0.74),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'Sinal ao vivo em reproducao',
                    style: _timeStyle(
                      context,
                      layout,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
                SizedBox(height: layout.isTv ? 14 : 10),
                _ControlsPanel(
                  layout: layout,
                  child: layout.isTv
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!previewState.isLive)
                              PlayerControlButton(
                                icon: Icons.replay_10_rounded,
                                label: '-10s',
                                onPressed: () {},
                                kind: PlayerControlButtonKind.secondary,
                              ),
                            if (!previewState.isLive) const SizedBox(width: 10),
                            PlayerControlButton(
                              icon: previewState.isPlaying
                                  ? Icons.pause_circle_rounded
                                  : Icons.play_circle_rounded,
                              label: previewState.isPlaying
                                  ? 'Pausar'
                                  : 'Reproduzir',
                              onPressed: () {},
                              kind: PlayerControlButtonKind.primary,
                              prominent: true,
                            ),
                            if (!previewState.isLive) const SizedBox(width: 10),
                            if (!previewState.isLive)
                              PlayerControlButton(
                                icon: Icons.forward_10_rounded,
                                label: '+10s',
                                onPressed: () {},
                                kind: PlayerControlButtonKind.secondary,
                              ),
                          ],
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (!previewState.isLive)
                              PlayerControlButton(
                                icon: Icons.replay_10_rounded,
                                label: '-10s',
                                onPressed: () {},
                                kind: PlayerControlButtonKind.secondary,
                              ),
                            PlayerControlButton(
                              icon: previewState.isPlaying
                                  ? Icons.pause_circle_rounded
                                  : Icons.play_circle_rounded,
                              label: previewState.isPlaying
                                  ? 'Pausar'
                                  : 'Reproduzir',
                              onPressed: () {},
                              kind: PlayerControlButtonKind.primary,
                              prominent: true,
                            ),
                            if (!previewState.isLive)
                              PlayerControlButton(
                                icon: Icons.forward_10_rounded,
                                label: '+10s',
                                onPressed: () {},
                                kind: PlayerControlButtonKind.secondary,
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _timeStyle(BuildContext context, DeviceLayout layout) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      color: Colors.white.withValues(alpha: 0.86),
      fontSize: layout.isTv ? 15 : 12.5,
      fontWeight: FontWeight.w600,
    );
  }
}

class _PlayerDeckContainer extends StatelessWidget {
  const _PlayerDeckContainer({required this.layout, required this.child});

  final DeviceLayout layout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = layout.isTv ? 26.0 : 20.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: [const Color(0xCC111C2C), const Color(0xB20A101B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(layout.isTv ? 18 : 14),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({required this.layout, required this.child});

  final DeviceLayout layout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(layout.isTv ? 13 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 16 : 14),
        gradient: LinearGradient(
          colors: [const Color(0x3376AAFF), const Color(0x1AFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({required this.layout, required this.child});

  final DeviceLayout layout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: layout.isTv ? 16 : 11,
        vertical: layout.isTv ? 14 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 18 : 14),
        gradient: LinearGradient(
          colors: [const Color(0x2E4A9CFF), const Color(0x1AFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: child,
    );
  }
}

class _PlayerTimeline extends StatelessWidget {
  const _PlayerTimeline({required this.controller, required this.layout});

  final VideoPlayerController controller;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: layout.isTv ? 13 : 9,
        child: VideoProgressIndicator(
          controller,
          allowScrubbing: true,
          padding: EdgeInsets.zero,
          colors: VideoProgressColors(
            playedColor: Theme.of(context).colorScheme.primaryContainer,
            bufferedColor: Colors.white.withValues(alpha: 0.5),
            backgroundColor: Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xCC122038), const Color(0xAA0B111E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _BufferingBadge extends StatelessWidget {
  const _BufferingBadge({required this.recovering});

  final bool recovering;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: recovering
              ? [const Color(0xCC2A1C3A), const Color(0xAA1B1028)]
              : [const Color(0xCC152237), const Color(0xAA101724)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: recovering
              ? const Color(0xFFBC8FFF)
              : Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(recovering ? 'Reconectando...' : 'Buffering'),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC10233D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x8A8CC8FF)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sync_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({super.key, required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 44),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              PlayerControlButton(
                interactiveKey: AppTestKeys.playerRetryButton,
                icon: Icons.refresh_rounded,
                label: 'Tentar novamente',
                onPressed: () {
                  onRetry();
                },
                kind: PlayerControlButtonKind.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration value) {
  final totalSeconds = value.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
