# APEX v0.6.6.9.14 — Setup & Track Knowledge 1.0

**Estado:** código integrado à `main` pelo [PR #98](https://github.com/Jugadru/APEX-Simulation/pull/98), commit `4bd57ad2580472ceafb1dccde422523fb3b4ccc9`. FAST aprovado antes e depois do merge; **não há release binária 9.14 publicada**.

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

## Validação aplicada e política atual

A 9.14 passou no FAST [antes](https://github.com/Jugadru/APEX-Simulation/actions/runs/45085007667) e [depois](https://github.com/Jugadru/APEX-Simulation/actions/runs/45085256586) do merge, usando Godot 4.7.2.

- `SETUP_TRACK_066914_PASS checks=64`: perfis das 20 pistas, chuva, HUD e integridade esportiva.
- `ENGINEER_066913_PASS checks=33`: continuidade do módulo anterior.
- APEX Test Lab, perfilador de CPU, replay e testes do Core 2 aprovados.

**Homologação extensa não é obrigatória em atualizações de scripts.** Matriz 20/180, endurance, SaveGuard, benchmarks, capturas e exportações são executados manualmente, se solicitados. A v9.14 é código-fonte integrado, não nova distribuição Windows/Linux. CI headless não comprova FPS/GPU em PC real.
