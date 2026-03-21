import '../entities/xtream_credentials.dart';
import '../entities/xtream_session.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<XtreamSession> call(XtreamCredentials credentials) async {
    final session = await _repository.login(credentials);
    await _repository.saveCredentials(credentials);
    return session;
  }
}
