import '../../../../core/network/xtream_client.dart';
import '../../domain/entities/xtream_credentials.dart';
import '../models/auth_response_dto.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final XtreamClient _client;

  Future<AuthResponseDto> login(XtreamCredentials credentials) async {
    final response = await _client.fetchObject(
      baseUrl: credentials.normalizedBaseUrl,
      username: credentials.username,
      password: credentials.password,
    );

    return AuthResponseDto.fromApi(response);
  }
}
