# APEX v0.6.6.9.14 — Setup & Track Knowledge 1.0

**Estado:** candidata a homologação, branch `feat/v0.6.6.9.14-setup-track-knowledge`, **não integrada à main**.

## Escopo da versão (uma funcionalidade principal)

A equipe agora interpreta os **20 perfis de pista do campeonato 2012 que já estão no jogo**, trazendo uma leitura de pista e uma proposta **qualitativa** de setup no painel de Race Engineer.

- Fonte: `data/track_physics_2012.json` via `TrackDynamics.profile_for(code)`. Não há circuitos fictícios, previsões externas, telemetria FIA ou constantes físicas novas.
- Recomendações: **carga aerodinâmica** (alta/equilibrada/baixa), **prioridade mecânica** (tração/apoio lateral/equilíbrio), **gestão dos pneus** (abrasão) e alertas observados de pista úmida/drenagem.
- **Monza:** perfil de carga lateral baixa. **Silverstone:** carga lateral alta. **Mônaco:** tração e aderência mecânica. Critérios são heurísticas relativas aos parâmetros do próprio catálogo APEX, não valores de asa aplicáveis fisicamente.
- Nível de engenheiro influencia somente o detalhamento da leitura e **não altera recomendações básicas, física ou decisões esportivas**.
- Nova pergunta consultiva **SETUP/PISTA** no painel existente, com resumo visível nas evidências dos dois carros.
- Sem modificações no motor, pontuação, pneus, rádio histórico, RaceSpace, weather physics, Pit Wall, Race Replay ou SaveGuard. Revisão esportiva continua `023_overtaking_intelligence_v1`.
- Ordens do jogador, incluindo **BOX manual V21 com chuva de 83%**, seguem intocadas. Nenhuma recomendação é aplicada automaticamente; `can_apply=false`.
- A versão 1.0 **não** permite ainda girar asas, mudar suspensão, salvar presets nem simular treino e ganho de tempo. Esse fluxo exigirá revisão esportiva e controles explícitos em versões posteriores, não neste PR.

## Homologação obrigatória

1. Import Godot 4.7.2 sem erros de parser, com tentativas controladas apenas para crashes nativos 134/139.
2. `SETUP_TRACK_066914_PASS`: catálogo de **20 circuitos**, exemplos distintos de Monza/Silverstone/Mônaco, chuva/drenagem, segurança dos dados e 24 carros reais, consulta UI, preservação de V21 e revisão 023.
3. Regressões específicas `ENGINEER_066913_PASS`, `RE3_0646_PASS`, `OVERTAKING_066912_PASS`, `REPLAY_UNIT_PASS`.
4. FAST + FULL completos no **SHA exato**: Quality Gate 2.0, matriz 20 circuitos, stress de longa duração, SaveGuard, exportações, benchmarks e visuais. O `ci:full` é obrigatório.
5. Renderização e desempenho de GPU em desktop real só podem ser declarados depois de teste local (CI headless não mede FPS real).

**Sem merge até que FULL esteja READY no SHA final, sem exceções.**
