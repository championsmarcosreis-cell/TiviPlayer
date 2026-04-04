import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/tv/tv_focusable.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/testing/app_test_keys.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/playback_history_entry.dart';
import '../controllers/playback_history_controller.dart';
import '../../domain/entities/playback_context.dart';
import '../../domain/engine/player_engine_adapter.dart';
import '../../domain/entities/playback_manifest.dart';
import '../../domain/entities/player_recovery_policy.dart';
import '../../domain/entities/player_runtime_issue.dart';
import '../../domain/entities/resolved_playback.dart';
import '../../domain/observability/player_telemetry.dart';
import '../providers/player_providers.dart';
import '../support/player_screen_arguments.dart';
import '../widgets/player_control_button.dart';

const MethodChannel _displayControlChannel = MethodChannel(
  'tiviplayer/display_control_android',
);

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

enum _PlayerOverlayVisibility { expanded, compact, hidden }

enum _MobileInlineUtility { none, volume, brightness }

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    this.arguments,
    this.playbackContext,
    this.liveNavigation,
    this.previewState,
    this.recoveryPolicy = const PlayerRecoveryPolicy(),
  }) : assert(
         arguments == null ||
             (playbackContext == null && liveNavigation == null),
         'When PlayerScreenArguments is provided, do not pass playbackContext '
         'or liveNavigation separately.',
       );

  static const routePath = '/player';

  final PlayerScreenArguments? arguments;
  final PlaybackContext? playbackContext;
  final PlayerLiveNavigation? liveNavigation;
  final PlayerPreviewState? previewState;
  final PlayerRecoveryPolicy recoveryPolicy;

  PlaybackContext? get initialPlaybackContext =>
      arguments?.playbackContext ?? playbackContext;

  PlayerLiveNavigation? get initialLiveNavigation =>
      arguments?.liveNavigation ?? liveNavigation;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  VideoPlayerController? _controller;
  PlaybackContext? _activePlaybackContext;
  PlayerLiveNavigation? _activeLiveNavigation;
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
  Timer? _interactionMessageTimer;
  Timer? _inactivePlaybackTimer;
  Timer? _mobileInlineUtilityTimer;
  DateTime? _lastProgressSaveAt;
  Duration _lastSavedPosition = Duration.zero;
  int _runtimeRecoveryAttempts = 0;
  int _initializationVersion = 0;
  String? _interactionMessage;
  DateTime? _lastRuntimeRecoveryStartedAt;
  bool _isMuted = false;
  double _volumeLevel = 1;
  double _lastVolumeBeforeMute = 1;
  double _screenBrightnessLevel = 0.8;
  bool _hasBrightnessControl = false;
  bool _didOverrideScreenBrightness = false;
  bool _keepScreenOnEnabled = false;
  _MobileInlineUtility _activeMobileInlineUtility = _MobileInlineUtility.none;
  double? _mobileVerticalGestureStartY;
  double _mobileVerticalGestureStartLevel = 0;
  List<PlaybackTrack> _audioTracks = const [];
  List<String> _subtitleTracks = const [];
  List<String> _qualityProfiles = const [];
  bool _hasRuntimeAudioTrackSelection = false;
  String? _selectedAudioTrackId;
  String? _selectedSubtitleTrack;
  String? _selectedQualityProfile;
  late final PlaybackHistoryController _playbackHistoryController;
  late final PlayerEngineAdapter _playerEngineAdapter;
  late final PlayerTelemetrySink _playerTelemetrySink;
  final ScreenBrightness _screenBrightnessController =
      ScreenBrightness.instance;
  final _runtimeIssueClassifier = const PlayerRuntimeIssueClassifier();

  @override
  void initState() {
    super.initState();
    unawaited(_enterPlayerImmersiveMode());
    _activePlaybackContext =
        widget.initialPlaybackContext ??
        widget.initialLiveNavigation?.playbackContext;
    _activeLiveNavigation = widget.initialLiveNavigation;
    _playbackHistoryController = ref.read(
      playbackHistoryControllerProvider.notifier,
    );
    _playerEngineAdapter = ref.read(playerEngineAdapterProvider);
    _playerTelemetrySink = ref.read(playerTelemetrySinkProvider);
    unawaited(_initializeBrightnessControl());
    if (widget.previewState != null) {
      _isInitializing = false;
      return;
    }
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    Future<void>.microtask(_initializePlayer);
  }

  @override
  void didUpdateWidget(covariant PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.arguments != oldWidget.arguments ||
        widget.playbackContext != oldWidget.playbackContext ||
        widget.liveNavigation != oldWidget.liveNavigation) {
      _activeLiveNavigation = widget.initialLiveNavigation;
      _activePlaybackContext =
          widget.initialPlaybackContext ??
          widget.initialLiveNavigation?.playbackContext;
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    unawaited(_restoreDefaultSystemUiMode());
    unawaited(_setKeepScreenOn(false));
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _overlayHideTimer?.cancel();
    _interactionMessageTimer?.cancel();
    _inactivePlaybackTimer?.cancel();
    _mobileInlineUtilityTimer?.cancel();
    _controller?.removeListener(_handleControllerUpdate);
    _persistPlaybackProgress(force: true);
    if (_didOverrideScreenBrightness) {
      unawaited(_restoreApplicationBrightness());
    }
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedPlayback = _resolvedPlayback;
    final activePlaybackContext = _activePlaybackContext;
    final controller = _controller;
    final playerValue = controller?.value;
    final hasReadyVideo = playerValue?.isInitialized == true;
    final streamMetrics =
        resolvedPlayback != null && hasReadyVideo && playerValue != null
        ? _deriveStreamMetrics(playerValue, isLive: resolvedPlayback.isLive)
        : null;

    return WillPopScope(
      onWillPop: _handleRouteBackNavigation,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _revealPlaybackUi,
          onHorizontalDragEnd: _handleHorizontalDragEnd,
          onVerticalDragStart: _handleVerticalDragStart,
          onVerticalDragUpdate: _handleVerticalDragUpdate,
          onVerticalDragEnd: _handleVerticalDragEnd,
          onVerticalDragCancel: _handleVerticalDragCancel,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = DeviceLayout.of(context, constraints: constraints);
              final previewState = widget.previewState;

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
                      onBack: () => unawaited(_handleBackNavigation()),
                    ),
                    _PreviewControlDeck(
                      previewState: previewState,
                      layout: layout,
                    ),
                  ],
                );
              }

              final overlayVisibility = _resolveOverlayVisibility(
                layout: layout,
                resolvedPlayback: resolvedPlayback,
                playerValue: playerValue,
                hasReadyVideo: hasReadyVideo,
                streamMetrics: streamMetrics,
              );
              final showExpandedOverlay =
                  overlayVisibility == _PlayerOverlayVisibility.expanded;
              final showCompactLiveBadge =
                  overlayVisibility == _PlayerOverlayVisibility.compact;

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
                  if (showExpandedOverlay) const _PlayerOverlayGradients(),
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
                  if (!_isInitializing &&
                      _errorMessage == null &&
                      showExpandedOverlay)
                    _PlayerTopBar(
                      title:
                          resolvedPlayback?.context.title ??
                          activePlaybackContext?.title ??
                          'Player',
                      isLive: resolvedPlayback?.isLive ?? false,
                      layout: layout,
                      onBack: () => unawaited(_handleBackNavigation()),
                    ),
                  if (!_isInitializing &&
                      _errorMessage == null &&
                      showExpandedOverlay &&
                      hasReadyVideo &&
                      controller != null &&
                      resolvedPlayback != null)
                    _PlayerControlDeck(
                      controller: controller,
                      resolvedPlayback: resolvedPlayback,
                      layout: layout,
                      activeMobileInlineUtility: _activeMobileInlineUtility,
                      isMuted: _isMuted,
                      volumeLevel: _volumeLevel,
                      screenBrightnessLevel: _screenBrightnessLevel,
                      hasBrightnessControl: _hasBrightnessControl,
                      selectedAudioTrack: _selectedAudioTrackLabel,
                      showAudioTrackSelector: _canSelectAudioTrack,
                      showSubtitleTrackSelector: _subtitleTracks.isNotEmpty,
                      selectedSubtitleTrack: _selectedSubtitleTrack,
                      showQualitySelector: _selectedQualityProfile != null,
                      selectedQualityProfile: _selectedQualityProfile,
                      qualityLabel: streamMetrics?.qualityLabel,
                      liveLatencyLabel: streamMetrics?.liveLatencyLabel,
                      onTogglePlayback: _togglePlayPause,
                      onSeekBackward: () =>
                          _seekRelative(const Duration(seconds: -10)),
                      onSeekForward: () =>
                          _seekRelative(const Duration(seconds: 10)),
                      canGoToPreviousChannel: _canGoToPreviousLiveChannel,
                      canGoToNextChannel: _canGoToNextLiveChannel,
                      onPreviousChannel: () =>
                          unawaited(_navigateToAdjacentLiveChannel(-1)),
                      onNextChannel: () =>
                          unawaited(_navigateToAdjacentLiveChannel(1)),
                      onSelectAudioTrack: _selectAudioTrack,
                      onSelectSubtitleTrack: _selectSubtitleTrack,
                      onSelectQualityProfile: _selectQualityProfile,
                    ),
                  if (!_isInitializing &&
                      _errorMessage == null &&
                      showExpandedOverlay &&
                      _statusMessage != null)
                    Positioned(
                      left: layout.pageHorizontalPadding,
                      top: layout.pageTopPadding + 84,
                      child: _StatusBanner(message: _statusMessage!),
                    ),
                  if (!_isInitializing &&
                      _errorMessage == null &&
                      showExpandedOverlay &&
                      _interactionMessage != null)
                    Positioned(
                      left: layout.pageHorizontalPadding,
                      right: layout.pageHorizontalPadding,
                      bottom:
                          layout.pageBottomPadding + (layout.isTv ? 156 : 140),
                      child: Align(
                        alignment: Alignment.center,
                        child: _InteractionToast(message: _interactionMessage!),
                      ),
                    ),
                  if (showCompactLiveBadge &&
                      streamMetrics != null &&
                      _errorMessage == null)
                    Positioned(
                      right: layout.pageHorizontalPadding,
                      top: layout.pageTopPadding + 78,
                      child: _LiveSignalBadge(
                        qualityLabel: streamMetrics.qualityLabel,
                        liveLatencyLabel: streamMetrics.liveLatencyLabel,
                        isBuffering: playerValue?.isBuffering == true,
                        recovering: _isRecoveringRuntime,
                      ),
                    ),
                  if (resolvedPlayback?.isLive != true &&
                      showExpandedOverlay &&
                      playerValue?.isBuffering == true &&
                      _errorMessage == null)
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
      ),
    );
  }

  Future<void> _initializePlayer() async {
    if (!mounted || _isDisposing) {
      return;
    }

    final playbackContext = _activePlaybackContext;

    if (playbackContext == null) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Contexto de playback ausente.';
        _audioTracks = const [];
        _subtitleTracks = const [];
        _qualityProfiles = const [];
        _hasRuntimeAudioTrackSelection = false;
        _selectedAudioTrackId = null;
        _selectedSubtitleTrack = null;
        _selectedQualityProfile = null;
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
      _interactionMessage = null;
      _statusMessage = wasRecoveringRuntime
          ? widget.recoveryPolicy.runtimeRecoveryLabel(
              attemptNumber: _runtimeRecoveryAttempts,
              isLive: playbackContext.isLive,
            )
          : null;
      _showPlaybackUi = true;
    });
    unawaited(_setKeepScreenOn(false));

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
        _audioTracks = const [];
        _subtitleTracks = const [];
        _qualityProfiles = const [];
        _hasRuntimeAudioTrackSelection = false;
        _selectedAudioTrackId = null;
        _selectedSubtitleTrack = null;
        _selectedQualityProfile = null;
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
        _interactionMessageTimer?.cancel();
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
        final runtimeContract = resolvedPlayback.runtimeContract;
        final formatHint = _resolveVideoFormatHint(runtimeContract.sourceType);
        final sanitizedRuntimeUri = _summarizeTelemetryUri(runtimeContract.uri);

        _recordTelemetry(
          PlayerTelemetryEvent(
            type: PlayerTelemetryEventType.playbackRuntimePrepared,
            message: 'Prepared playback runtime contract',
            attributes: <String, Object?>{
              'uri': sanitizedRuntimeUri,
              'isLive': resolvedPlayback.isLive,
              'sourceType': runtimeContract.sourceType.name,
              'formatHint': formatHint?.name,
              'httpHeaderCount': runtimeContract.httpHeaders.length,
              'httpHeaderNames': runtimeContract.httpHeaders.keys.join(','),
              'userAgent': runtimeContract.userAgent,
            },
          ),
        );

        final controller = VideoPlayerController.networkUrl(
          runtimeContract.uri,
          formatHint: formatHint,
          httpHeaders: runtimeContract.httpHeaders,
        );
        attemptController = controller;
        await controller.initialize();
        final resumePosition = playbackContext.resumePosition;
        if (resumePosition != null &&
            resolvedPlayback.canResume &&
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
        final targetVolume = _isMuted
            ? 0.0
            : _lastVolumeBeforeMute.clamp(0.0, 1.0);
        await controller.setVolume(targetVolume);
        final runtimeAudioState = await _loadRuntimeAudioState(
          controller,
          resolvedPlayback,
        );
        final runtimeResolvedPlayback = runtimeAudioState.playback;
        final manifest = runtimeResolvedPlayback.manifest;
        final subtitleTracks = _subtitleTrackLabels(manifest);
        final qualityProfiles = _qualityProfileLabels(manifest);
        controller.addListener(_handleControllerUpdate);
        await controller.play();

        if (!mounted ||
            _isDisposing ||
            requestVersion != _initializationVersion) {
          await controller.dispose();
          return;
        }

        setState(() {
          _resolvedPlayback = runtimeResolvedPlayback;
          _controller = controller;
          _isInitializing = false;
          _errorMessage = null;
          _statusMessage = null;
          _interactionMessage = null;
          _isRecoveringRuntime = false;
          _volumeLevel = targetVolume;
          _isMuted = targetVolume <= 0;
          _audioTracks = runtimeAudioState.tracks;
          _subtitleTracks = subtitleTracks;
          _qualityProfiles = qualityProfiles;
          _hasRuntimeAudioTrackSelection = runtimeAudioState.selectionAvailable;
          _selectedAudioTrackId = runtimeAudioState.selectedTrackId;
          _selectedSubtitleTrack = _resolveDefaultSubtitleTrackLabel(manifest);
          _selectedQualityProfile = _resolveDefaultQualityProfileLabel(
            manifest,
          );
        });
        _recordTelemetry(
          PlayerTelemetryEvent(
            type: PlayerTelemetryEventType.playbackRuntimeReady,
            message: 'Initialized playback runtime contract',
            attributes: <String, Object?>{
              'uri': sanitizedRuntimeUri,
              'isLive': resolvedPlayback.isLive,
              'sourceType': runtimeContract.sourceType.name,
              'formatHint': formatHint?.name,
              'httpHeaderCount': runtimeContract.httpHeaders.length,
              'userAgent': runtimeContract.userAgent,
            },
          ),
        );
        _runtimeRecoveryAttempts = 0;
        _lastKnownPlaying = _isPlaybackActive(controller.value);
        _revealPlaybackUi(autoHide: _lastKnownPlaying);
        unawaited(_syncKeepScreenOn());
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
      _interactionMessage = null;
      _audioTracks = const [];
      _subtitleTracks = const [];
      _qualityProfiles = const [];
      _hasRuntimeAudioTrackSelection = false;
      _selectedAudioTrackId = null;
      _selectedSubtitleTrack = null;
      _selectedQualityProfile = null;
      _errorMessage = Failure.fromError(
        lastError ?? StateError('Falha ao carregar stream.'),
      ).message;
    });
    unawaited(_syncKeepScreenOn());
  }

  void _handleControllerUpdate() {
    final controller = _controller;
    if (!mounted || _isDisposing || controller == null) {
      return;
    }

    final value = controller.value;
    if (value.hasError) {
      final issue = _runtimeIssueClassifier.classify(
        value.errorDescription ?? 'Falha ao carregar o stream no player.',
      );
      _recordTelemetry(
        PlayerTelemetryEvent(
          type: PlayerTelemetryEventType.runtimeIssueClassified,
          message: 'Runtime issue classificada no player.',
          attributes: <String, Object?>{
            'kind': issue.kind.name,
            'retryable': issue.retryable,
            'code': issue.code,
            'raw': value.errorDescription,
          },
        ),
      );
      unawaited(_attemptRuntimeRecovery(issue));
      return;
    }
    _trackBufferingRecovery(value);

    final playbackActive = _isPlaybackActive(value);
    if (playbackActive != _lastKnownPlaying) {
      _lastKnownPlaying = playbackActive;
      if (playbackActive) {
        _inactivePlaybackTimer?.cancel();
        _scheduleOverlayHide();
      } else {
        _scheduleOverlayRevealForStableInactivity();
      }
    }

    unawaited(_syncKeepScreenOn());
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
    final issue = const PlayerRuntimeIssue(
      kind: PlayerRuntimeIssueKind.timeout,
      message: 'Buffering prolongado ao reproduzir o stream.',
      retryable: true,
      code: 'buffering_stall',
    );
    _recordTelemetry(
      PlayerTelemetryEvent(
        type: PlayerTelemetryEventType.runtimeIssueClassified,
        message: 'Buffering stall classificado como timeout.',
        attributes: <String, Object?>{
          'kind': issue.kind.name,
          'retryable': issue.retryable,
          'code': issue.code,
        },
      ),
    );
    unawaited(_attemptRuntimeRecovery(issue));
  }

  Future<void> _attemptRuntimeRecovery(PlayerRuntimeIssue issue) async {
    final playbackContext = _activePlaybackContext;
    if (!mounted ||
        _isDisposing ||
        _isInitializing ||
        _isRecoveringRuntime ||
        playbackContext == null) {
      _recordTelemetry(
        PlayerTelemetryEvent(
          type: PlayerTelemetryEventType.runtimeRecoverySkipped,
          message: 'Recuperacao ignorada por estado invalido.',
          attributes: <String, Object?>{
            'kind': issue.kind.name,
            'retryable': issue.retryable,
            'isInitializing': _isInitializing,
            'isRecoveringRuntime': _isRecoveringRuntime,
          },
        ),
      );
      return;
    }

    final recoveryStartedAt = _lastRuntimeRecoveryStartedAt;
    if (recoveryStartedAt != null) {
      final elapsed = DateTime.now().difference(recoveryStartedAt);
      if (elapsed < const Duration(seconds: 45)) {
        _recordTelemetry(
          PlayerTelemetryEvent(
            type: PlayerTelemetryEventType.runtimeRecoverySkipped,
            message: 'Recuperacao ignorada por cooldown ativo.',
            attributes: <String, Object?>{
              'kind': issue.kind.name,
              'elapsedMs': elapsed.inMilliseconds,
              'cooldownMs': 45000,
              'code': issue.code,
            },
          ),
        );
        return;
      }
    }

    if (!issue.retryable) {
      if (_errorMessage == null) {
        setState(() {
          _statusMessage = null;
          _errorMessage = issue.message;
          _showPlaybackUi = true;
        });
      }
      _recordTelemetry(
        PlayerTelemetryEvent(
          type: PlayerTelemetryEventType.runtimeRecoverySkipped,
          message: 'Recuperacao ignorada: issue nao retryable.',
          attributes: <String, Object?>{
            'kind': issue.kind.name,
            'code': issue.code,
          },
        ),
      );
      return;
    }

    final nextAttempt = widget.recoveryPolicy.nextRuntimeRecoveryAttempt(
      _runtimeRecoveryAttempts,
    );
    if (nextAttempt == null) {
      if (_errorMessage == null) {
        setState(() {
          _statusMessage = null;
          _errorMessage = issue.message;
          _showPlaybackUi = true;
        });
      }
      _recordTelemetry(
        PlayerTelemetryEvent(
          type: PlayerTelemetryEventType.runtimeRecoveryLimitReached,
          message: 'Limite de recuperacao em runtime atingido.',
          attributes: <String, Object?>{
            'kind': issue.kind.name,
            'attempts': _runtimeRecoveryAttempts,
            'max': widget.recoveryPolicy.maxRuntimeRecoveries,
            'code': issue.code,
          },
        ),
      );
      return;
    }

    _runtimeRecoveryAttempts = nextAttempt;
    final currentAttempt = nextAttempt;
    _lastRuntimeRecoveryStartedAt = DateTime.now();
    _interactionMessageTimer?.cancel();
    setState(() {
      _showPlaybackUi = true;
      _isRecoveringRuntime = true;
      _errorMessage = null;
      _interactionMessage = null;
      _statusMessage = widget.recoveryPolicy.runtimeRecoveryLabel(
        attemptNumber: currentAttempt,
        isLive: playbackContext.isLive,
      );
    });

    final retryDelay = widget.recoveryPolicy.runtimeRecoveryDelayForIssue(
      issueKind: issue.kind,
      attemptNumber: currentAttempt,
    );
    _recordTelemetry(
      PlayerTelemetryEvent(
        type: PlayerTelemetryEventType.runtimeRecoveryScheduled,
        message: 'Recuperacao runtime agendada.',
        attributes: <String, Object?>{
          'kind': issue.kind.name,
          'attempt': currentAttempt,
          'delayMs': retryDelay.inMilliseconds,
          'code': issue.code,
        },
      ),
    );

    await Future<void>.delayed(retryDelay);
    if (!mounted || _isDisposing) {
      return;
    }
    await _initializePlayer();
  }

  void _persistPlaybackProgress({bool force = false}) {
    final controller = _controller;
    final resolved = _resolvedPlayback;
    if (controller == null || resolved == null || !resolved.canResume) {
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
      seriesId: contextData.seriesId,
    );
    unawaited(_playbackHistoryController.upsert(entry));
  }

  Future<void> _togglePlayPause() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    _revealPlaybackUi();

    final wasPlaying = controller.value.isPlaying;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    unawaited(_syncKeepScreenOn());
    _showInteractionMessage(wasPlaying ? 'Pausado' : 'Reproduzindo');
  }

  Future<void> _syncKeepScreenOn() async {
    if (!mounted || _isDisposing) {
      await _setKeepScreenOn(false);
      return;
    }

    final shouldKeepScreenOn = shouldKeepMobileLiveScreenAwake(
      isTv: DeviceLayout.of(context).isTv,
      playbackContext: _resolvedPlayback?.context ?? _activePlaybackContext,
      playerValue: _controller?.value,
    );
    await _setKeepScreenOn(shouldKeepScreenOn);
  }

  Future<void> _setKeepScreenOn(bool enabled) async {
    if (_keepScreenOnEnabled == enabled) {
      return;
    }

    try {
      await _displayControlChannel.invokeMethod<void>('setKeepScreenOn', {
        'enabled': enabled,
      });
      _keepScreenOnEnabled = enabled;
    } on PlatformException {
      // Ignore platform failures to avoid breaking playback controls.
    } on MissingPluginException {
      // Ignore absent platform hook on non-Android targets.
    }
  }

  Future<void> _toggleMute() async {
    _revealPlaybackUi();

    if (_isMuted) {
      final restoredVolume = _lastVolumeBeforeMute <= 0
          ? 1.0
          : _lastVolumeBeforeMute.clamp(0.0, 1.0);
      await _setVolumeLevel(restoredVolume);
      _showInteractionMessage('Som ativado');
      return;
    }

    await _setVolumeLevel(0);
    _showInteractionMessage('Sem som');
  }

  Future<void> _setVolumeLevel(double level) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final clamped = level.clamp(0.0, 1.0);
    final previousVolume = _volumeLevel;
    if (clamped > 0) {
      _lastVolumeBeforeMute = clamped;
    } else if (previousVolume > 0) {
      _lastVolumeBeforeMute = previousVolume;
    }

    await controller.setVolume(clamped);
    if (!mounted || _isDisposing) {
      return;
    }

    setState(() {
      _volumeLevel = clamped;
      _isMuted = clamped <= 0;
    });
  }

  Future<void> _initializeBrightnessControl() async {
    try {
      final brightness = await _screenBrightnessController.application;
      if (!mounted || _isDisposing) {
        return;
      }
      setState(() {
        _hasBrightnessControl = true;
        _screenBrightnessLevel = brightness.clamp(0.12, 1.0);
      });
    } on Exception {
      if (!mounted || _isDisposing) {
        return;
      }
      setState(() {
        _hasBrightnessControl = false;
      });
    }
  }

  Future<void> _setScreenBrightnessLevel(double level) async {
    final clamped = level.clamp(0.12, 1.0);
    try {
      await _screenBrightnessController.setApplicationScreenBrightness(clamped);
      if (!mounted || _isDisposing) {
        return;
      }
      setState(() {
        _hasBrightnessControl = true;
        _didOverrideScreenBrightness = true;
        _screenBrightnessLevel = clamped;
      });
    } on Exception {
      if (!mounted || _isDisposing) {
        return;
      }
      setState(() {
        _hasBrightnessControl = false;
      });
      _showInteractionMessage('Brilho indisponivel');
    }
  }

  Future<void> _restoreApplicationBrightness() async {
    try {
      await _screenBrightnessController.resetApplicationScreenBrightness();
    } on Exception {
      // Ignore brightness reset failures to avoid impacting player teardown.
    }
  }

  void _showMobileInlineUtility(
    _MobileInlineUtility utility, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted || _isDisposing) {
      return;
    }

    _revealPlaybackUi(autoHide: false);
    _mobileInlineUtilityTimer?.cancel();

    if (_activeMobileInlineUtility != utility) {
      setState(() {
        _activeMobileInlineUtility = utility;
      });
    }

    _mobileInlineUtilityTimer = Timer(duration, () {
      if (!mounted || _isDisposing) {
        return;
      }
      setState(() {
        _activeMobileInlineUtility = _MobileInlineUtility.none;
      });
      _scheduleOverlayHide();
    });
  }

  void _beginMobileVerticalGesture(
    _MobileInlineUtility utility,
    double startY,
  ) {
    _mobileVerticalGestureStartY = startY;
    _mobileVerticalGestureStartLevel =
        utility == _MobileInlineUtility.brightness
        ? _screenBrightnessLevel
        : _volumeLevel;
    _showMobileInlineUtility(utility, duration: const Duration(seconds: 2));
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    if (!mounted || _isDisposing || widget.previewState != null) {
      return;
    }
    final layout = DeviceLayout.of(context);
    if (layout.isTv) {
      return;
    }

    final width = MediaQuery.sizeOf(context).width;
    final startX = details.localPosition.dx;
    if (startX <= width / 2) {
      if (!_hasBrightnessControl) {
        return;
      }
      _beginMobileVerticalGesture(
        _MobileInlineUtility.brightness,
        details.localPosition.dy,
      );
      return;
    }

    _beginMobileVerticalGesture(
      _MobileInlineUtility.volume,
      details.localPosition.dy,
    );
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (!mounted || _isDisposing || widget.previewState != null) {
      return;
    }
    final startY = _mobileVerticalGestureStartY;
    final activeUtility = _activeMobileInlineUtility;
    if (startY == null || activeUtility == _MobileInlineUtility.none) {
      return;
    }

    final layout = DeviceLayout.of(context);
    final gestureRange = (layout.height * 0.55).clamp(220.0, 420.0);
    final delta = (startY - details.localPosition.dy) / gestureRange;
    final nextLevel = (_mobileVerticalGestureStartLevel + delta).clamp(
      0.0,
      1.0,
    );

    if (activeUtility == _MobileInlineUtility.brightness) {
      final brightnessLevel = nextLevel.clamp(0.12, 1.0);
      unawaited(_setScreenBrightnessLevel(brightnessLevel));
      return;
    }

    unawaited(_setVolumeLevel(nextLevel));
  }

  void _finishMobileVerticalGesture() {
    if (_activeMobileInlineUtility == _MobileInlineUtility.none) {
      return;
    }
    _mobileVerticalGestureStartY = null;
    _showMobileInlineUtility(
      _activeMobileInlineUtility,
      duration: const Duration(milliseconds: 900),
    );
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    _finishMobileVerticalGesture();
  }

  void _handleVerticalDragCancel() {
    _finishMobileVerticalGesture();
  }

  Future<void> _selectAudioTrack() async {
    final controller = _controller;
    final resolvedPlayback = _resolvedPlayback;
    final tracks = _audioTracks;
    if (!_canSelectAudioTrack ||
        controller == null ||
        resolvedPlayback == null ||
        tracks.isEmpty) {
      _showInteractionMessage('Audio indisponivel');
      return;
    }

    final options = buildAudioSelectionOptions(tracks);
    final selectedTrackId = await _chooseSelectionOption(
      title: 'Faixa de audio',
      options: options,
      currentSelectionId:
          _selectedAudioTrackId ?? _resolveSelectedAudioTrackId(tracks),
    );
    if (!mounted || selectedTrackId == null) {
      return;
    }
    _recordTelemetry(
      PlayerTelemetryEvent(
        type: PlayerTelemetryEventType.selectionRequested,
        message: 'Selecao de audio solicitada.',
        attributes: <String, Object?>{
          'selectedTrackId': selectedTrackId,
          'supports': _hasRuntimeAudioTrackSelection,
        },
      ),
    );
    final track = _resolveAudioTrackById(tracks, selectedTrackId);
    if (track == null) {
      _showInteractionMessage('Faixa de audio invalida');
      return;
    }

    final result = await _playerEngineAdapter.selectAudioTrack(
      playback: resolvedPlayback,
      track: track,
      controller: controller,
    );
    if (!mounted || _isDisposing) {
      return;
    }
    if (result == PlayerSelectionApplyResult.applied) {
      final runtimeAudioState = await _loadRuntimeAudioState(
        controller,
        resolvedPlayback,
      );
      if (!mounted || _isDisposing) {
        return;
      }
      setState(() {
        _resolvedPlayback = runtimeAudioState.playback;
        _audioTracks = runtimeAudioState.tracks;
        _hasRuntimeAudioTrackSelection = runtimeAudioState.selectionAvailable;
        _selectedAudioTrackId = runtimeAudioState.selectedTrackId;
      });
    }
    final selectedLabel = _displayAudioTrackLabel(track, tracks);
    _showInteractionMessage(_audioSelectionMessage(selectedLabel, result));
    _recordTelemetry(
      PlayerTelemetryEvent(
        type: PlayerTelemetryEventType.selectionResult,
        message: 'Selecao de audio concluida.',
        attributes: <String, Object?>{
          'selectedTrackId': selectedTrackId,
          'selectedLabel': selectedLabel,
          'result': result.name,
        },
      ),
    );
  }

  Future<_RuntimeAudioState> _loadRuntimeAudioState(
    VideoPlayerController controller,
    ResolvedPlayback playback,
  ) async {
    final selectionAvailable = await _playerEngineAdapter
        .isAudioTrackSelectionAvailable(
          playback: playback,
          controller: controller,
        );
    final tracks = selectionAvailable
        ? await _playerEngineAdapter.getAudioTracks(
            playback: playback,
            controller: controller,
          )
        : const <PlaybackTrack>[];
    final manifest = playback.manifest.copyWith(audioTracks: tracks);
    final capabilities = playback.context.capabilities.copyWith(
      hasAudioTracks: tracks.isNotEmpty,
    );
    final context = playback.context.copyWith(
      manifest: manifest,
      capabilities: capabilities,
    );

    return _RuntimeAudioState(
      playback: playback.copyWith(context: context, manifest: manifest),
      tracks: tracks,
      selectionAvailable: selectionAvailable,
      selectedTrackId: _resolveSelectedAudioTrackId(tracks),
    );
  }

  bool get _canSelectAudioTrack =>
      _hasRuntimeAudioTrackSelection && _audioTracks.length > 1;

  String? get _selectedAudioTrackLabel {
    final selectedTrack = _selectedAudioTrack;
    if (selectedTrack == null) {
      return null;
    }

    return _displayAudioTrackLabel(selectedTrack, _audioTracks);
  }

  PlaybackTrack? get _selectedAudioTrack {
    if (_audioTracks.isEmpty) {
      return null;
    }

    final selectedTrackId = _selectedAudioTrackId;
    if (selectedTrackId != null) {
      for (final track in _audioTracks) {
        if (track.id == selectedTrackId) {
          return track;
        }
      }
    }

    for (final track in _audioTracks) {
      if (track.isDefault) {
        return track;
      }
    }

    return _audioTracks.first;
  }

  Future<void> _selectSubtitleTrack() async {
    final tracks = _subtitleTracks;
    if (tracks.isEmpty) {
      _showInteractionMessage('Legendas indisponiveis');
      return;
    }

    final selected = await _chooseTrack(
      title: 'Legendas',
      tracks: tracks,
      currentSelection: _selectedSubtitleTrack,
      allowOff: true,
      helperText: _playerEngineAdapter.supportsSubtitleTrackSelection
          ? null
          : 'A engine atual nao aplica troca de legenda em runtime.',
    );
    if (!mounted || selected == null) {
      return;
    }
    _recordTelemetry(
      PlayerTelemetryEvent(
        type: PlayerTelemetryEventType.selectionRequested,
        message: 'Selecao de legenda solicitada.',
        attributes: <String, Object?>{
          'selected': selected,
          'supports': _playerEngineAdapter.supportsSubtitleTrackSelection,
        },
      ),
    );

    final resolvedPlayback = _resolvedPlayback;
    if (resolvedPlayback == null) {
      _showInteractionMessage('Playback indisponivel');
      return;
    }

    final disableSubtitles = selected == _offTrackLabel;
    PlaybackTrack? track;
    if (!disableSubtitles) {
      track = _resolveTrackByLabel(
        resolvedPlayback.manifest.subtitleTracks,
        selected,
      );
      if (track == null) {
        _showInteractionMessage('Faixa de legenda invalida');
        return;
      }
    }

    setState(() {
      _selectedSubtitleTrack = disableSubtitles ? null : selected;
    });

    final result = await _playerEngineAdapter.selectSubtitleTrack(
      playback: resolvedPlayback,
      track: track,
    );
    if (!mounted || _isDisposing) {
      return;
    }
    _showInteractionMessage(
      _subtitleSelectionMessage(
        selectedLabel: selected,
        disabled: disableSubtitles,
        result: result,
      ),
    );
    _recordTelemetry(
      PlayerTelemetryEvent(
        type: PlayerTelemetryEventType.selectionResult,
        message: 'Selecao de legenda concluida.',
        attributes: <String, Object?>{
          'selected': selected,
          'disabled': disableSubtitles,
          'result': result.name,
        },
      ),
    );
  }

  Future<void> _selectQualityProfile() async {
    final profiles = _qualityProfiles;
    if (profiles.isEmpty) {
      _showInteractionMessage('Qualidade manual indisponivel');
      return;
    }
    final available = [
      if (_supportsAnyQualitySelection) _autoQualityLabel,
      ...profiles,
    ];
    final currentSelection =
        _selectedQualityProfile ??
        (_supportsAnyQualitySelection ? _autoQualityLabel : profiles.first);

    final selected = await _chooseTrack(
      title: 'Qualidade',
      tracks: available,
      currentSelection: currentSelection,
      allowOff: false,
      helperText: _supportsAnyQualitySelection
          ? null
          : 'A engine atual nao aplica troca manual de qualidade.',
    );
    if (!mounted || selected == null) {
      return;
    }
    _recordTelemetry(
      PlayerTelemetryEvent(
        type: PlayerTelemetryEventType.selectionRequested,
        message: 'Selecao de qualidade solicitada.',
        attributes: <String, Object?>{
          'selected': selected,
          'supportsManual': _playerEngineAdapter.supportsManualQualitySelection,
          'supportsAuto': _playerEngineAdapter.supportsAutoQualitySelection,
        },
      ),
    );

    final resolvedPlayback = _resolvedPlayback;
    if (resolvedPlayback == null) {
      _showInteractionMessage('Playback indisponivel');
      return;
    }
    if (selected == _autoQualityLabel) {
      setState(() {
        _selectedQualityProfile = _autoQualityLabel;
      });

      final result = await _playerEngineAdapter.selectAutoQuality(
        playback: resolvedPlayback,
      );
      if (!mounted || _isDisposing) {
        return;
      }
      _showInteractionMessage(_qualityAutoSelectionMessage(result));
      _recordTelemetry(
        PlayerTelemetryEvent(
          type: PlayerTelemetryEventType.selectionResult,
          message: 'Selecao de qualidade auto concluida.',
          attributes: <String, Object?>{
            'selected': selected,
            'result': result.name,
          },
        ),
      );
      return;
    }

    final variant = _resolveVariantByLabel(
      resolvedPlayback.manifest.variants,
      selected,
    );
    if (variant == null) {
      _showInteractionMessage('Perfil de qualidade invalido');
      return;
    }

    setState(() {
      _selectedQualityProfile = selected;
    });

    final result = await _playerEngineAdapter.selectQualityVariant(
      playback: resolvedPlayback,
      variant: variant,
    );
    if (!mounted || _isDisposing) {
      return;
    }
    _showInteractionMessage(_qualitySelectionMessage(selected, result));
    _recordTelemetry(
      PlayerTelemetryEvent(
        type: PlayerTelemetryEventType.selectionResult,
        message: 'Selecao de qualidade manual concluida.',
        attributes: <String, Object?>{
          'selected': selected,
          'result': result.name,
        },
      ),
    );
  }

  Future<String?> _chooseTrack({
    required String title,
    required List<String> tracks,
    required String? currentSelection,
    required bool allowOff,
    String? helperText,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF101826),
      builder: (context) {
        final options = [if (allowOff) _offTrackLabel, ...tracks];
        final effectiveCurrent = allowOff
            ? (currentSelection ?? _offTrackLabel)
            : (currentSelection ?? tracks.first);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (helperText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    helperText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.74),
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                for (final option in options)
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      option,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: option == effectiveCurrent
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                    onTap: () => Navigator.of(context).pop(option),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _chooseSelectionOption({
    required String title,
    required List<PlayerSelectionOption> options,
    required String? currentSelectionId,
    String? helperText,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF101826),
      builder: (context) {
        final effectiveCurrent =
            currentSelectionId ?? (options.isEmpty ? null : options.first.id);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (helperText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    helperText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.74),
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                for (final option in options)
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      option.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: option.id == effectiveCurrent
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                    onTap: () => Navigator.of(context).pop(option.id),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _seekRelative(Duration offset) async {
    final controller = _controller;
    final resolvedPlayback = _resolvedPlayback;

    if (controller == null ||
        resolvedPlayback == null ||
        !resolvedPlayback.canSeek) {
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
    final direction = offset.isNegative ? '-' : '+';
    final seconds = offset.inSeconds.abs();
    _showInteractionMessage('$direction${seconds}s');
  }

  PlayerLiveNavigation? get _liveNavigationWithChannelSwitching {
    final liveNavigation = _activeLiveNavigation;
    if (liveNavigation == null || !liveNavigation.hasChannelNavigation) {
      return null;
    }
    return liveNavigation;
  }

  bool get _canGoToPreviousLiveChannel =>
      _liveNavigationWithChannelSwitching?.previousChannel != null;

  bool get _canGoToNextLiveChannel =>
      _liveNavigationWithChannelSwitching?.nextChannel != null;

  Future<void> _navigateToAdjacentLiveChannel(int offset) async {
    final liveNavigation = _liveNavigationWithChannelSwitching;
    if (liveNavigation == null || _isInitializing || _isRecoveringRuntime) {
      return;
    }

    final targetIndex = liveNavigation.boundedCurrentIndex + offset;
    if (targetIndex < 0 || targetIndex >= liveNavigation.channels.length) {
      return;
    }

    final nextLiveNavigation = liveNavigation.forChannelIndex(targetIndex);
    final nextContext = nextLiveNavigation.playbackContext;
    if (nextContext.itemId == _activePlaybackContext?.itemId) {
      return;
    }

    _persistPlaybackProgress(force: true);
    _lastProgressSaveAt = null;
    _lastSavedPosition = Duration.zero;
    _bufferingSince = null;
    _runtimeRecoveryAttempts = 0;
    _lastRuntimeRecoveryStartedAt = null;

    setState(() {
      _activePlaybackContext = nextContext;
      _activeLiveNavigation = nextLiveNavigation;
      _resolvedPlayback = null;
      _errorMessage = null;
      _statusMessage = null;
      _interactionMessage = null;
      _showPlaybackUi = true;
    });

    await _initializePlayer();
    if (!mounted || _isDisposing) {
      return;
    }

    final positionLabel =
        '${targetIndex + 1}/${nextLiveNavigation.channels.length}';
    _showInteractionMessage('$positionLabel • ${nextContext.title}');
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (!mounted || _isDisposing || widget.previewState != null) {
      return;
    }
    final layout = DeviceLayout.of(context);
    if (layout.isTv) {
      return;
    }
    final velocity = details.primaryVelocity;
    if (velocity == null || velocity.abs() < 280) {
      return;
    }
    if (velocity.isNegative) {
      unawaited(_navigateToAdjacentLiveChannel(1));
    } else {
      unawaited(_navigateToAdjacentLiveChannel(-1));
    }
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (!mounted || _isDisposing || widget.previewState != null) {
      return false;
    }
    if (event is! KeyDownEvent) {
      return false;
    }
    final key = event.logicalKey;

    final overlayWasHidden = !_showPlaybackUi;
    _revealPlaybackUi();
    final canNavigateLiveOnThisKey =
        (_isLeftKey(key) && _canGoToPreviousLiveChannel) ||
        (_isRightKey(key) && _canGoToNextLiveChannel);
    if (overlayWasHidden && !canNavigateLiveOnThisKey) {
      return true;
    }

    if (_isInitializing) {
      return false;
    }

    if (_errorMessage != null) {
      if (_isActivationKey(key)) {
        unawaited(_initializePlayer());
        return true;
      }
      return false;
    }

    if (_isDirectPlayPauseKey(key)) {
      unawaited(_togglePlayPause());
      return true;
    }

    if (_isMuteKey(key)) {
      unawaited(_toggleMute());
      return true;
    }

    if (_isLeftKey(key) && _canGoToPreviousLiveChannel) {
      unawaited(_navigateToAdjacentLiveChannel(-1));
      return true;
    }

    if (_isRightKey(key) && _canGoToNextLiveChannel) {
      unawaited(_navigateToAdjacentLiveChannel(1));
      return true;
    }

    final resolved = _resolvedPlayback;
    if (resolved == null || !resolved.canSeek) {
      return false;
    }

    if (_isLeftKey(key)) {
      unawaited(_seekRelative(const Duration(seconds: -10)));
      return true;
    }

    if (_isRightKey(key)) {
      unawaited(_seekRelative(const Duration(seconds: 10)));
      return true;
    }

    return false;
  }

  void _revealPlaybackUi({bool autoHide = true}) {
    if (!mounted || widget.previewState != null) {
      return;
    }

    _inactivePlaybackTimer?.cancel();
    final allowAutoHide =
        autoHide && !_shouldKeepOverlayVisibleForCurrentLayout();

    if (!_showPlaybackUi) {
      setState(() {
        _showPlaybackUi = true;
      });
    }

    if (allowAutoHide) {
      _scheduleOverlayHide();
    } else {
      _overlayHideTimer?.cancel();
    }
  }

  void _scheduleOverlayHide() {
    _overlayHideTimer?.cancel();
    if (_shouldKeepOverlayVisibleForCurrentLayout()) {
      if (!_showPlaybackUi) {
        setState(() {
          _showPlaybackUi = true;
        });
      }
      return;
    }

    final controller = _controller;
    final canHide =
        !_isInitializing &&
        _errorMessage == null &&
        _statusMessage == null &&
        _interactionMessage == null &&
        controller != null &&
        controller.value.isInitialized &&
        _isPlaybackActive(controller.value);

    if (!canHide) {
      return;
    }

    _overlayHideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _isDisposing) {
        return;
      }
      setState(() {
        _showPlaybackUi = false;
        _activeMobileInlineUtility = _MobileInlineUtility.none;
      });
    });
  }

  _PlayerOverlayVisibility _resolveOverlayVisibility({
    required DeviceLayout layout,
    required ResolvedPlayback? resolvedPlayback,
    required VideoPlayerValue? playerValue,
    required bool hasReadyVideo,
    required _PlayerStreamMetrics? streamMetrics,
  }) {
    if (_shouldShowExpandedOverlay(layout: layout, playerValue: playerValue)) {
      return _PlayerOverlayVisibility.expanded;
    }

    return _PlayerOverlayVisibility.hidden;
  }

  bool _shouldShowExpandedOverlay({
    required DeviceLayout layout,
    required VideoPlayerValue? playerValue,
  }) {
    if (widget.previewState != null) {
      return true;
    }

    return _showPlaybackUi ||
        _isInitializing ||
        _errorMessage != null ||
        _statusMessage != null ||
        _interactionMessage != null ||
        !_isPlaybackActive(playerValue);
  }

  bool _isPlaybackActive(VideoPlayerValue? value) {
    if (value == null || !value.isInitialized) {
      return false;
    }
    return value.isPlaying || value.isBuffering;
  }

  bool _shouldKeepOverlayVisibleForCurrentLayout() {
    if (!mounted) {
      return false;
    }
    final layout = DeviceLayout.of(context);
    return !layout.isTv &&
        _activeMobileInlineUtility != _MobileInlineUtility.none;
  }

  void _scheduleOverlayRevealForStableInactivity() {
    _inactivePlaybackTimer?.cancel();
    final controller = _controller;
    final canSchedule =
        !_isInitializing &&
        _errorMessage == null &&
        controller != null &&
        controller.value.isInitialized;
    if (!canSchedule) {
      return;
    }

    _inactivePlaybackTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted || _isDisposing) {
        return;
      }
      if (_isPlaybackActive(_controller?.value)) {
        return;
      }
      _revealPlaybackUi(autoHide: false);
    });
  }

  void _showInteractionMessage(String message) {
    if (!mounted || _isDisposing) {
      return;
    }

    final layout = DeviceLayout.of(context);
    if (!layout.isTv && (message == 'Pausado' || message == 'Reproduzindo')) {
      return;
    }

    _interactionMessageTimer?.cancel();
    setState(() {
      _interactionMessage = message;
    });

    _interactionMessageTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || _isDisposing) {
        return;
      }
      setState(() {
        _interactionMessage = null;
      });
      _scheduleOverlayHide();
    });
  }

  void _recordTelemetry(PlayerTelemetryEvent event) {
    _playerTelemetrySink.record(event);
  }

  bool get _supportsAnyQualitySelection {
    return _playerEngineAdapter.supportsManualQualitySelection ||
        _playerEngineAdapter.supportsAutoQualitySelection;
  }

  bool _isActivationKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA;
  }

  bool _isDirectPlayPauseKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.mediaPlayPause;
  }

  bool _isLeftKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowLeft;
  }

  bool _isRightKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowRight;
  }

  Future<void> _enterPlayerImmersiveMode() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } on Exception {
      // Ignore platform/UI mode failures to avoid breaking playback.
    }
  }

  Future<void> _restoreDefaultSystemUiMode() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } on Exception {
      // Ignore platform/UI mode failures during teardown.
    }
  }

  bool _isMuteKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.keyM ||
        key == LogicalKeyboardKey.audioVolumeMute;
  }

  Future<void> _handleBackNavigation() async {
    if (!mounted || _isDisposing) {
      return;
    }
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go('/home');
  }

  Future<bool> _handleRouteBackNavigation() async {
    await _handleBackNavigation();
    return false;
  }
}

