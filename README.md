# TiviPlayer

Base Flutter para Android mobile e Android TV com login, catálogo e playback via API compatível com Xtream Codes.

## PR3

Este PR fecha o recorte de branding, aparência comercial, posters/capas, área de conta e white-label da UI.

### Branding importado do legado

Foram importados somente assets visuais do projeto legado em `C:\clubTivi-main`, sem reaproveitar código, telas ou lógica:

- `assets/branding/app_logo.png`
- `assets/branding/app_icon.png`

Decisão de uso:

- `app_logo.png`: escolhido como lockup principal para splash, login e hero/home por ser a versão mais limpa e legível.
- `app_icon.png`: usado como ícone de apoio no header e como placeholder branded para conteúdos sem imagem válida.

Os assets estão registrados no `pubspec.yaml` via `assets/branding/`.

## O que foi entregue

### Login TV/mobile

- Tela refeita com layout responsivo para mobile e TV.
- Scroll seguro com `SingleChildScrollView`.
- Botão `Entrar` sempre visível e acionável.
- Ordem de foco previsível no formulário.
- Texto e labels neutros, sem expor `Xtream`, URL base ou endpoint técnico na UI normal.

### Posters, capas e thumbnails

As imagens agora usam apenas campos reais já retornados pelo payload:

- Live: `stream_icon`
- VOD list: `stream_icon`
- VOD detail: `cover_big` com fallback para `cover`
- Series list/detail: `cover`

Comportamento:

- URLs inválidas ou ausentes caem em placeholder branded.
- Loading visual de artwork mostra estado intermediário.
- Erro de carregamento não quebra layout.
- Aspect ratio consistente em listas e detalhes.
- Categoria VOD/Live/Séries continua branded por card; os endpoints de categoria não trazem poster útil no contrato atual.

## Conta / Minha assinatura

Os dados abaixo passam a ser integrados do `player_api.php` no login e persistidos localmente com a sessão:

- `status`
- `exp_date`
- `is_trial`
- `active_cons`
- `max_connections`
- `server_info.timezone`
- `server_info.time_now` / `server_info.timestamp_now`
- mensagem retornada no payload, quando existir

Na UI, os dados são exibidos apenas se existirem:

- status da assinatura
- vencimento formatado em linguagem humana
- trial
- conexões ativas
- máximo simultâneo
- fuso horário
- horário do serviço

Não há exibição de JSON cru.

## White-label da UI

Decisão do PR3:

- remover da navegação normal qualquer exposição desnecessária de nome do provedor, base URL, IP, porta e label `Xtream`
- manter o endereço técnico apenas como dado de entrada no login, com linguagem neutra (`Endereço de acesso`)
- não exibir URL/IP na home, nos detalhes ou na tela de conta
- não introduzir gateway, proxy ou endpoint adicional neste PR

## Arquitetura

- `lib/app`: bootstrap, roteamento e tema
- `lib/core`: rede, parsing, formatação e storage local
- `lib/features/auth`: login, sessão e minha assinatura
- `lib/features/live`: categorias e canais ao vivo
- `lib/features/vod`: categorias, listagens e detalhe de filmes
- `lib/features/series`: categorias, listagens e detalhe de séries
- `lib/features/player`: resolução de playback e player atual
- `lib/features/favorites`: favoritos locais
- `lib/shared`: scaffold, branding e widgets reutilizáveis

## Endpoints usados

Todos os endpoints continuam passando somente por `player_api.php`:

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

## Playback

O player continua resolvendo URLs sem endpoint extra:

- Live: `/live/USER/PASS/STREAM_ID.EXT`
- Filmes: `/movie/USER/PASS/STREAM_ID.EXT`
- Episódios: `/series/USER/PASS/STREAM_ID.EXT`

Se faltar dado crítico como `container_extension`, o app mantém erro explícito em vez de montar URL insegura.

## Credenciais locais

- `api.txt` segue local e ignorado pelo Git
- o app não lê `api.txt` automaticamente
- o build não embute segredos
- a sessão local agora persiste também os metadados de conta já retornados no login

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

## Smokes de integração

Smokes existentes:

- `integration_test/playback_smoke_tolerant_test.dart`
- `integration_test/playback_smoke_strict_test.dart`
- `integration_test/android_tv_smoke_test.dart`

Execução com `dart-define-from-file` local ignorado:

```bash
flutter test integration_test/playback_smoke_tolerant_test.dart -d <android_device> --dart-define-from-file=<arquivo_local_ignorado>.json
flutter test integration_test/playback_smoke_strict_test.dart -d <android_device> --dart-define-from-file=<arquivo_local_ignorado>.json
flutter test integration_test/android_tv_smoke_test.dart -d <tv_device_suportado_pelo_flutter> --dart-define-from-file=<arquivo_local_ignorado>.json
```

## Limitações que ficam para PR4

- player premium completo e refinamentos avançados de UX de playback
- proxy/gateway ou qualquer mascaramento além da ocultação de interface
- cache persistente de imagens em disco
- redesign mais amplo fora das telas tocadas neste PR
- launcher/native splash rebrand completo
- favoritos com tela dedicada
