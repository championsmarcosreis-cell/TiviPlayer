import 'dart:convert';
import 'dart:developer' as developer;

import '../../domain/observability/player_telemetry.dart';

class DebugPlayerTelemetrySink implements PlayerTelemetrySink {
  const DebugPlayerTelemetrySink();

  @override
  void record(PlayerTelemetryEvent event) {
    developer.log(
      event.message,
      name: 'tiviplayer.player',
      error: jsonEncode(<String, Object?>{
        'type': event.type.name,
        ...event.attributes,
      }),
    );
  }
}
