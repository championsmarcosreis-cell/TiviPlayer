import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/live/data/models/live_epg_dto.dart';

void main() {
  test('parse short epg payload with base64 fields and sort by start', () {
    final payload = {
      'epg_listings': [
        {
          'title': base64Encode(utf8.encode('Jornal da Noite')),
          'description': base64Encode(
            utf8.encode('Resumo das noticias do dia'),
          ),
          'start_timestamp': '1700003600',
          'stop_timestamp': '1700007200',
        },
        {
          'title': base64Encode(utf8.encode('Esporte ao Vivo')),
          'description': base64Encode(utf8.encode('Cobertura esportiva')),
          'start_timestamp': '1700000000',
          'stop_timestamp': '1700003600',
        },
      ],
    };

    final parsed = LiveEpgDto.fromApi(payload);

    expect(parsed, hasLength(2));
    expect(parsed.first.title, 'Esporte ao Vivo');
    expect(parsed.last.title, 'Jornal da Noite');
    expect(parsed.first.startAt.isBefore(parsed.last.startAt), isTrue);
    expect(parsed.first.description, 'Cobertura esportiva');
  });

  test('ignore invalid ranges and keep plain text when not base64', () {
    final payload = {
      'epg_listings': [
        {
          'title': 'Programa da Manha',
          'description': 'Descricao comum',
          'start': '2026-03-23 08:00:00',
          'end': '2026-03-23 10:00:00',
        },
        {
          'title': 'Invalido',
          'start': '2026-03-23 11:00:00',
          'end': '2026-03-23 10:00:00',
        },
      ],
    };

    final parsed = LiveEpgDto.fromApi(payload);

    expect(parsed, hasLength(1));
    expect(parsed.first.title, 'Programa da Manha');
    expect(parsed.first.description, 'Descricao comum');
  });
}
