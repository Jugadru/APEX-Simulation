# APEX 9.18 — Wet Weather Setups

Base: v0.6.6.9.17.12 / 036, PR #127, merge f442d3b8. Uma funcionalidade principal: disponibilizar acertos climáticos reais no fluxo de preparação do GP.

## Escopo
O modelo 015 já calcula ritmo e desgaste com asa, freios e suspensão a partir da umidade, carga lateral, tração e aderência observadas. A interface de preparação agora permite escolher separadamente para a dupla, com ordem estável por ID do cadastro e nomes no painel. Os presets são escolhas explícitas, não previsões perfeitas nem acertos automáticos de IA. Mantidos durante a prova; escolhas do menu permanecem até alteração manual, padrão neutro. Sem alteração de pneus, clima, estratégia, DRS/KERS, física de corrida ou RNG. Valores abstratos de balanceamento, não medições FIA.

| Acerto | Asa | Freio | Suspensão |
|---|---:|---:|---:|
| Neutro | 0 | 0 | 0 |
| Seco | 0.15 | -0.55 | -0.65 |
| Misto | 0.35 | 0.35 | 0.45 |
| Chuva | 0.85 | 0.75 | 0.85 |

Os parâmetros são aplicados pelo contrato existente configure_pre_race_setup antes da captura de replay. Sem mudança de schema/revisão esportiva; replays 036 já registram race_setup_15. Sem persistência nova de preferências de menu após reiniciar o aplicativo.

## Homologação
FAST + APEX Test Lab e testes de setup 015/9.14, interface nativa, nove cenários curtos em Monza/Silverstone/Mônaco com seco, chuva e variável, replay com setup não neutro, neutralidade por hash, proteção de pneus/pit/RNG. Resultados ainda NOT_RUN no momento de envio. Não há FULL obrigatório, calibração histórica ou ganho de FPS declarado. Rollback: f442d3b8. Sem merge antes de CI aprovada e autorização.
