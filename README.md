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
- `lib/features/player`: resolução de playback, player e controles mínimos.
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

## Playback URL

O player resolve URLs Xtream sem inventar endpoint adicional:

- Live: `/live/USER/PASS/STREAM_ID.EXT`
- Filmes: `/movie/USER/PASS/STREAM_ID.EXT`
- Episódios: `/series/USER/PASS/STREAM_ID.EXT`

A resolução usa:

- `server_info`/base URL validada na sessão;
- `username` e `password` autenticados;
- `stream_id`/`episode id`;
- `container_extension` vindo do payload real.

Se `container_extension` ou outro dado crítico não vier do provedor, o app mostra erro explícito no player em vez de montar URL insegura.

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
- `AndroidManifest.xml` principal com `android.permission.INTERNET`, `android:usesCleartextTraffic="true"` para provedores Xtream via HTTP, `LEANBACK_LAUNCHER` e touchscreen opcional.
- Player com controles focáveis para D-pad, play/pause e seek apenas onde o conteúdo suporta.
- Layout responsivo para telas menores e TVs largas.

## Limitações atuais

- O player cobre Live, VOD e episódio de série com controles básicos; não há ainda telemetria, retry avançado ou resume persistente.
- Live não força seek artificial; seek básico existe apenas em VOD e episódios.
- Favoritos entraram no detalhe de VOD e Séries, mas ainda não existe tela dedicada de favoritos.
- Persistência de credenciais usa `shared_preferences`; endurecimento de segurança pode entrar depois.
- Não há ingestão de XMLTV no boot.
- iOS ficou fora do escopo.

## Próxima PR sugerida

PR3 sugerida:

- histórico/retomada persistente;
- refinamento de buffering/erros por provedor;
- favoritos com listagem própria;
- cache leve e paginação/virtualização quando necessário;
- smoke tests instrumentados de navegação e playback.
