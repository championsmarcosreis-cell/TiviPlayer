import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../domain/engine/player_engine_adapter.dart';
import '../../domain/entities/playback_manifest.dart';
import '../../domain/entities/resolved_playback.dart';
import '../../domain/observability/player_telemetry.dart';

class AndroidChannelPlayerEngineAdapter implements PlayerEngineAdapter {
  AndroidChannelPlayerEngineAdapter({
    MethodChannel? channel,
    PlayerTelemetrySink? telemetrySink,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _telemetrySink = telemetrySink {
    _capabilitiesFuture = _loadCapabilities();
  }

  static const _channelName = 'tiviplayer/player_engine_android';

  final MethodChannel _channel;
  final PlayerTelemetrySink? _telemetrySink;

  late final Future<void> _capabilitiesFuture;
  bool _supportsAudioTrackSelection = false;
  bool _supportsSubtitleTrackSelection = false;
  bool _supportsManualQualitySelection = false;
  bool _supportsAutoQualitySelection = false;

  @override
  bool get supportsAudioTrackSelection => _supportsAudioTrackSelection;

  @override
  bool get supportsSubtitleTrackSelection => _supportsSubtitleTrackSelection;

  @override
  bool get supportsManualQualitySelection => _supportsManualQualitySelection;

  @override
  bool get supportsAutoQualitySelection => _supportsAutoQualitySelection;

  @override
  Future<bool> isAudioTrackSelectionAvailable({
    required ResolvedPlayback playback,
    VideoPlayerController? controller,
  }) async {
    await _capabilitiesFuture;
    if (controller != null && controller.value.isInitialized) {
      final isAvailable = controller.isAudioTrackSupportAvailable();
      _supportsAudioTrackSelection = isAvailable;
      return isAvailable;
    }
    return _supportsAudioTrackSelection;
  }

  @override
  Future<List<PlaybackTrack>> getAudioTracks({
    required ResolvedPlayback playback,
    VideoPlayerController? controller,
  }) async {
    await _capabilitiesFuture;
    if (controller == null || !controller.value.isInitialized) {
      return const <PlaybackTrack>[];
    }

    final isAvailable = controller.isAudioTrackSupportAvailable();
    _supportsAudioTrackSelection = isAvailable;
    if (!isAvailable) {
      return const <PlaybackTrack>[];
    }

    try {
      final tracks = await controller.getAudioTracks();
      return tracks
          .map(_mapAudioTrack)
          .where((track) => track.id.trim().isNotEmpty)
          .toList(growable: false);
    } on MissingPluginException {
      _supportsAudioTrackSelection = false;
      return const <PlaybackTrack>[];
    } on PlatformException {
      return const <PlaybackTrack>[];
    } on StateError {
      return const <PlaybackTrack>[];
    }
  }

  @override
  Future<PlayerSelectionApplyResult> selectAudioTrack({
    required ResolvedPlayback playback,
    required PlaybackTrack track,
    VideoPlayerController? controller,
  }) async {
    await _capabilitiesFuture;
    if (controller != null && controller.value.isInitialized) {
      final isAvailable = controller.isAudioTrackSupportAvailable();
      _supportsAudioTrackSelection = isAvailable;
      if (!isAvailable) {
        return PlayerSelectionApplyResult.notSupported;
      }

      try {
        await controller.selectAudioTrack(track.id);
        _recordSelectionResult(
          'selectAudioTrack',
          PlayerSelectionApplyResult.applied,
          raw: <String, Object?>{'mode': 'video_player', 'trackId': track.id},
        );
        return PlayerSelectionApplyResult.applied;
      } on MissingPluginException {
        return PlayerSelectionApplyResult.notSupported;
      } on PlatformException catch (error) {
        _recordSelectionResult(
          'selectAudioTrack',
          PlayerSelectionApplyResult.failed,
          raw: <String, Object?>{
            'mode': 'video_player',
            'code': error.code,
            'message': error.message,
          },
        );
        return PlayerSelectionApplyResult.failed;
      } on StateError catch (error) {
        _recordSelectionResult(
          'selectAudioTrack',
          PlayerSelectionApplyResult.failed,
          raw: <String, Object?>{
            'mode': 'video_player',
            'message': error.message,
          },
        );
        return PlayerSelectionApplyResult.failed;
      }
    }

    return _invokeSelection('selectAudioTrack', <String, Object?>{
      ..._playbackPayload(playback),
      'track': _trackPayload(track),
    });
  }

  @override
  Future<PlayerSelectionApplyResult> selectSubtitleTrack({
    required ResolvedPlayback playback,
    PlaybackTrack? track,
  }) async {
    await _capabilitiesFuture;
    return _invokeSelection('selectSubtitleTrack', <String, Object?>{
      ..._playbackPayload(playback),
      'track': track == null ? null : _trackPayload(track),
      'disabled': track == null,
    });
  }

  @override
  Future<PlayerSelectionApplyResult> selectQualityVariant({
    required ResolvedPlayback playback,
    required PlaybackVariant variant,
  }) async {
    await _capabilitiesFuture;
    return _invokeSelection('selectQualityVariant', <String, Object?>{
      ..._playbackPayload(playback),
      'variant': _variantPayload(variant),
      'auto': false,
    });
  }

  @override
  Future<PlayerSelectionApplyResult> selectAutoQuality({
    required ResolvedPlayback playback,
  }) async {
    await _capabilitiesFuture;
    return _invokeSelection('setAutoQuality', <String, Object?>{
      ..._playbackPayload(playback),
      'auto': true,
    });
  }

  Future<void> _loadCapabilities() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getCapabilities',
      );

      final capabilities = raw ?? const <String, dynamic>{};
      _supportsAudioTrackSelection =
          capabilities['audioTrackSelection'] == true;
      _supportsSubtitleTrackSelection =
          capabilities['subtitleTrackSelection'] == true;
      _supportsManualQualitySelection =
          capabilities['manualQualitySelection'] == true;
      _supportsAutoQualitySelection =
          capabilities['autoQualitySelection'] == true;
    } on MissingPluginException {
      _supportsAudioTrackSelection = false;
      _supportsSubtitleTrackSelection = false;
      _supportsManualQualitySelection = false;
      _supportsAutoQualitySelection = false;
    } on PlatformException {
      _supportsAudioTrackSelection = false;
      _supportsSubtitleTrackSelection = false;
      _supportsManualQualitySelection = false;
      _supportsAutoQualitySelection = false;
    }
  }

  Future<PlayerSelectionApplyResult> _invokeSelection(
    String method,
    Map<String, Object?> payload,
  ) async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        method,
        payload,
      );
      final status = (raw?['status'] as String? ?? '').toLowerCase();
      final result = switch (status) {
        'applied' => PlayerSelectionApplyResult.applied,
        'not_supported' => PlayerSelectionApplyResult.notSupported,
        _ => PlayerSelectionApplyResult.failed,
      };
      _recordSelectionResult(method, result, raw: raw);
      return result;
    } on MissingPluginException {
      _recordSelectionResult(
        method,
        PlayerSelectionApplyResult.notSupported,
        raw: const <String, Object?>{'reason': 'missing_plugin'},
      );
      return PlayerSelectionApplyResult.notSupported;
    } on PlatformException catch (error) {
      _recordSelectionResult(
        method,
        PlayerSelectionApplyResult.failed,
        raw: <String, Object?>{'code': error.code, 'message': error.message},
      );
      return PlayerSelectionApplyResult.failed;
    }
  }

  PlaybackTrack _mapAudioTrack(VideoAudioTrack track) {
    return PlaybackTrack(
      id: track.id,
      type: PlaybackTrackType.audio,
      label: _resolveRuntimeAudioTrackLabel(track),
      languageCode: track.language,
      codec: track.codec,
      isDefault: track.isSelected,
    );
  }

  String _resolveRuntimeAudioTrackLabel(VideoAudioTrack track) {
    final label = track.label?.trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }

    final language = track.language?.trim();
    if (language != null && language.isNotEmpty) {
      return language.toUpperCase();
    }

    final codec = track.codec?.trim();
    if (codec != null && codec.isNotEmpty) {
      return codec.toUpperCase();
    }

    return 'Faixa ${track.id}';
  }

  Map<String, Object?> _playbackPayload(ResolvedPlayback playback) {
    return <String, Object?>{
      'uri': playback.uri.toString(),
      'isLive': playback.isLive,
    };
  }

  Map<String, Object?> _trackPayload(PlaybackTrack track) {
    return <String, Object?>{
      'id': track.id,
      'type': track.type.name,
      'label': track.label,
      'languageCode': track.languageCode,
      'codec': track.codec,
      'isDefault': track.isDefault,
      'isForced': track.isForced,
    };
  }

  Map<String, Object?> _variantPayload(PlaybackVariant variant) {
    return <String, Object?>{
      'id': variant.id,
      'label': variant.label,
      'width': variant.width,
      'height': variant.height,
      'bitrateKbps': variant.bitrateKbps,
      'codec': variant.codec,
      'isDefault': variant.isDefault,
      'isAuto': variant.isAuto,
    };
  }

  void _recordSelectionResult(
    String method,
    PlayerSelectionApplyResult result, {
    Map<String, dynamic>? raw,
  }) {
    final sink = _telemetrySink;
    if (sink == null) {
      return;
    }

    sink.record(
      PlayerTelemetryEvent(
        type: PlayerTelemetryEventType.selectionResult,
        message: 'Android channel selection result',
        attributes: <String, Object?>{
          'method': method,
          'result': result.name,
          'raw': raw?.toString(),
        },
      ),
    );
  }
}
