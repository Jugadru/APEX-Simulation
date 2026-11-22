# APEX v0.6.6.9.6 — Pit Wall Prediction Ledger 1.0 (CANDIDATE)

**Base:** `main` em `2364be6a5d138d6b9cf56c29a3336c1b166527b0`, Race Radio 3.0. Uma única funcionalidade: previsões versus resultados verificáveis.

## Integração implementada

- `scripts/core/race_pitwall_prediction_06696.gd`: observador passivo; registra decisões e recomendações antes de sua execução (inclusive ordem manual e V21), e mantém uma **segunda fotografia** na entrada real do pit, antes de qualquer sorteio de serviço; correlaciona `car_id + stop` com o registro imutável em `pit_history`; compara posição e perda líquida de pit; acompanha até cinco voltas subsequentes para desgaste/ritmo e três para água; compara ganho relativo de cinco voltas contra um mesmo rival quando não há novo pit rival; registra incertezas. Armazena até 96 entradas por GP.
- `scripts/race_engine.gd`: observadores para recomendações consultivas, agendamento/cancelamento manual, IA e entrada/saída do pit, mais interfaces `get_prediction_ledger` e `get_prediction_summary`. Nenhuma ordem nova, nenhuma alteração em regulamento, física, pace, pneus, scheduler ou probabilidade de falha.
- `scripts/apex_race_session_controller.gd`: fornece níveis reais de engenheiro/estrategista para **rotulagem da previsão** da equipe do jogador. Níveis desconhecidos são registrados como -1, nunca inventados.
- `scripts/apex_race_hud_0622.gd`: histórico de recomendações, decisões, cancelamentos e saídas verificadas; MAE por nível de estrategista e comparação de ritmo relativo dentro do Pit Wall existente. Não cria HUD alternativa.
- `scripts/core/race_state_codec_0660.gd`: exclui o observador e níveis de staff dos snapshots e hashes esportivos. Mantém schema e `SIMULATION_REVISION`.
- `tests/pitwall_prediction_06696_test.gd`: exercícios de previsão sem resultado fabricado, medição real, erro/causas, horizonte, interrupção, cópias imutáveis, calibração retrospectiva e comparação de motor com/sem consultas.

## Sem promessas irreais

A posição após o pit é estimada pelo modelo **já existente** do Pit Wall. A perda líquida real é `pit_history.total - base_lap * PIT_TRACK_FRACTION`; portanto não se compara tempo de atravessar a pit lane com a perda em relação à volta normal. O modelo de desgaste usa `Strategy._wear_per_lap` e o novo composto real; o ritmo estimado usa última volta observada e deltas de composto/água, não eventos futuros. A previsão de água é o `forecast_3` calculado no instante da fotografia correspondente: na emissão da recomendação, para histórico consultivo, ou na entrada do pit, para avaliação do resultado.

Após **três** saídas de pit verificadas da **mesma equipe e nível de estrategista**, a previsão seguinte pode corrigir viés médio recente (até oito observações, correção limitada). Não existem erros aleatórios impostos por nível de staff nem bônus de desempenho para criar acerto artificial. O histórico permite calcular MAE por categoria de staff; até haver identidade estável por funcionário, não confundir isto com uma avaliação individual.

**Limitações explícitas v1:** recomendações e agendamentos são preservados no instante da decisão e ligados à entrada se executados; **somente o snapshot de entrada** é pontuado contra os resultados subsequentes, para não comparar clima de V4 com V24. Agendamentos cancelados não geram resultados fictícios. O ledger é diagnóstico **da sessão ativa**; não é salvo automaticamente na carreira nem exportado como replay histórico. Resultados de ritmo de cinco voltas são aproximações; a diferença relativa de tempo contra o mesmo rival (sem pit rival) pode ser medida e contrastada com previsão de ritmo, mas **não** prova quanto se ganharia se o próprio piloto tivesse permanecido na pista. Uma diferença de posição não prova por si só uma causa específica de tráfego. Uma segunda parada interrompe a verificação do mesmo composto.

## QA de liberação (NÃO CONFIRMADA)

A PR deve executar o Godot 4.7.2, as regressões da v0.6.6.9.5 e Pit Wall V21, replay, saves antigos, benchmarking e inspeção visual real. Resultados específicos devem ser consultados na execução de GitHub Actions vinculada ao commit mais recente; **não reaproveitar PASS de commits anteriores**. Uma PR aberta não é release estável. A fonte de evidência será o CI do commit exato.

## Rollback

Não alterar `main` antes dos gates. Para reverter, fechar a PR/descartar a branch, deixando `main` no commit original.

## CI: robustez de importação

O grupo 1/4 da matriz de 20 circuitos registrou uma falha de importador nativo (`exit 139`) no primeiro head, enquanto outros grupos concluíram a importação. O workflow da matriz passou a repetir apenas falhas nativas `139/134`, limpando o cache `.godot` entre tentativas. Erros de parsing continuam falha imediata. Evidência final e resultado dos quatro grupos devem ser conferidos no commit da PR.
