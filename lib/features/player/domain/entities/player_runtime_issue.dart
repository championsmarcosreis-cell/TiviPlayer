enum PlayerRuntimeIssueKind {
  network,
  timeout,
  streamUnavailable,
  codec,
  unauthorized,
  unknown,
}

class PlayerRuntimeIssue {
  const PlayerRuntimeIssue({
    required this.kind,
    required this.message,
    this.retryable = true,
    this.code,
  });

  final PlayerRuntimeIssueKind kind;
  final String message;
  final bool retryable;
  final String? code;
}

class PlayerRuntimeIssueClassifier {
  const PlayerRuntimeIssueClassifier();

  PlayerRuntimeIssue classify(String rawMessage) {
    final normalized = rawMessage.trim();
    final lower = normalized.toLowerCase();

    if (_containsAny(lower, const [
      '401',
      '403',
      'unauthorized',
      'forbidden',
    ])) {
      return const PlayerRuntimeIssue(
        kind: PlayerRuntimeIssueKind.unauthorized,
        message: 'Acesso ao stream negado. Verifique credenciais/permissao.',
        retryable: false,
        code: 'unauthorized',
      );
    }

    if (_containsAny(lower, const ['404', '410', 'not found', 'offline'])) {
      return const PlayerRuntimeIssue(
        kind: PlayerRuntimeIssueKind.streamUnavailable,
        message: 'Stream indisponivel no momento.',
        retryable: true,
        code: 'stream_unavailable',
      );
    }

    if (_containsAny(lower, const ['timeout', 'timed out', 'etimedout'])) {
      return const PlayerRuntimeIssue(
        kind: PlayerRuntimeIssueKind.timeout,
        message: 'Tempo de resposta excedido no stream.',
        retryable: true,
        code: 'timeout',
      );
    }

    if (_containsAny(lower, const [
      'socket',
      'network',
      'host',
      'dns',
      'unreachable',
    ])) {
      return const PlayerRuntimeIssue(
        kind: PlayerRuntimeIssueKind.network,
        message: 'Falha de rede ao reproduzir stream.',
        retryable: true,
        code: 'network',
      );
    }

    if (_containsAny(lower, const ['codec', 'decoder', 'format', 'mime'])) {
      return const PlayerRuntimeIssue(
        kind: PlayerRuntimeIssueKind.codec,
        message: 'Formato de midia nao suportado pela engine atual.',
        retryable: false,
        code: 'codec_unsupported',
      );
    }

    return PlayerRuntimeIssue(
      kind: PlayerRuntimeIssueKind.unknown,
      message: normalized.isEmpty
          ? 'Falha desconhecida ao carregar o stream.'
          : normalized,
      retryable: true,
      code: 'unknown',
    );
  }

  bool _containsAny(String value, List<String> terms) {
    for (final term in terms) {
      if (value.contains(term)) {
        return true;
      }
    }
    return false;
  }
}
