# Fase 2 - Spike técnico do player

Data: 2026-03-23

## Objetivo

Preparar a base para sair do player URL-simples e evoluir para player com:

- seleção real de áudio
- seleção real de legendas
- qualidade manual + auto (ABR)
- live com reconexão mais previsível

## Decisão técnica

A direção recomendada para a Fase 2 é:

- adotar engine de playback com suporte robusto a tracks/ABR/live
- usar adapter interno para desacoplar UI da implementação da engine
- manter `video_player` apenas como fallback temporário durante a migração

Plataforma alvo:

- Android TV + mobile: stack baseada em Media3/ExoPlayer
- iOS (quando aplicável): AVPlayer

## O que foi implementado neste spike

1. Contrato de manifesto estruturado:
`lib/features/player/domain/entities/playback_manifest.dart`

2. Propagação do manifesto no pipeline de playback:
- `PlaybackContext` recebe `manifest`
- `ResolvedPlayback` recebe `manifest`

3. Repositório de player com inferência de tipo de fonte:
- `progressive` para extensões tradicionais
- `hls` para `m3u8`
- `dash` para `mpd`

4. Fallback textual (`notes`) convertido para estrutura:
- áudio
- legendas
- perfis de qualidade

5. Player UI consumindo contrato estruturado:
- áudio/legenda deixam de depender de parsing local em `player_screen`
- qualidade marcada na UI passa a usar lista estruturada de variantes

## Limites atuais (intencionais)

- troca de áudio/legenda/qualidade ainda não é aplicada no stream em runtime
- no estado atual, a marcação permanece como preparação de UX/estado
- reconexão existente continua ativa, sem classificação avançada de erros

## Próximos incrementos (ordem recomendada)

1. Criar interface `PlayerEngineAdapter` no domínio/apresentação.
2. Implementar adapter Media3 com API de:
`setAudioTrack`, `setSubtitleTrack`, `setQualityVariant`, `setAutoQuality`.
3. Conectar o adapter ao `PlayerScreen` por provider.
4. Implementar classificação de erros/reconexão para live (rede, timeout, stream offline).
5. Fechar suíte real em device:
- 30 minutos live estável
- seek repetido em VOD sem travar
- troca de faixa sem reinício completo quando suportado
