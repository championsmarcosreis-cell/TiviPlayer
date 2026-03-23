class PlayerRecoveryPolicy {
  const PlayerRecoveryPolicy({
    this.maxInitializationRetries = 2,
    this.maxRuntimeRecoveries = 2,
    this.initializationBaseDelay = const Duration(milliseconds: 550),
    this.initializationStepDelay = const Duration(milliseconds: 450),
    this.runtimeRecoveryDelay = const Duration(milliseconds: 800),
    this.bufferingStallThreshold = const Duration(seconds: 12),
  }) : assert(maxInitializationRetries >= 0),
       assert(maxRuntimeRecoveries >= 0);

  final int maxInitializationRetries;
  final int maxRuntimeRecoveries;
  final Duration initializationBaseDelay;
  final Duration initializationStepDelay;
  final Duration runtimeRecoveryDelay;
  final Duration bufferingStallThreshold;

  int get totalInitializationAttempts => maxInitializationRetries + 1;

  Duration initializationRetryDelay(int retryIndex) {
    final safeIndex = retryIndex < 0 ? 0 : retryIndex;
    final totalMilliseconds =
        initializationBaseDelay.inMilliseconds +
        (initializationStepDelay.inMilliseconds * safeIndex);
    return Duration(milliseconds: totalMilliseconds);
  }

  bool canRecoverRuntime(int attemptsPerformed) {
    return attemptsPerformed < maxRuntimeRecoveries;
  }

  int runtimeAttemptsAfterInitializationStart({
    required int currentAttempts,
    required bool fromRuntimeRecovery,
  }) {
    return fromRuntimeRecovery ? currentAttempts : 0;
  }

  int? nextRuntimeRecoveryAttempt(int currentAttempts) {
    if (!canRecoverRuntime(currentAttempts)) {
      return null;
    }

    return currentAttempts + 1;
  }

  String initializationRetryLabel({
    required int attemptNumber,
    required bool isLive,
  }) {
    final streamLabel = isLive ? 'sinal ao vivo' : 'video';
    return 'Reconectando $streamLabel ($attemptNumber/$totalInitializationAttempts)...';
  }

  String runtimeRecoveryLabel({
    required int attemptNumber,
    required bool isLive,
  }) {
    final streamLabel = isLive ? 'sinal ao vivo' : 'video';
    return 'Recuperando $streamLabel ($attemptNumber/$maxRuntimeRecoveries)...';
  }
}