VideoFormat? _resolveVideoFormatHint(PlaybackSourceType sourceType) {
  return switch (sourceType) {
    PlaybackSourceType.hls => VideoFormat.hls,
    PlaybackSourceType.dash => VideoFormat.dash,
    PlaybackSourceType.progressive => VideoFormat.other,
    PlaybackSourceType.unknown => null,
  };
}

String _summarizeTelemetryUri(Uri uri) {
  final host = uri.host.trim().isEmpty ? 'unknown-host' : uri.host;
  final pathSegments = uri.pathSegments.where((segment) => segment.isNotEmpty);
  final lastSegment = pathSegments.isEmpty ? 'unknown' : pathSegments.last;
  final scheme = uri.scheme.trim().isEmpty ? 'unknown' : uri.scheme;
  return '$scheme://$host/.../$lastSegment';
}

bool shouldKeepMobileLiveScreenAwake({
  required bool isTv,
  required PlaybackContext? playbackContext,
  required VideoPlayerValue? playerValue,
}) {
  if (isTv || playbackContext?.isLive != true) {
    return false;
  }
  if (playerValue == null || !playerValue.isInitialized) {
    return false;
  }
  return _isPlaybackValueActive(playerValue);
}

bool _isPlaybackValueActive(VideoPlayerValue? value) {
  if (value == null || !value.isInitialized || value.hasError) {
    return false;
  }
  return value.isPlaying || value.isBuffering;
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

    final playerValue = value!;
    final layout = DeviceLayout.of(context);
    final videoSize = playerValue.size;
    final videoWidth = videoSize.width > 0
        ? videoSize.width
        : ((playerValue.aspectRatio == 0 ? 16 / 9 : playerValue.aspectRatio) *
              1000);
    final videoHeight = videoSize.height > 0 ? videoSize.height : 1000.0;
    final videoStage = SizedBox(
      width: videoWidth,
      height: videoHeight,
      child: VideoPlayer(controller!),
    );

    return ColoredBox(
      color: Colors.black,
      child: layout.isTv
          ? Center(
              child: AspectRatio(
                aspectRatio: playerValue.aspectRatio == 0
                    ? 16 / 9
                    : playerValue.aspectRatio,
                child: VideoPlayer(controller!),
              ),
            )
          : Center(
              child: FittedBox(fit: BoxFit.contain, child: videoStage),
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
    final layout = DeviceLayout.of(context);

    if (!layout.isTv) {
      return IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0x98000000),
                const Color(0x34000000),
                Colors.transparent,
                const Color(0x58000000),
                const Color(0xB8000000),
              ],
              stops: const [0, 0.14, 0.5, 0.78, 1],
            ),
          ),
        ),
      );
    }

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
                  const Color(0xC8000000),
                  const Color(0x78030A16),
                  Colors.transparent,
                  const Color(0xC0101A2A),
                  const Color(0xF0000000),
                ],
                stops: const [0, 0.16, 0.56, 0.82, 1],
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
    if (!layout.isTv) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            layout.pageHorizontalPadding,
            layout.pageTopPadding,
            layout.pageHorizontalPadding,
            0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OverlayBackButton(
                interactiveKey: AppTestKeys.playerCloseButton,
                testId: AppTestKeys.playerCloseButtonId,
                autofocus: true,
                onPressed: onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      shadows: const [
                        Shadow(
                          color: Color(0xB0000000),
                          blurRadius: 8,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isLive) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _OverlayStatusBadge(label: 'AO VIVO'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          layout.pageHorizontalPadding,
          layout.pageTopPadding,
          layout.pageHorizontalPadding,
          0,
        ),
        child: Row(
          children: [
            _OverlayBackButton(
              interactiveKey: AppTestKeys.playerCloseButton,
              testId: AppTestKeys.playerCloseButtonId,
              autofocus: !layout.isTv,
              onPressed: onBack,
            ),
            SizedBox(width: layout.cardSpacing),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: layout.isTv ? 29 : 18,
                  fontWeight: FontWeight.w700,
                  shadows: const [
                    Shadow(
                      color: Color(0xB0000000),
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            if (layout.isTv || isLive)
              _OverlayStatusBadge(label: isLive ? 'AO VIVO' : 'VOD'),
          ],
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
    required this.activeMobileInlineUtility,
    required this.isMuted,
    required this.volumeLevel,
    required this.screenBrightnessLevel,
    required this.hasBrightnessControl,
    required this.selectedAudioTrack,
    required this.showAudioTrackSelector,
    required this.showSubtitleTrackSelector,
    required this.selectedSubtitleTrack,
    required this.showQualitySelector,
    required this.selectedQualityProfile,
    required this.onSelectAudioTrack,
    required this.onSelectSubtitleTrack,
    required this.onSelectQualityProfile,
    required this.onTogglePlayback,
    required this.onSeekBackward,
    required this.onSeekForward,
    required this.canGoToPreviousChannel,
    required this.canGoToNextChannel,
    required this.onPreviousChannel,
    required this.onNextChannel,
    this.qualityLabel,
    this.liveLatencyLabel,
  });

  final VideoPlayerController controller;
  final ResolvedPlayback resolvedPlayback;
  final DeviceLayout layout;
  final _MobileInlineUtility activeMobileInlineUtility;
  final bool isMuted;
  final double volumeLevel;
  final double screenBrightnessLevel;
  final bool hasBrightnessControl;
  final String? selectedAudioTrack;
  final bool showAudioTrackSelector;
  final bool showSubtitleTrackSelector;
  final String? selectedSubtitleTrack;
  final bool showQualitySelector;
  final String? selectedQualityProfile;
  final VoidCallback onSelectAudioTrack;
  final VoidCallback onSelectSubtitleTrack;
  final VoidCallback onSelectQualityProfile;
  final VoidCallback onTogglePlayback;
  final VoidCallback onSeekBackward;
  final VoidCallback onSeekForward;
  final bool canGoToPreviousChannel;
  final bool canGoToNextChannel;
  final VoidCallback onPreviousChannel;
  final VoidCallback onNextChannel;
  final String? qualityLabel;
  final String? liveLatencyLabel;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final isSeekable = resolvedPlayback.canSeek;
    final isLive = resolvedPlayback.isLive;
    final isPlaying = value.isPlaying;
    final total = value.duration;
    final current = value.position;
    final remaining = total - current;
    final mobileHorizontalInset = layout.isTv
        ? layout.pageHorizontalPadding
        : 0.0;
    final showLiveChannelControls =
        isLive && (canGoToPreviousChannel || canGoToNextChannel);
    final showAudioChip = !isLive && showAudioTrackSelector;
    final showSubtitleChip = showSubtitleTrackSelector;
    final showQualityChip = showQualitySelector;
    final showInfoChips =
        qualityLabel != null || (isLive && liveLatencyLabel != null);
    final showSecondaryPanel =
        showAudioChip || showSubtitleChip || showQualityChip || showInfoChips;

    if (!layout.isTv) {
      return _buildMobileOverlay(
        context,
        isSeekable: isSeekable,
        isLive: isLive,
        isPlaying: isPlaying,
        total: total,
        current: current,
        remaining: remaining,
        showLiveChannelControls: showLiveChannelControls,
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            mobileHorizontalInset,
            0,
            mobileHorizontalInset,
            layout.pageBottomPadding,
          ),
          child: _PlayerDeckContainer(
            layout: layout,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isSeekable) ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: layout.isTv ? 980 : double.infinity,
                    ),
                    child: _TimelinePanel(
                      layout: layout,
                      child: Column(
                        children: [
                          _PlayerTimeline(
                            controller: controller,
                            layout: layout,
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
                  ),
                ],
                SizedBox(height: layout.isTv ? 14 : 10),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: layout.isTv ? 980 : double.infinity,
                  ),
                  child: _ControlsPanel(
                    layout: layout,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSeekable)
                          PlayerControlButton(
                            icon: Icons.replay_10_rounded,
                            label: '-10s',
                            onPressed: onSeekBackward,
                            kind: PlayerControlButtonKind.secondary,
                          ),
                        if (showLiveChannelControls && canGoToPreviousChannel)
                          PlayerControlButton(
                            icon: Icons.skip_previous_rounded,
                            label: 'Canal anterior',
                            onPressed: onPreviousChannel,
                            kind: PlayerControlButtonKind.secondary,
                          ),
                        if (isSeekable || showLiveChannelControls)
                          const SizedBox(width: 10),
                        PlayerControlButton(
                          icon: isPlaying
                              ? Icons.pause_circle_rounded
                              : Icons.play_circle_rounded,
                          label: isPlaying ? 'Pausar' : 'Reproduzir',
                          onPressed: onTogglePlayback,
                          autofocus: layout.isTv,
                          kind: PlayerControlButtonKind.primary,
                          prominent: true,
                        ),
                        if (isSeekable || showLiveChannelControls)
                          const SizedBox(width: 10),
                        if (isSeekable)
                          PlayerControlButton(
                            icon: Icons.forward_10_rounded,
                            label: '+10s',
                            onPressed: onSeekForward,
                            kind: PlayerControlButtonKind.secondary,
                          ),
                        if (showLiveChannelControls && canGoToNextChannel)
                          PlayerControlButton(
                            icon: Icons.skip_next_rounded,
                            label: 'Proximo canal',
                            onPressed: onNextChannel,
                            kind: PlayerControlButtonKind.secondary,
                          ),
                      ],
                    ),
                  ),
                ),
                if (showSecondaryPanel) ...[
                  SizedBox(height: layout.isTv ? 10 : 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: layout.isTv ? 980 : double.infinity,
                    ),
                    child: _SecondaryControlsPanel(
                      layout: layout,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showAudioChip ||
                              showSubtitleChip ||
                              showQualityChip ||
                              showInfoChips)
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: layout.isTv ? 12 : 8,
                              runSpacing: layout.isTv ? 12 : 8,
                              children: [
                                if (showAudioChip)
                                  _OverlayActionChip(
                                    icon: Icons.audiotrack_rounded,
                                    label: 'Audio',
                                    detail: selectedAudioTrack,
                                    onPressed: onSelectAudioTrack,
                                  ),
                                if (showSubtitleChip)
                                  _OverlayActionChip(
                                    icon: Icons.subtitles_rounded,
                                    label: 'Legenda',
                                    detail: selectedSubtitleTrack ?? 'Off',
                                    onPressed: onSelectSubtitleTrack,
                                  ),
                                if (showQualityChip)
                                  _OverlayActionChip(
                                    icon: Icons.high_quality_rounded,
                                    label: 'Qualidade',
                                    detail: selectedQualityProfile,
                                    onPressed: onSelectQualityProfile,
                                  ),
                                if (qualityLabel != null)
                                  _OverlayInfoChip(
                                    icon: Icons.hd_rounded,
                                    label: qualityLabel!,
                                  ),
                                if (isLive && liveLatencyLabel != null)
                                  _OverlayInfoChip(
                                    icon: Icons.speed_rounded,
                                    label: liveLatencyLabel!,
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
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

  Widget _buildMobileOverlay(
    BuildContext context, {
    required bool isSeekable,
    required bool isLive,
    required bool isPlaying,
    required Duration total,
    required Duration current,
    required Duration remaining,
    required bool showLiveChannelControls,
  }) {
    final resolutionLabel = qualityLabel ?? selectedQualityProfile;
    final showInlineUtility =
        activeMobileInlineUtility != _MobileInlineUtility.none;
    final sideUtilityInset = (layout.width * 0.12).clamp(72.0, 180.0);
    final utilityTop = (layout.height * 0.28).clamp(
      layout.pageTopPadding + 120.0,
      layout.pageTopPadding + 220.0,
    );
    final utilityBottom = (layout.height * 0.24).clamp(
      layout.pageBottomPadding + 110.0,
      layout.pageBottomPadding + 180.0,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          layout.pageHorizontalPadding,
          0,
          layout.pageHorizontalPadding,
          layout.pageBottomPadding,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showInlineUtility)
              Positioned(
                left:
                    activeMobileInlineUtility == _MobileInlineUtility.brightness
                    ? sideUtilityInset
                    : null,
                right: activeMobileInlineUtility == _MobileInlineUtility.volume
                    ? sideUtilityInset
                    : null,
                top: utilityTop,
                bottom: utilityBottom,
                child: Align(
                  alignment:
                      activeMobileInlineUtility ==
                          _MobileInlineUtility.brightness
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: _MobileEdgeLevelOverlay(
                    alignment: activeMobileInlineUtility,
                    icon:
                        activeMobileInlineUtility == _MobileInlineUtility.volume
                        ? (isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded)
                        : Icons.brightness_6_rounded,
                    value:
                        activeMobileInlineUtility == _MobileInlineUtility.volume
                        ? volumeLevel
                        : screenBrightnessLevel,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSeekable)
                      _MobileTimelineCard(
                        layout: layout,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PlayerTimeline(
                              controller: controller,
                              layout: layout,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  _formatDuration(current),
                                  style: _timeStyle(context, layout),
                                ),
                                const Spacer(),
                                Text(
                                  '-${_formatDuration(remaining.isNegative ? Duration.zero : remaining)}',
                                  style: _timeStyle(context, layout).copyWith(
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDuration(total),
                                  style: _timeStyle(context, layout).copyWith(
                                    color: Colors.white.withValues(alpha: 0.58),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (isSeekable) const SizedBox(height: 10),
                    _MobileBottomDock(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MobileHeroControls(
                            isPlaying: isPlaying,
                            showLiveChannelControls: showLiveChannelControls,
                            canGoToPreviousChannel: canGoToPreviousChannel,
                            canGoToNextChannel: canGoToNextChannel,
                            onTogglePlayback: onTogglePlayback,
                            onPreviousChannel: onPreviousChannel,
                            onNextChannel: onNextChannel,
                          ),
                          if (resolutionLabel != null &&
                              resolutionLabel.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _MobileInfoBadge(
                              icon: Icons.hd_rounded,
                              label: resolutionLabel,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

class _OverlayBackButton extends StatelessWidget {
  const _OverlayBackButton({
    required this.onPressed,
    required this.autofocus,
    this.testId,
    this.interactiveKey,
  });

  final VoidCallback onPressed;
  final bool autofocus;
  final String? testId;
  final Key? interactiveKey;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);

    return TvFocusable(
      autofocus: autofocus,
      testId: testId,
      interactiveKey: interactiveKey,
      onPressed: onPressed,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.symmetric(
            horizontal: layout.isTv ? 16 : 12,
            vertical: layout.isTv ? 12 : 9,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: focused ? 0.42 : 0.26),
            borderRadius: BorderRadius.circular(layout.isTv ? 20 : 16),
            border: Border.all(
              color: focused
                  ? Colors.white.withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.2),
              width: focused ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: layout.isTv ? 24 : 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Sair',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverlayStatusBadge extends StatelessWidget {
  const _OverlayStatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isLive = label == 'AO VIVO';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isLive ? const Color(0xCCFF5E69) : Colors.white24,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isLive
              ? const Color(0xFFFFA8AF)
              : Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _SecondaryControlsPanel extends StatelessWidget {
  const _SecondaryControlsPanel({required this.layout, required this.child});

  final DeviceLayout layout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(layout.isTv ? 26 : 20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: layout.isTv ? 14 : 10,
          vertical: layout.isTv ? 12 : 10,
        ),
        child: child,
      ),
    );
  }
}

class _OverlayActionChip extends StatelessWidget {
  const _OverlayActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.detail,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);

    return TvFocusable(
      onPressed: onPressed,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.symmetric(
            horizontal: layout.isTv ? 14 : 12,
            vertical: layout.isTv ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: focused ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(layout.isTv ? 18 : 15),
            border: Border.all(
              color: focused
                  ? Colors.white.withValues(alpha: 0.72)
                  : Colors.white.withValues(alpha: 0.18),
              width: focused ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.92),
                size: layout.isTv ? 19 : 17,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (detail != null && detail!.trim().isNotEmpty) ...[
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: layout.isTv ? 220 : 120,
                  ),
                  child: Text(
                    detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w600,
                    ),
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

class _OverlayInfoChip extends StatelessWidget {
  const _OverlayInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: layout.isTv ? 10 : 9,
          vertical: layout.isTv ? 8 : 7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.78),
              size: layout.isTv ? 16 : 14,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileTimelineCard extends StatelessWidget {
  const _MobileTimelineCard({required this.layout, required this.child});

  final DeviceLayout layout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: child,
    );
  }
}

class _MobileHeroControls extends StatelessWidget {
  const _MobileHeroControls({
    required this.isPlaying,
    required this.showLiveChannelControls,
    required this.canGoToPreviousChannel,
    required this.canGoToNextChannel,
    required this.onTogglePlayback,
    required this.onPreviousChannel,
    required this.onNextChannel,
  });

  final bool isPlaying;
  final bool showLiveChannelControls;
  final bool canGoToPreviousChannel;
  final bool canGoToNextChannel;
  final VoidCallback onTogglePlayback;
  final VoidCallback onPreviousChannel;
  final VoidCallback onNextChannel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showLiveChannelControls && canGoToPreviousChannel)
          _MobileNavigationButton(
            icon: Icons.skip_previous_rounded,
            label: 'Anterior',
            onPressed: onPreviousChannel,
          ),
        if (showLiveChannelControls && canGoToPreviousChannel)
          const SizedBox(width: 10),
        _MobileHeroPlayButton(
          isPlaying: isPlaying,
          onPressed: onTogglePlayback,
        ),
        if (showLiveChannelControls && canGoToNextChannel)
          const SizedBox(width: 10),
        if (showLiveChannelControls && canGoToNextChannel)
          _MobileNavigationButton(
            icon: Icons.skip_next_rounded,
            label: 'Proximo',
            onPressed: onNextChannel,
          ),
      ],
    );
  }
}

class _MobileHeroPlayButton extends StatelessWidget {
  const _MobileHeroPlayButton({
    required this.isPlaying,
    required this.onPressed,
  });

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onPressed: onPressed,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: focused
                  ? [const Color(0xFFFF9B50), const Color(0xFFFF6A1A)]
                  : [const Color(0xFFFF8A3D), const Color(0xFFFF5E0E)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: focused
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.22),
              width: focused ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xAAFF6A1A,
                ).withValues(alpha: focused ? 0.44 : 0.28),
                blurRadius: focused ? 30 : 22,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                color: Colors.black.withValues(alpha: 0.82),
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                isPlaying ? 'Pausar' : 'Reproduzir',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileNavigationButton extends StatelessWidget {
  const _MobileNavigationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onPressed: onPressed,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: focused ? 0.28 : 0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: focused
                  ? Colors.white.withValues(alpha: 0.52)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.92), size: 20),
            ],
          ),
        );
      },
    );
  }
}

