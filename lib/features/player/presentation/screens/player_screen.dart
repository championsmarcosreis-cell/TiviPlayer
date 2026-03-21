import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/playback_context.dart';
import '../../domain/entities/resolved_playback.dart';
import '../providers/player_providers.dart';
import '../widgets/player_control_button.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.playbackContext});

  static const routePath = '/player';

  final PlaybackContext? playbackContext;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  VideoPlayerController? _controller;
  ResolvedPlayback? _resolvedPlayback;
  String? _errorMessage;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_initializePlayer);
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedPlayback = _resolvedPlayback;
    final controller = _controller;
    final playerValue = controller?.value;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PlayerControlButton(
                    icon: Icons.arrow_back_rounded,
                    label: 'Voltar',
                    autofocus: true,
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    resolvedPlayback?.context.title ??
                        widget.playbackContext?.title ??
                        'Player',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  if (resolvedPlayback != null)
                    _PlayerTag(label: resolvedPlayback.isLive ? 'LIVE' : 'VOD'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: playerValue?.isInitialized == true
                        ? playerValue!.aspectRatio
                        : 16 / 9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF101319),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (playerValue?.isInitialized == true)
                              VideoPlayer(controller!)
                            else
                              const SizedBox.shrink(),
                            if (_isInitializing)
                              const _CenteredMessage(
                                child: CircularProgressIndicator(),
                              ),
                            if (!_isInitializing && _errorMessage != null)
                              _CenteredMessage(
                                child: _ErrorPanel(
                                  message: _errorMessage!,
                                  onRetry: _initializePlayer,
                                ),
                              ),
                            if (playerValue?.isBuffering == true &&
                                _errorMessage == null)
                              const Positioned(
                                bottom: 24,
                                right: 24,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(16),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text('Carregando...'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (controller != null &&
                  playerValue != null &&
                  playerValue.isInitialized &&
                  _errorMessage == null)
                _PlayerControls(
                  controller: controller,
                  resolvedPlayback: resolvedPlayback!,
                  onBack: () => context.pop(),
                  onTogglePlayback: _togglePlayPause,
                  onSeekBackward: () =>
                      _seekRelative(const Duration(seconds: -10)),
                  onSeekForward: () =>
                      _seekRelative(const Duration(seconds: 10)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializePlayer() async {
    final playbackContext = widget.playbackContext;

    if (playbackContext == null) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Contexto de playback ausente.';
      });
      return;
    }

    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    _controller?.removeListener(_handleControllerUpdate);
    await _controller?.dispose();
    _controller = null;

    try {
      final session = ref.read(currentSessionProvider);
      final resolvedPlayback = ref
          .read(resolvePlaybackUseCaseProvider)
          .call(session, playbackContext);

      final controller = VideoPlayerController.networkUrl(resolvedPlayback.uri);
      await controller.initialize();
      controller.addListener(_handleControllerUpdate);
      await controller.play();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _resolvedPlayback = resolvedPlayback;
        _controller = controller;
        _isInitializing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _resolvedPlayback = null;
        _isInitializing = false;
        _errorMessage = Failure.fromError(error).message;
      });
    }
  }

  void _handleControllerUpdate() {
    final controller = _controller;
    if (!mounted || controller == null) {
      return;
    }

    final value = controller.value;
    if (value.hasError) {
      setState(() {
        _errorMessage =
            value.errorDescription ?? 'Falha ao carregar o stream no player.';
      });
      return;
    }

    setState(() {});
  }

  Future<void> _togglePlayPause() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

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
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({
    required this.controller,
    required this.resolvedPlayback,
    required this.onBack,
    required this.onTogglePlayback,
    required this.onSeekBackward,
    required this.onSeekForward,
  });

  final VideoPlayerController controller;
  final ResolvedPlayback resolvedPlayback;
  final VoidCallback onBack;
  final VoidCallback onTogglePlayback;
  final VoidCallback onSeekBackward;
  final VoidCallback onSeekForward;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final status = resolvedPlayback.isLive
        ? (value.isPlaying ? 'Ao vivo' : 'Live pausado')
        : '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resolvedPlayback.isSeekable) ...[
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            colors: VideoProgressColors(
              playedColor: Theme.of(context).colorScheme.primary,
              bufferedColor: Colors.white.withValues(alpha: 0.3),
              backgroundColor: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            PlayerControlButton(
              icon: Icons.arrow_back_rounded,
              label: 'Sair',
              onPressed: onBack,
            ),
            PlayerControlButton(
              icon: value.isPlaying
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
              label: value.isPlaying ? 'Pausar' : 'Reproduzir',
              onPressed: onTogglePlayback,
            ),
            if (resolvedPlayback.isSeekable)
              PlayerControlButton(
                icon: Icons.replay_10_rounded,
                label: '-10s',
                onPressed: onSeekBackward,
              ),
            if (resolvedPlayback.isSeekable)
              PlayerControlButton(
                icon: Icons.forward_10_rounded,
                label: '+10s',
                onPressed: onSeekForward,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          status,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
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
}

class _PlayerTag extends StatelessWidget {
  const _PlayerTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 42),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                PlayerControlButton(
                  icon: Icons.refresh_rounded,
                  label: 'Tentar novamente',
                  onPressed: () {
                    onRetry();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(child: child);
  }
}
