# APEX Motorsport Manager v0.6.6.9.8 — Wet Strategy Intelligence (INTEGRADA À MAIN)

**Base:** main commit 46b7b661d6c0fd4c11bd5702c1c12aaae3e32f61, incluindo v0.6.6.9.7.1.
**Status:** RELEASE INTEGRADA à `main` em `c62dc42d0745d6796db1403622f046e515fec7b8` ([PR #86](https://github.com/Jugadru/APEX-Simulation/pull/86)); candidata aprovada `40fa39ab75ebd2c25258f72638d92cbdda387071`. As árvores Git da candidata e do merge são idênticas.
**Escopo único:** previsões meteorológicas imperfeitas para escolhas automáticas de pneus.

## O que muda

- Novo módulo puro: scripts/core/race_wet_strategy_intelligence_06698.gd. Usa somente chuva, lâmina de água, umidade, vento, temperatura e drenagem observados. Não lê eventos futuros, não chama weather.forecast() nem consome RNG.
- Integra-se à função original _build_strategy_plan() do Core 2, alcançando a mesma IA do Pit Wall e dos rivais. O modo Manual recebe sugestões sem executar automaticamente.
- Nowcast com faixa de incerteza **heurística**, sem fingir probabilidade calibrada. O módulo puro aceita um nível de competência que ajusta a margem, mas a IA esportiva usa nível neutro fixo nesta versão. A competência do STAFF não deve afetar decisões antes de integrar seus dados à persistência/replay; nenhum atributo auxiliar fora do checkpoint influencia o motor.
- Trocas automáticas não críticas que dependem de atravessar o limiar entre pneus podem aguardar quando a faixa cruza esse limiar. Desgaste crítico e slicks em pista perigosamente molhada não são bloqueados.
- Nenhuma alteração da física da chuva, progressão do carro, HDR, HUD 2D/3D, regulamento 2012 ou cálculo da fila de pit.
- Ordens manuais V21 e chamadas imediatas continuam sob controle do jogador. Double stack, FIFO e prevenção de filas da versão 9.7.1 permanecem preservados.

## Replays e saves

A mudança pode alterar os tempos das paradas e, portanto, hashes esportivos. O replay novo utiliza a revisão 020_wet_strategy_intelligence_v1. Arquivos da revisão 019_last_legal_pit_queue_v1 e anteriores preservam o algoritmo antigo de previsão por sinalizador apenas de sessão: wet_strategy_intelligence_enabled=false. O sinalizador foi excluído do codec, com SCHEMA=1 e sem novos campos persistidos.

**Limitação:** uma tempestade que ainda não começou não será prevista com precisão. A faixa é uma medida de incerteza heurística, não intervalo estatístico. A nova estratégia exige testes de balanceamento completos em corridas molhadas, variáveis e secas.

## Evidências finais de homologação

- **[21/21 workflows PASS](https://github.com/Jugadru/APEX-Simulation/commit/40fa39ab75ebd2c25258f72638d92cbdda387071/checks)**, todos no mesmo commit candidato. Três falhas transitórias de importação Godot (código 139) foram repetidas e passaram; não houve correção artificial da IA para contorná-las.
- **[Quality Gate READY 10/10](https://github.com/Jugadru/APEX-Simulation/actions/runs/44984972797)**, após repetir a auditoria por SHA depois da conclusão dos workflows. O primeiro relatório `BLOCKED 6/10` refletia evidências ainda pendentes e não foi aceito como READY.
- **[Wet Strategy 9.8](https://github.com/Jugadru/APEX-Simulation/actions/runs/44984972799)**: 83 verificações; inclui nome e descrição de versão 9.8, previsões determinísticas, ausência de conhecimento da chuva futura, segurança do pit e replays 019/020.
- Regressões dirigidas: Weather 0641 PASS; Pit Coordination 9.7 **41 checks**, Pit Queue 9.7.1 **28 checks**, Prediction Ledger 9.6 **28 checks**.
- **[Matriz de 20 circuitos](https://github.com/Jugadru/APEX-Simulation/actions/runs/44984972857)**: 4/4 grupos PASS.
- **[Endurance](https://github.com/Jugadru/APEX-Simulation/actions/runs/44984972885)**: duas repetições de crescimento 6.000 ticks; GPs repetidos ITA seco/GBR chuva intensa, dados administrativos de carreira 400 rodadas, zero avisos; Monza 53 voltas, **24.229 ticks**, 24 carros e replay integral PASS; hash esportivo `aae9bbc6a574d9cede858f7c59049b0db691225970db13e94d21d282a4fccc1e`.
- **[SaveGuard](https://github.com/Jugadru/APEX-Simulation/actions/runs/44984972877)**, Race Radio, Soul Driver, Pit Wall Analyzer e regressão visual: PASS.
- **[Exportação Godot 4.7.2](https://github.com/Jugadru/APEX-Simulation/actions/runs/44984972921)**: Linux e Windows x86_64 PASS; os dois PCK registram nome `v0.6.6.9.8`; smoke Linux PASS. [Builds temporárias](https://github.com/Jugadru/APEX-Simulation/actions/runs/44984972921/artifacts/14738384976), com previsão de expiração em 06/12/2026.

**Limitações verificadas:** o Pit Wall Intelligence Analyzer terminou com PASS, mas manteve um sinal `REVIEW / PIT_QUEUE` no cenário `ita_manual_v7`, parada IA de Grosjean, volta 9, espera real de 5,8772 s, sem incidente. É um caso específico para análise posterior, não falha dos critérios de lançamento. Os benchmarks headless não medem FPS 3D nativo no PC Windows/Linux do jogador.

## Execução

    godot --headless --single-threaded-scene --path . --import
    godot --headless --single-threaded-scene --path . --script res://tests/wet_strategy_06698_test.gd

## Rollback

Se houver regressão esportiva comprovada, abrir branch de correção e executar `git revert c62dc42d0745d6796db1403622f046e515fec7b8`, com regressões de replay e SaveGuard. Não renomear arquivos 020 como 019 nem forçar downgrade silencioso.
