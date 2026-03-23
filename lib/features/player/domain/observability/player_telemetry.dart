enum PlayerTelemetryEventType {
  runtimeIssueClassified,
  runtimeRecoveryScheduled,
  runtimeRecoverySkipped,
  runtimeRecoveryLimitReached,
  selectionRequested,
  selectionResult,
}

class PlayerTelemetryEvent {
  const PlayerTelemetryEvent({
    required this.type,
    required this.message,
    this.attributes = const <String, Object?>{},
  });

  final PlayerTelemetryEventType type;
  final String message;
  final Map<String, Object?> attributes;
}

abstract class PlayerTelemetrySink {
  void record(PlayerTelemetryEvent event);
}
