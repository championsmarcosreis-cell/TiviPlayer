import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/player/domain/entities/player_runtime_issue.dart';

void main() {
  const classifier = PlayerRuntimeIssueClassifier();

  test('classifies unauthorized errors as non-retryable', () {
    final issue = classifier.classify('HTTP 401 Unauthorized');

    expect(issue.kind, PlayerRuntimeIssueKind.unauthorized);
    expect(issue.retryable, isFalse);
  });

  test('classifies timeout and network errors as retryable', () {
    final timeoutIssue = classifier.classify('request timed out while loading');
    final networkIssue = classifier.classify(
      'socket exception: host unreachable',
    );

    expect(timeoutIssue.kind, PlayerRuntimeIssueKind.timeout);
    expect(timeoutIssue.retryable, isTrue);
    expect(networkIssue.kind, PlayerRuntimeIssueKind.network);
    expect(networkIssue.retryable, isTrue);
  });
}
