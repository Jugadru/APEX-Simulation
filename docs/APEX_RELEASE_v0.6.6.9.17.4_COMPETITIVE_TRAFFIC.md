# APEX v0.6.6.9.17.4 — Competitive Start & Traffic Intelligence

INTEGRADA — homologada em 24/11/2026. Base estável 9.17.3 (merge e8ab858). Objetivo: avaliar largadas em múltiplas seeds e antecipar convergência em gargalos, após observação de carros parados/lado a lado pelo jogador. A captura não prova parada esportiva versus visual.

- Lookahead de quatro comprimentos de carro sobre o perfil de largura existente, sem recriar geometria nem mudar o grid.
- Cancela ataque/defesa novos se não houver dois corredores adiante; mantém corredor já ocupado. O perseguidor lateral cede progressivamente, sem bônus ao líder. RaceSpace continua autoridade de segurança.
- Revisão esportiva 026_competitive_traffic_v1. Replays 025 e anteriores usam caminho antigo; schema de checkpoint preservado; gravação live permanece desligada.
- Matriz 3 seeds × 4 pistas × seco/chuva intensa, 120 s em ticks de 0,2 s, A/B 025/026 e repetição 026, posições aos 18/60/120 s, tentativas/passagens, retenções esportivas, congelamento do pelotão e determinismo. Gates de segurança e não regressão mantidos; testes visuais e FAST obrigatórios. Sem promessa de redução até obter dados. Limites e coeficientes são unidades esquemáticas, não telemetria FIA.
- Racing line/vácuo/ar sujo, HUD e menus são atualizações separadas. Não mudar outros sistemas nesta versão.

Estado final: PASS no SHA 7ed25d3a012de762d4b247ee8b667be910aaea48. Merge autorizado: 603998ae31666d8f72cc4225a1396c0b49a2d739. O roadmap 9.17.5–9.17.11 segue antes da 9.18 original.

## Evidências finais
- FAST: https://github.com/Jugadru/APEX-Simulation/actions/runs/45452644928 — PASS.
- Movimento: https://github.com/Jugadru/APEX-Simulation/actions/runs/45452645191 — 21/21 jobs PASS.
- Multiseed: https://github.com/Jugadru/APEX-Simulation/actions/runs/45452645002 — 4/4 jobs PASS, 510 checks, 24 cenários e 72 execuções. Amostras estacionárias 7→0, ultrapassagens 25→25, zero reversões e congelamentos. Lado a lado praticamente inalterado; não confundir melhora do tráfego com racing line implementada. Limites: 120 s por cenário, sem comprovação de corrida longa no PC do jogador. Exportação e publicação separadas.
