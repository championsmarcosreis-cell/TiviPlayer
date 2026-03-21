# TiviPlayer

Base estrutural Flutter para Android Mobile + Android TV consumindo API Xtream-compatible.

## Arquitetura

O projeto foi organizado em camadas por feature:

- `lib/app`: bootstrap, roteamento e tema.
- `lib/core`: rede Xtream, parsing tolerante, storage local e utilitários TV.
- `lib/features/auth`: login, sessão e persistência local de credenciais.
- `lib/features/live`: categorias e canais Live.
- `lib/features/vod`: categorias, listagens e `get_vod_info`.
- `lib/features/series`: categorias, listagens e `get_series_info`.
- `lib/features/player`: contrato/base de playback para PR2.
- `lib/features/favorites`: persistência local pronta para favoritos.
- `lib/shared`: scaffolds e widgets reutilizáveis.

Padrão aplicado:

- `data`: datasources remotos + DTOs + repositories concretos.
- `domain`: entities + repositories abstratos + usecases.
- `presentation`: providers Riverpod + telas.

## Endpoints usados

Todos os endpoints passam por `player_api.php`:

- `player_api.php?username=USER&password=PASS`
- `action=get_live_categories`
- `action=get_live_streams`
- `action=get_live_streams&category_id=X`
- `action=get_vod_categories`
- `action=get_vod_streams`
- `action=get_vod_streams&category_id=X`
- `action=get_vod_info&vod_id=X`
- `action=get_series_categories`
- `action=get_series`
- `action=get_series&category_id=X`
- `action=get_series_info&series=X`
- fallback compatível: alguns provedores exigem `action=get_series_info&series_id=X`

## Credenciais locais

- `api.txt` permanece local e está bloqueado no `.gitignore`.
- XML Android do projeto não deve ser ignorado globalmente; não use regra ampla como `*.xml`.
- O app não lê `api.txt` automaticamente e não embute segredos no build.
- Para usar credenciais reais, abra o app e preencha `Base URL`, `Usuário` e `Senha` na tela de login.
- As credenciais válidas são persistidas localmente via `shared_preferences` para reabertura rápida da sessão.

## Como rodar

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Para análise e testes:

```bash
flutter analyze
flutter test
```

## Compatibilidade TV

- Tema escuro com foco visível.
- Navegação preparada para D-pad com `FocusableActionDetector`.
- `AndroidManifest.xml` principal com `android.permission.INTERNET`, `LEANBACK_LAUNCHER` e touchscreen opcional.
- Layout responsivo para telas menores e TVs largas.

## Limitações atuais

- Player real não foi implementado nesta PR.
- A URL final de mídia não é resolvida para Live/VOD/Séries nesta fase.
- Favoritos têm base pronta, mas ainda não foram expostos na UI.
- Persistência de credenciais usa `shared_preferences`; endurecimento de segurança pode entrar depois.
- Não há ingestão de XMLTV no boot.
- iOS ficou fora do escopo.

## Próxima PR sugerida

PR2 focada em playback:

- resolução de URL de mídia sem inventar contrato fora do servidor usado;
- tela de player com `video_player`;
- controle remoto completo;
- retomada de reprodução;
- favoritos na UI;
- cache leve e paginação/virtualização quando necessário.
