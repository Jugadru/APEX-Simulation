# APEX v0.6.6.9.11 — Race Start Intelligence 1.0

**Estado:** candidato em branch/PR; não é release homologado.
**Base:** main após v0.6.6.9.10 e infraestrutura CI FAST/TARGETED/FULL.
**Escopo único:** modelo causal e individual de reação/tração nos primeiros 8 segundos simulados. Nada de mudanças nas disputas em curva ou IA de ultrapassagem (v9.12 e v9.17).

## Contrato da implementação

- `scripts/core/race_start_intelligence_066911.gd`: serviço puro, sem RNG e sem mutação. A reação depende de habilidade, percepção espacial, confiança inicial e tolerância ao risco. A tração depende de carro, habilidade, pneu/temperatura já simulados e aderência/umidade reais.
- O risco tem trade-off: pode reduzir o tempo de reação, mas aumenta a perda de tração. Não há rolagem de posições, impulsos de movimento, teleporte ou incidentes gerados pelo serviço.
- `race_performance.gd` aplica o custo transitório exclusivamente ao ritmo-alvo, antes de converter ritmo em progresso pelo RaceSpace preexistente. `race_engine.gd` fornece relógio, clima e a versão esportiva da sessão.
- O custo é zero a partir de 8s. Mecânica de pneus, pneus molhados, KERS e DRS de 2012 não são substituídos.
- Fórmulas e coeficientes são aproximações de jogo, **não dados medidos de telemetria ou largadas reais**.
- Nenhum campo novo é persistido em carros ou migrado em saves. A flag de versão é **session-only** e excluída dos hashes/checkpoints esportivos.

## Replay, compatibilidade e rollback

- Arquivos novos: revisão `022_race_start_intelligence_v1`.
- Arquivos 021: `021_strategy_staff_intelligence_v1`, preservam a largada da Melhoria 14 e toda a inteligência do estrategista 9.10.
- Arquivos 020 e anteriores: preservam as decisões estratégicas historicamente corretas e sua física de largada pré-existente.
- Para `load_data`, `load_live_session` e `seek`, a mesma flag de compatibilidade é reaplicada após restauração. A revisão 021 não pode ser confundida com uma revisão sem STAFF.
- Rollback: reverter esta PR inteira. O algoritmo anterior permanece no arquivo `race_launch_14.gd`, sem alteração.

## Testes planejados e evidências exigidas

- Godot 4.7.2 import e parse de todos os scripts: **NOT_RUN**.
- Modelo puro, diferença de habilidade e confiança, chuva, frio, risco, limites 0–8s: **NOT_RUN**.
- Grid 2012 com 24 carros e seed idêntica: **NOT_RUN**.
- Hash e seek de replay 022 e 021: **NOT_RUN**.
- BOX manual V21 sob chuva forte: **NOT_RUN**.
- FAST e TARGETED: **NOT_RUN**.
- FULL: Silverstone/Spa/Monza/Singapura, circuito/corrida completos, SaveGuard, benchmark, 2D/3D e exports: **NOT_RUN**.
- GPU, FPS real, estabilidade e aceitação visual no PC alvo: **NOT_RUN**.

O workflow `apex-race-start-ci.yml` executa importação real e regressões dirigidas. O `godot-setup.yml` e o seletor `tools/apex_ci_tiers.py` incluem os novos testes no FAST/FULL. Marcar `ci:full` no PR **apenas quando os testes iniciais estiverem verdes** para ativar a homologação de maior custo.

**Critério de merge/release:** aprovar apenas depois de evidências reais suficientes. Não alterar `project.godot` para 9.11 nem publicar ZIP antes dos gates.
