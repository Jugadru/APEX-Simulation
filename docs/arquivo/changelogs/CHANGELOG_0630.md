# Apex Motorsport Manager v0.6.3.0 — Rádio dos Pilotos (fase 1)

**Base protegida:** Apex v0.6.2.9. O projeto principal foi atualizado, mas os laboratórios externos de Bahrain e de carros 2012 permanecem separados.

## Implementado

- `scripts/core/race_driver_feedback.gd` (novo): avaliação determinística de fatos da corrida, com prioridade para pneu inadequado às condições, perda de aderência, temperatura e tráfego. Mensagens com intervalo de quatro voltas; somente pilotos da equipe do jogador.
- `scripts/race_engine.gd`: inclui o novo módulo, guarda apenas o último aviso de cada piloto e adiciona um evento `driver_radio` à telemetria. **Não altera física, IA dos boxes, pneus, DRS/KERS, câmeras ou consumo de aleatoriedade.**
- `scripts/apex_commentary.gd`: novo papel **PILOTO** no rádio e nos filtros. O filtro de equipe inclui piloto/engenheiro/boxes; o de transmissão não confunde essas falas com narração.
- `scripts/main.gd` e `project.godot`: apenas identificação da versão.
- Novo teste nativo em `tests/core_0630_driver_radio_smoke_test.gd`.
- Novo teste reprodutível de estado em `tests/core_0630_parity.gd` (para comparação com a v0.6.2.9).

## O que NÃO está incluído

- Não são áudios reais, clonagem de voz ou citações reais dos pilotos de 2012: cada mensagem traz **RÁDIO FICTÍCIO**.
- Não há personalidade psicológica histórica inferida, decisões autônomas de pilotos ou novo jogo de pneus por solicitação verbal.
- Não foram importados modelos KN5/GLB de terceiros nem o circuito externo de Bahrain.
- Não houve mudança da HUD aprovada, além de apresentar as mensagens no filtro existente de rádio.
