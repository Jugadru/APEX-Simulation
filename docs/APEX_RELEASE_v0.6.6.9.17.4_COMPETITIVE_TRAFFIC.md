# APEX v0.6.6.9.17.4 — Competitive Start & Traffic Intelligence

CANDIDATA. Base estável 9.17.3 (merge e8ab858). Objetivo: avaliar largadas em múltiplas seeds e antecipar convergência em gargalos, após observação de carros parados/lado a lado pelo jogador. A captura não prova parada esportiva versus visual.

- Lookahead de quatro comprimentos de carro sobre o perfil de largura existente, sem recriar geometria nem mudar o grid.
- Cancela ataque/defesa novos se não houver dois corredores adiante; mantém corredor já ocupado. O perseguidor lateral cede progressivamente, sem bônus ao líder. RaceSpace continua autoridade de segurança.
- Revisão esportiva 026_competitive_traffic_v1. Replays 025 e anteriores usam caminho antigo; schema de checkpoint preservado; gravação live permanece desligada.
- Matriz 3 seeds × 4 pistas × seco/chuva intensa, 120 s em ticks de 0,2 s, A/B 025/026 e repetição 026, posições aos 18/60/120 s, tentativas/passagens, retenções esportivas, congelamento do pelotão e determinismo. Gates de segurança e não regressão mantidos; testes visuais e FAST obrigatórios. Sem promessa de redução até obter dados. Limites e coeficientes são unidades esquemáticas, não telemetria FIA.
- Racing line/vácuo/ar sujo, HUD e menus são atualizações separadas. Não mudar outros sistemas nesta versão.

Estado inicial: NOT_RUN. Não integrar sem FAST + matriz direcionada no SHA exato. O roadmap 9.17.5–9.17.11 segue antes da 9.18 original.
