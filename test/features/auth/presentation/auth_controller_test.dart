import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/core/errors/app_exception.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_credentials.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_session.dart';
import 'package:tiviplayer/features/auth/domain/repositories/auth_repository.dart';
import 'package:tiviplayer/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  test('bootstrap autentica quando sessão salva está disponível', () async {
    final repository = _FakeAuthRepository(
      savedSession: XtreamSession.cached(
        const XtreamCredentials(
          baseUrl: 'http://example.com',
          username: 'sergio',
          password: '123456',
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    final state = await _waitForSettledState(container);

    expect(state.status, AuthStatus.authenticated);
    expect(state.session?.credentials.username, 'sergio');
  });

  test('bootstrap cai para unauthenticated quando leitura falha', () async {
    final repository = _FakeAuthRepository(
      readError: const AppException('Falha ao carregar sessão.'),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    final state = await _waitForSettledState(container);

    expect(state.status, AuthStatus.unauthenticated);
    expect(state.errorMessage, 'Falha ao carregar sessão.');
  });
}

Future<AuthState> _waitForSettledState(ProviderContainer container) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    final state = container.read(authControllerProvider);
    if (state.status != AuthStatus.initializing) {
      return state;
    }

    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  fail('AuthController permaneceu em initializing.');
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.savedSession, this.readError});

  final XtreamSession? savedSession;
  final Object? readError;

  @override
  Future<void> clearSession() async {}

  @override
  Future<XtreamSession> login(XtreamCredentials credentials) async {
    throw UnimplementedError();
  }

  @override
  Future<XtreamSession?> readSavedSession() async {
    if (readError != null) {
      throw readError!;
    }

    return savedSession;
  }

  @override
  Future<void> saveSession(XtreamSession session) async {}
}
