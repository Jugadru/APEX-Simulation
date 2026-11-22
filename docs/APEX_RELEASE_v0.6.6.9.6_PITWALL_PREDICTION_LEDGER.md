# APEX v0.6.6.9.6 — Pit Wall Prediction Ledger 1.0 (CANDIDATE)

**Base:** `main` em `2364be6a5d138d6b9cf56c29a3336c1b166527b0`, Race Radio 3.0. Uma única funcionalidade: previsões versus resultados verificáveis.

## Integração implementada

- `scripts/core/race_pitwall_prediction_06696.gd`: observador passivo; captura uma previsão no compromisso real de entrada no pit, **antes** de qualquer sorteio de serviço; correlaciona `car_id + stop` com o registro imutável em `pit_history`; compara posição e perda líquida de pit; acompanha até cinco voltas subsequentes para desgaste/ritmo e três para água; registra incertezas. Armazena até 96 entradas por GP.
- `scripts/race_engine.gd`: três ganchos observacionais, interfaces `get_prediction_ledger` e `get_prediction_summary`. Nenhuma ordem nova, nenhuma alteração em regulamento, física, pace, pneus, scheduler ou probabilidade de falha.
- `scripts/apex_race_session_controller.gd`: fornece níveis reais de engenheiro/estrategista para **rotulagem da previsão** da equipe do jogador. Níveis desconhecidos são registrados como -1, nunca inventados.
- `scripts/apex_race_hud_0622.gd`: histórico e MAE dentro do Pit Wall existente. Não cria HUD alternativa.
- `scripts/core/race_state_codec_0660.gd`: exclui o observador e níveis de staff dos snapshots e hashes esportivos. Mantém schema e `SIMULATION_REVISION`.
- `tests/pitwall_prediction_06696_test.gd`: exercícios de previsão sem resultado fabricado, medição real, erro/causas, horizonte, interrupção, cópias imutáveis, calibração retrospectiva e comparação de motor com/sem consultas.

## Sem promessas irreais

A posição após o pit é estimada pelo modelo **já existente** do Pit Wall. A perda líquida real é `pit_history.total - base_lap * PIT_TRACK_FRACTION`; portanto não se compara tempo de atravessar a pit lane com a perda em relação à volta normal. O modelo de desgaste usa `Strategy._wear_per_lap` e o novo composto real; o ritmo estimado usa última volta observada e deltas de composto/água, não eventos futuros. A previsão de água é o `forecast_3` calculado no instante do compromisso.

Após **três** saídas de pit verificadas da **mesma equipe e nível de estrategista**, a previsão seguinte pode corrigir viés médio recente (até oito observações, correção limitada). Não existem erros aleatórios impostos por nível de staff nem bônus de desempenho para criar acerto artificial. O histórico permite calcular MAE por categoria de staff; até haver identidade estável por funcionário, não confundir isto com uma avaliação individual.

**Limitações explícitas v1:** a fotografia da previsão é tirada na entrada comprometida do pit, não no momento de uma recomendação ainda não aceita; agendamentos cancelados não geram resultados fictícios. O ledger é diagnóstico **da sessão ativa**; não é salvo automaticamente na carreira nem exportado como replay histórico. Resultados de ritmo de cinco voltas são aproximações; não há comparação contrafactual do tempo que teria sido obtido sem parar. Uma diferença de posição não prova por si só uma causa específica de tráfego. Uma segunda parada interrompe a verificação do mesmo composto.

## QA de liberação (NÃO CONFIRMADA)

A PR deve executar o Godot 4.7.2, as regressões da v0.6.6.9.5 e Pit Wall V21, replay, saves antigos, benchmarking e inspeção visual real. Antes das ações, todos os testes são **NOT_RUN**. Uma PR aberta não é release estável. A fonte de evidência será o CI do commit exato.

## Rollback

Não alterar `main` antes dos gates. Para reverter, fechar a PR/descartar a branch, deixando `main` no commit original.