class _MobileBottomDock extends StatelessWidget {
  const _MobileBottomDock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: child,
    );
  }
}

class _MobileInfoBadge extends StatelessWidget {
  const _MobileInfoBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.54), size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.56),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileEdgeLevelOverlay extends StatelessWidget {
  const _MobileEdgeLevelOverlay({
    required this.alignment,
    required this.icon,
    required this.value,
  });

  final _MobileInlineUtility alignment;
  final IconData icon;
  final double value;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    final isLeft = alignment == _MobileInlineUtility.brightness;
    const indicatorHeight = 136.0;
    final fillAlignment = Alignment.lerp(
      Alignment.bottomCenter,
      Alignment.topCenter,
      clampedValue,
    )!;

    return Padding(
      padding: EdgeInsets.only(left: isLeft ? 6 : 0, right: isLeft ? 0 : 6),
      child: SizedBox(
        width: 42,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 8),
            Container(
              width: 8,
              height: indicatorHeight,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment: fillAlignment,
                child: Container(
                  width: 8,
                  height: indicatorHeight * clampedValue,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A3D),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveSignalBadge extends StatelessWidget {
  const _LiveSignalBadge({
    required this.qualityLabel,
    required this.liveLatencyLabel,
    required this.isBuffering,
    required this.recovering,
  });

  final String qualityLabel;
  final String? liveLatencyLabel;
  final bool isBuffering;
  final bool recovering;

  @override
  Widget build(BuildContext context) {
    final statusLabel = recovering
        ? 'Reconectando'
        : (isBuffering ? 'Instavel' : 'Estavel');

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: recovering
              ? [const Color(0xCC2A1C3A), const Color(0xAA1B1028)]
              : [const Color(0xCC0F1D30), const Color(0xAA0A141F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: recovering
              ? const Color(0xFFBC8FFF)
              : Colors.white.withValues(alpha: 0.26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBuffering || recovering) ...[
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              'LIVE • $qualityLabel',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              statusLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.84),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (liveLatencyLabel != null) ...[
              const SizedBox(width: 8),
              Text(
                liveLatencyLabel!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                ),
              ),
            ],
          ],
        ),
      ),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        layout.isTv ? 6 : 2,
        layout.isTv ? 8 : 6,
        layout.isTv ? 6 : 2,
        layout.isTv ? 6 : 2,
      ),
      child: child,
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({required this.layout, required this.child});

  final DeviceLayout layout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: layout.isTv ? 8 : 6,
        horizontal: layout.isTv ? 4 : 2,
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: layout.isTv ? 4 : 2,
        vertical: layout.isTv ? 6 : 4,
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

class _InteractionToast extends StatelessWidget {
  const _InteractionToast({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD0E1624),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Text(
          message,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.94),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
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

const _offTrackLabel = 'Desativadas';
const _autoQualityLabel = 'Auto';

class _PlayerStreamMetrics {
  const _PlayerStreamMetrics({
    required this.qualityLabel,
    required this.liveLatencyLabel,
  });

  final String qualityLabel;
  final String? liveLatencyLabel;
}

class _RuntimeAudioState {
  const _RuntimeAudioState({
    required this.playback,
    required this.tracks,
    required this.selectionAvailable,
    required this.selectedTrackId,
  });

  final ResolvedPlayback playback;
  final List<PlaybackTrack> tracks;
  final bool selectionAvailable;
  final String? selectedTrackId;
}

@immutable
class PlayerSelectionOption {
  const PlayerSelectionOption({required this.id, required this.label});

  final String id;
  final String label;
}

@visibleForTesting
List<PlayerSelectionOption> buildAudioSelectionOptions(
  List<PlaybackTrack> tracks,
) {
  final baseLabelCounts = <String, int>{};
  for (final track in tracks) {
    final baseLabel = _audioTrackLabel(track);
    baseLabelCounts[baseLabel] = (baseLabelCounts[baseLabel] ?? 0) + 1;
  }

  return tracks
      .map(
        (track) => PlayerSelectionOption(
          id: track.id,
          label: _displayAudioTrackLabel(
            track,
            tracks,
            baseLabelCounts: baseLabelCounts,
          ),
        ),
      )
      .toList(growable: false);
}

List<String> _subtitleTrackLabels(PlaybackManifest manifest) {
  return manifest.subtitleTracks
      .map((track) => track.label.trim())
      .where((label) => label.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

List<String> _qualityProfileLabels(PlaybackManifest manifest) {
  return manifest.variants
      .map((variant) => variant.label.trim())
      .where((label) => label.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

String? _resolveSelectedAudioTrackId(List<PlaybackTrack> tracks) {
  if (tracks.isEmpty) {
    return null;
  }

  for (final track in tracks) {
    if (track.isDefault) {
      return track.id;
    }
  }

  return tracks.first.id;
}

String? _resolveDefaultSubtitleTrackLabel(PlaybackManifest manifest) {
  return _resolveDefaultTrackLabel(manifest.subtitleTracks);
}

String? _resolveDefaultTrackLabel(List<PlaybackTrack> tracks) {
  if (tracks.isEmpty) {
    return null;
  }

  for (final track in tracks) {
    if (track.isDefault && track.label.trim().isNotEmpty) {
      return track.label.trim();
    }
  }

  for (final track in tracks) {
    final label = track.label.trim();
    if (label.isNotEmpty) {
      return label;
    }
  }

  return null;
}

String? _resolveDefaultQualityProfileLabel(PlaybackManifest manifest) {
  if (manifest.variants.isEmpty) {
    return null;
  }

  for (final variant in manifest.variants) {
    if (variant.isAuto) {
      return _autoQualityLabel;
    }
  }

  for (final variant in manifest.variants) {
    if (variant.isDefault && variant.label.trim().isNotEmpty) {
      return variant.label.trim();
    }
  }

  for (final variant in manifest.variants) {
    final label = variant.label.trim();
    if (label.isNotEmpty) {
      return label;
    }
  }

  return null;
}

PlaybackTrack? _resolveTrackByLabel(List<PlaybackTrack> tracks, String label) {
  final normalized = label.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }

  for (final track in tracks) {
    if (track.label.trim().toLowerCase() == normalized) {
      return track;
    }
  }

  return null;
}

PlaybackTrack? _resolveAudioTrackById(List<PlaybackTrack> tracks, String id) {
  for (final track in tracks) {
    if (track.id == id) {
      return track;
    }
  }

  return null;
}

String _audioTrackLabel(PlaybackTrack track) {
  final label = track.label.trim();
  if (label.isNotEmpty) {
    return label;
  }

  final languageCode = track.languageCode?.trim();
  if (languageCode != null && languageCode.isNotEmpty) {
    return languageCode.toUpperCase();
  }

  final codec = track.codec?.trim();
  if (codec != null && codec.isNotEmpty) {
    return codec.toUpperCase();
  }

  return 'Faixa ${track.id}';
}

String _displayAudioTrackLabel(
  PlaybackTrack track,
  List<PlaybackTrack> tracks, {
  Map<String, int>? baseLabelCounts,
}) {
  final baseLabel = _audioTrackLabel(track);
  final counts =
      baseLabelCounts ??
      <String, int>{
        for (final item in tracks)
          _audioTrackLabel(item): tracks
              .where(
                (candidate) =>
                    _audioTrackLabel(candidate) == _audioTrackLabel(item),
              )
              .length,
      };

  if ((counts[baseLabel] ?? 0) <= 1) {
    return baseLabel;
  }

  return '$baseLabel • ${track.id}';
}

PlaybackVariant? _resolveVariantByLabel(
  List<PlaybackVariant> variants,
  String label,
) {
  final normalized = label.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }

  for (final variant in variants) {
    if (variant.label.trim().toLowerCase() == normalized) {
      return variant;
    }
  }

  return null;
}

String _audioSelectionMessage(
  String selected,
  PlayerSelectionApplyResult result,
) {
  return switch (result) {
    PlayerSelectionApplyResult.applied => 'Audio aplicado: $selected',
    PlayerSelectionApplyResult.notSupported =>
      'Audio marcado: $selected (aplicacao pendente)',
    PlayerSelectionApplyResult.failed =>
      'Falha ao aplicar audio. Marcado: $selected',
  };
}

String _subtitleSelectionMessage({
  required String selectedLabel,
  required bool disabled,
  required PlayerSelectionApplyResult result,
}) {
  if (disabled) {
    return switch (result) {
      PlayerSelectionApplyResult.applied => 'Legendas desativadas',
      PlayerSelectionApplyResult.notSupported =>
        'Legendas desativadas (aplicacao pendente)',
      PlayerSelectionApplyResult.failed => 'Falha ao desativar legendas.',
    };
  }

  return switch (result) {
    PlayerSelectionApplyResult.applied => 'Legenda aplicada: $selectedLabel',
    PlayerSelectionApplyResult.notSupported =>
      'Legenda marcada: $selectedLabel (aplicacao pendente)',
    PlayerSelectionApplyResult.failed =>
      'Falha ao aplicar legenda. Marcada: $selectedLabel',
  };
}

String _qualitySelectionMessage(
  String selected,
  PlayerSelectionApplyResult result,
) {
  return switch (result) {
    PlayerSelectionApplyResult.applied => 'Qualidade aplicada: $selected',
    PlayerSelectionApplyResult.notSupported =>
      'Qualidade marcada: $selected (aplicacao pendente)',
    PlayerSelectionApplyResult.failed =>
      'Falha ao aplicar qualidade. Marcada: $selected',
  };
}

String _qualityAutoSelectionMessage(PlayerSelectionApplyResult result) {
  return switch (result) {
    PlayerSelectionApplyResult.applied => 'Qualidade automatica aplicada',
    PlayerSelectionApplyResult.notSupported =>
      'Qualidade automatica marcada (aplicacao pendente)',
    PlayerSelectionApplyResult.failed => 'Falha ao ativar qualidade automatica',
  };
}

_PlayerStreamMetrics _deriveStreamMetrics(
  VideoPlayerValue value, {
  required bool isLive,
}) {
  final width = value.size.width.round();
  final height = value.size.height.round();
  final quality = _qualityLabel(height);
  final qualityLabel = width > 0 && height > 0
      ? '$quality • ${width}x$height'
      : quality;

  String? liveLatencyLabel;
  if (isLive) {
    final duration = value.duration;
    final position = value.position;
    if (duration > Duration.zero &&
        position >= Duration.zero &&
        duration >= position) {
      final lag = duration - position;
      final lagSeconds = lag.inSeconds.clamp(0, 120);
      liveLatencyLabel = 'Atraso ~${lagSeconds}s';
    }
  }

  return _PlayerStreamMetrics(
    qualityLabel: qualityLabel,
    liveLatencyLabel: liveLatencyLabel,
  );
}

String _qualityLabel(int height) {
  if (height <= 0) {
    return 'AUTO';
  }
  if (height >= 2160) {
    return '4K';
  }
  if (height >= 1440) {
    return 'QHD';
  }
  if (height >= 1080) {
    return 'FHD';
  }
  if (height >= 720) {
    return 'HD';
  }
  if (height >= 480) {
    return 'SD';
  }
  return 'LD';
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
