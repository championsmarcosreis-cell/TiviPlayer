# TiviPlayer

Base Flutter para Android mobile e Android TV com login, catálogos e playback via API compatível com Xtream Codes.

## PR4

Estado atual do pacote: PR4 concluído no escopo previsto desta fase.

Foco desta entrega:

- presença visual mais profissional nas telas principais
- melhor encaixe por classe de device
- branding nativo Android coerente com o branding interno
- white-label preservado
- validação operacional com `mobile = emulador Android` e `smart TV = Mi TV Stick`

## O que o PR4 entregou

### Presença visual / polish

As telas tocadas pelo PR4 receberam refinamento de spacing, hierarquia, proporção e leitura:

- login
- splash/home
- catálogos e listas
- detalhes
- conta

Direção aplicada:

- mais respiro visual
- tipografia e alinhamentos mais consistentes
- cards e listas com densidade mais controlada
- leitura a distância melhor em TV
- placeholders e loading states com aparência branded

### Encaixe por classe de device

O app passou a tratar explicitamente classes de layout usadas no PR4 por meio de `DeviceLayout`:

- mobile portrait
- TV 10-foot UI
- TV compacta/fraca

Impacto prático:

- botões críticos continuam visíveis em mobile
- grids e listas ficam menos espremidos
- detalhes e conta mantêm hierarquia melhor
- foco em TV continua previsível

Arquivo-base desse recorte:

- `lib/shared/presentation/layout/device_layout.dart`

### Grid, listas e cards

Foram ajustados:

- tamanhos e paddings de cards da home
- listas/grids de Live, VOD e Séries
- tiles e metadados em catálogo
- cards de detalhe

Objetivo do recorte:

- poster + título + metadados legíveis sem poluir a tela
- ergonomia melhor para navegação por toque e D-pad

### Posters, capas e placeholders

O PR4 manteve o contrato Xtream atual e refinou a apresentação visual:

- fallback branded consistente
- loading visual para artworks
- bordas e moldura mais estáveis
- comportamento compacto sem overflow em cards estreitos

Arquivo relevante:

- `lib/shared/widgets/branded_artwork.dart`

### Conta / home / white-label

A home e a conta foram reorganizadas para melhorar apresentação e hierarquia de:

- status
- vencimento
- trial
- conexões

Regras mantidas:

- sem expor URL/IP/provedor na UI normal
- sem JSON cru
- sem reabrir contrato Xtream além do necessário

### Branding nativo Android

O branding nativo Android foi alinhado ao branding interno do app:

- launcher icon
- round icon
- foreground/background dos ícones adaptativos
- splash logo nativo
- TV banner

Arquivos nativos relevantes:

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/res/mipmap-anydpi-v26/`
- `android/app/src/main/res/mipmap-*/`
- `android/app/src/main/res/drawable/tiviplayer_splash_logo.png`
- `android/app/src/main/res/drawable-nodpi/tv_banner.png`

### TV / foco / ergonomia

O PR4 refinou apenas o que impacta UX real em TV:

- foco visível
- áreas clicáveis
- espaçamento para 10-foot UI
- navegação por D-pad nas telas tocadas por esta fase

Sem reabrir arquitetura de foco.

## Segurança e segredos

- `api.txt` continua local e ignorado pelo Git
- o app não lê `api.txt` automaticamente
- o build não embute segredos por padrão
- o pacote deste PR não inclui segredos locais

## Como rodar

```bash
flutter pub get
flutter analyze
flutter test
```

## Smokes do PR4

Fluxos de validação desta fase:

- `integration_test/pr4_mobile_flow_test.dart`
- `integration_test/pr4_account_flow_test.dart`
- `integration_test/pr4_tv_dpad_flow_test.dart`

Execução com `dart-define-from-file` local ignorado:

```bash
flutter test integration_test/pr4_mobile_flow_test.dart -d <android_emulator> --dart-define-from-file=<arquivo_local_ignorado>.json
flutter test integration_test/pr4_account_flow_test.dart -d <android_device> --dart-define-from-file=<arquivo_local_ignorado>.json
flutter test integration_test/pr4_tv_dpad_flow_test.dart -d <android_tv_device> --dart-define-from-file=<arquivo_local_ignorado>.json
```

Alvos operacionais definidos ao final do PR4:

- mobile: emulador Android
- smart TV: Mi TV Stick

## Validação final do PR4

Checklist fechado nesta fase:

- `flutter analyze` passando
- `flutter test` passando
- smoke mobile principal passando no emulador Android
- smoke de conta isolado passando
- smoke TV passando no Mi TV Stick

## Próxima fase

Fora do escopo entregue neste PR e mantido para a próxima etapa:

- player premium completo
- troca de engine/player
- proxy, gateway ou backend masking real
- cache persistente complexo
- favoritos com tela dedicada
- EPG timeline
- live preview grande
- redesign total do app
- telemetria avançada
