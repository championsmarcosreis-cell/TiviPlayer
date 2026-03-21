import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/errors/failure.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/xtream_credentials.dart';
import '../../domain/entities/xtream_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_saved_session_use_case.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';

enum AuthStatus { initializing, unauthenticated, authenticating, authenticated }

class AuthState {
  const AuthState({required this.status, this.session, this.errorMessage});

  const AuthState.initializing() : this(status: AuthStatus.initializing);

  const AuthState.unauthenticated({String? errorMessage})
    : this(status: AuthStatus.unauthenticated, errorMessage: errorMessage);

  const AuthState.authenticated(XtreamSession session)
    : this(status: AuthStatus.authenticated, session: session);

  final AuthStatus status;
  final XtreamSession? session;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    XtreamSession? session,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(xtreamClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final getSavedSessionUseCaseProvider = Provider<GetSavedSessionUseCase>((ref) {
  return GetSavedSessionUseCase(ref.watch(authRepositoryProvider));
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final currentSessionProvider = Provider<XtreamSession?>((ref) {
  return ref.watch(authControllerProvider.select((state) => state.session));
});

class AuthController extends Notifier<AuthState> {
  late final GetSavedSessionUseCase _getSavedSessionUseCase;
  late final LoginUseCase _loginUseCase;
  late final LogoutUseCase _logoutUseCase;
  var _bootstrapped = false;

  @override
  AuthState build() {
    _getSavedSessionUseCase = ref.watch(getSavedSessionUseCaseProvider);
    _loginUseCase = ref.watch(loginUseCaseProvider);
    _logoutUseCase = ref.watch(logoutUseCaseProvider);

    if (!_bootstrapped) {
      _bootstrapped = true;
      Future<void>.microtask(bootstrap);
    }

    return const AuthState.initializing();
  }

  Future<void> bootstrap() async {
    final session = _getSavedSessionUseCase();

    if (session == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    state = AuthState.authenticated(session);
  }

  Future<void> login(XtreamCredentials credentials) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      errorMessage: null,
      clearError: true,
    );

    try {
      final session = await _loginUseCase(credentials);
      state = AuthState.authenticated(session);
    } catch (error) {
      state = AuthState.unauthenticated(
        errorMessage: Failure.fromError(error).message,
      );
    }
  }

  Future<void> logout() async {
    await _logoutUseCase();
    state = const AuthState.unauthenticated();
  }
}
