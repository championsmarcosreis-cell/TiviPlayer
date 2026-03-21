import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/auth/data/models/auth_response_dto.dart';

void main() {
  test('parse account fields from player_api payload', () {
    final dto = AuthResponseDto.fromApi({
      'user_info': {
        'auth': 1,
        'status': 'Active',
        'username': 'user',
        'password': 'pass',
        'message': 'Conta pronta',
        'exp_date': '1798761600',
        'active_cons': '1',
        'max_connections': '3',
        'is_trial': '1',
      },
      'server_info': {
        'url': 'provider.example',
        'port': 8080,
        'server_protocol': 'http',
        'timezone': 'America/Sao_Paulo',
        'time_now': '2026-03-21 12:00:00',
        'timestamp_now': '1798761600',
      },
    });

    expect(dto.userInfo.auth, isTrue);
    expect(dto.userInfo.expirationDate, '1798761600');
    expect(dto.userInfo.activeConnections, 1);
    expect(dto.userInfo.maxConnections, 3);
    expect(dto.userInfo.isTrial, isTrue);
    expect(dto.serverInfo?.timezone, 'America/Sao_Paulo');
    expect(dto.serverInfo?.timeNow, '2026-03-21 12:00:00');
    expect(dto.serverInfo?.timestampNow, '1798761600');
  });
}
