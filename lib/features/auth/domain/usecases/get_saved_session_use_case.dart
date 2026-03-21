import '../entities/xtream_session.dart';
import '../repositories/auth_repository.dart';

class GetSavedSessionUseCase {
  const GetSavedSessionUseCase(this._repository);

  final AuthRepository _repository;

  XtreamSession? call() {
    final credentials = _repository.readSavedCredentials();

    if (credentials == null) {
      return null;
    }

    return XtreamSession.cached(credentials);
  }
}
