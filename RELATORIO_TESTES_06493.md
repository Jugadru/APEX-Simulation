# RELATÓRIO TÉCNICO — APEX v0.6.4.9.3 — BALANCEAMENTO DE PIT STOPS

**Data:** 09/11/2026  
**Base:** `APEX_MOTORSPORT_MANAGER_v0.6.4.9.2_DOUBLE_STACK_COMPLETO.zip`  
**Engine:** Godot 4.7.2 stable, execução Linux headless para simulação e Xvfb/OpenGL para interface.

## 1. Mudança isolada nesta versão

**Exatamente um módulo funcional alterado:** `scripts/core/race_ai_director.gd`.

Quando a IA avalia a **troca de um intermediário por outro intermediário** ou de um pneu de chuva por outro do mesmo composto, **somente uma troca preditiva não crítica** é adiada se:

1. O pneu ainda tiver **menos de 64% de desgaste**;
2. Houver **mais de duas voltas de vida estimada até o cliff**;
3. Não existir **alerta crítico** que imponha a parada.

A análise é refeita na volta seguinte. O critério de troca por desgaste crítico, a escolha de composto quando o clima realmente muda, a histerese da chuva, as paradas manuais e a proteção de V21 não foram alterados. O limite de 64% é **ajuste de game balance** e não parâmetro histórico da Pirelli.

`project.godot` alterado apenas para nome da versão e **saves isolados**. O código de física, clima, desgastes, corridas, Staff, Soul Driver, Race Engineer e Double Stack foi preservado, incluindo `scripts/race_engine.gd` (bytes idênticos à base).

## 2. Silverstone — GP completo e reproduzível

- Circuito: **Silverstone (GBR)**.
- Seed: **6403**.
- Clima: **Variável** (transição chuva e secagem de pista).
- Grade: **24 pilotos**, Ferrari controlada pela IA como na referência da 0.6.4.9.2.
- Prova: **52/52 voltas**, `sim.step(0.20)` sem passo grosso, **26436 ticks** e **5287.2 segundos simulados**.
- Godot concluiu com código 0, `sim.finished=true`, classificação validada e sem violações de regra de pneus.
- **Vencedor: Fernando Alonso**.

| Indicador | v0.6.4.9.2 | v0.6.4.9.3 |
|---|---:|---:|
| Pit stops totais | **90** | **78** |
| Trocas Intermediário → Intermediário | 12 | 0 |
| Pilotos com 4 paradas | 18 | 6 |
| Pilotos com 3 paradas | 6 | 18 |
| Classificação válida | Sim | Sim |
| Máximo desgaste capturado nas voltas | 75.0% | 77.6% |

**Melhoria de 12 pit stops (13,3%)**, exatamente as 12 trocas de intermediário por intermediário que foram dispensadas. A troca para slicks posteriormente permaneceu. A redução foi observada **nesta seed e nestas condições**; não prova resultado igual em outras pistas ou climas.

As esperas por double stack existentes continuaram presentes: Felipe Massa 1.11s, Kamui Kobayashi 6.64s, Jean-Eric Vergne 7.27s. Não foram alteradas ou ocultadas nesta versão.

## 3. Testes de regressão

- **Teste dirigido** `tests/pit_balance_06493_threshold_test.gd`: PASS. Situações de 57% e 62% de desgaste com pista secando deixam de autorizar troca preditiva de Inter por Inter; 72% e 91% continuam permitindo parada por desgaste; planejador seco e ordem V21 preservados.
- **GP completo Silverstone variável**: PASS (52v, 24 carros, 0,20s), logs e JSON anexados.
- **18 verificações de regressão**: 15 passaram em execução headless e 3 verificações de interface que dependem de captura de tela passaram após reexecução gráfica em Xvfb. Os três testes não devem ser marcados como aprovados pela tentativa headless: um gerou erro de captura e dois atingiram timeout sem renderização.
- **Quatro testes adicionais** de escolha de pneus, transição meteorológica, dinâmica da pista e termodinâmica: concluídos com exit 0 e sem `SCRIPT ERROR`.

Os logs originais da bateria e as reexecuções gráficas estão em `qa/06493/regression_logs` e `qa/06493/logs/`.

## 4. Limitações e problemas ainda abertos

- **Controle adicional de Silverstone seco (52v): não validado.** A execução avançou até aproximadamente a volta 51, mas ficou lenta e foi encerrada para não confundir um teste incompleto com PASS. Essa observação não demonstra regressão: o ajuste deste patch só trata troca de compostos de chuva por si próprios. Um teste direcionado do planejador seco e os testes existentes passaram; uma prova seca de 52 voltas ainda deve ser reavaliada separadamente.
- **Bateria de 8 GPs / temporada com Staff**: não reexecutada nesta entrega.
- **Prevenção de double stack:** continuam 3 esperas na corrida de referência; apenas o patch 0.6.4.9.2 mexeu nesse aspecto.
- **Indicador de confiança estratégica:** permanece como na 0.6.4.9.2; revisão planejada separadamente para a **v0.6.4.9.4**.
- Todos os fatores de pneus e tempos são parâmetros fictícios de jogo, não telemetria de F1 real.

## 5. Arquivos de evidência

- `qa/06493/native_020/GBR.json`: resultado e telemetria do GP variável.
- `qa/06493/GBR_COMPARACAO.json`: resumos e distribuição de paradas.
- `qa/06493/SILVERSTONE_COMPARACAO_06492_06493.csv`: diferença por piloto.
- `qa/06493/PROVA_CONTROLADA_baseline_06492.txt` e `PROVA_CONTROLADA_new_06493.txt`: ensaios idênticos antes/depois.
- `qa/06493/regressions.json` e `qa/06493/logs/`: resultados originais, testes em Xvfb e execução seca interrompida.

**Conclusão:** a v0.6.4.9.3 reduz paradas preditivas prematuras em Silverstone sob clima variável sem mexer nos demais sistemas de produção. Os limites acima permanecem explícitos.
