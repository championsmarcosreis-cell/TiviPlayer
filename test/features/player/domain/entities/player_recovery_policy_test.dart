import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/player/domain/entities/player_recovery_policy.dart';
import 'package:tiviplayer/features/player/domain/entities/player_runtime_issue.dart';

void main() {
  test('calculates initialization attempts and progressive delay', () {
    const policy = PlayerRecoveryPolicy(
      maxInitializationRetries: 3,
      initializationBaseDelay: Duration(milliseconds: 400),
      initializationStepDelay: Duration(milliseconds: 250),
    );

    expect(policy.totalInitializationAttempts, 4);
    expect(
      policy.initializationRetryDelay(0),
      const Duration(milliseconds: 400),
    );
    expect(
      policy.initializationRetryDelay(1),
      const Duration(milliseconds: 650),
    );
    expect(
      policy.initializationRetryDelay(2),
      const Duration(milliseconds: 900),
    );
  });

  test('limits runtime recoveries', () {
    const policy = PlayerRecoveryPolicy(maxRuntimeRecoveries: 2);

    expect(policy.canRecoverRuntime(0), isTrue);
    expect(policy.canRecoverRuntime(1), isTrue);
    expect(policy.canRecoverRuntime(2), isFalse);
    expect(policy.nextRuntimeRecoveryAttempt(0), 1);
    expect(policy.nextRuntimeRecoveryAttempt(1), 2);
    expect(policy.nextRuntimeRecoveryAttempt(2), isNull);
  });

  test('resets runtime attempts for manual initialization only', () {
    const policy = PlayerRecoveryPolicy(maxRuntimeRecoveries: 2);

    expect(
      policy.runtimeAttemptsAfterInitializationStart(
        currentAttempts: 2,
        fromRuntimeRecovery: true,
      ),
      2,
    );
    expect(
      policy.runtimeAttemptsAfterInitializationStart(
        currentAttempts: 2,
        fromRuntimeRecovery: false,
      ),
      0,
    );
  });

  test('builds user-facing recovery labels', () {
    const policy = PlayerRecoveryPolicy(
      maxInitializationRetries: 2,
      maxRuntimeRecoveries: 3,
    );

    expect(
      policy.initializationRetryLabel(attemptNumber: 2, isLive: true),
      'Reconectando sinal ao vivo (2/3)...',
    );
    expect(
      policy.runtimeRecoveryLabel(attemptNumber: 1, isLive: false),
      'Recuperando video (1/3)...',
    );
  });

  test('applies classified runtime backoff by issue type', () {
    const policy = PlayerRecoveryPolicy(
      runtimeRecoveryDelay: Duration(milliseconds: 1000),
    );

    expect(
      policy.runtimeRecoveryDelayForIssue(
        issueKind: PlayerRuntimeIssueKind.network,
        attemptNumber: 1,
      ),
      const Duration(milliseconds: 1300),
    );
    expect(
      policy.runtimeRecoveryDelayForIssue(
        issueKind: PlayerRuntimeIssueKind.streamUnavailable,
        attemptNumber: 2,
      ),
      const Duration(milliseconds: 2280),
    );
  });
}
