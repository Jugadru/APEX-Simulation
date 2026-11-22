# APEX Motorsport Manager — v0.6.6.9.9 Race Quality Release

**Estado:** CANDIDATE — homologação condicionada aos testes da PR #87 no SHA exato. Não declarar ESTÁVEL antes da aprovação.
**Base:** `main` v0.6.6.9.8 (commit `736ba64e9edb8230804001d19a60df8dc8e39288`), Wet Strategy Intelligence homologada.
**Escopo:** qualidade, estabilidade e correções de falhas **comprovadas**. Sem mecânicas novas, mudanças de física, RNG, IA estratégica, sem trocar revisão 020 de replay/schema, sem reescrever a HUD.

## Incremento diagnóstico inicial: fila residual do pit

A v9.8 registrou `REVIEW / PIT_QUEUE` para Romain Grosjean, `ita_manual_v7`, Monza seco, volta 9/10, `origin=ia_estrategia`, `incident_delay=0` e espera real **5,8772 s**. Não há demonstração de que uma parada antecipada fosse viável ou melhor. O caso **não é bug confirmado**.

O primeiro patch desta versão é estritamente **passivo**:
- `tests/ci/apex_pitwall_intelligence_probe.gd` copia de `get_pit_history()` os horários `entered_at` e `exited_at`, serviço e tempo total já registrados pelo Core 2. Não altera corrida ou dado oficial.
- `tools/apex_pitwall_intelligence.py` valida a presença/consistência dos horários, associa a parada do companheiro mais próximo da mesma equipe e exibe separação de entradas e interseção dos **intervalos de passagem pela pit lane**.
- Sobreposição da passagem na pit lane **não prova** trabalho simultâneo dos mecânicos, nem fila evitável. Os alertas seguem `REVIEW`; não alterar limiar de 3s ou esconder ocorrências.
- `tools/tests/test_apex_pitwall_intelligence.py` exerce o caso sintético 5,8772s e rejeita evidências ausentes, invertidas e não finitas. Testes Python **não são execução de GP**.
- A repetição nativa observou Grosjean entrando em **790,6 s** e saindo em **822,2 s**; Räikkönen entrou em **785,6 s** e saiu em **815,8 s**. O intervalo de entrada foi 5,0 s; a sobreposição da passagem pela pit lane **não prova** tempo de ocupação exclusiva da equipe nem erro causal da estratégia.

## Matriz de regressão da release (resultado a preencher somente com evidência)

| Bloco | Escopo de verificação | Status inicial |
|---|---|---|
| Python / observabilidade | Contratos, registros incompletos, 5,8772s, companheiro | NOT_RUN |
| Pit Wall Analyzer Godot | 4 cenários × 2 repetições; ITA seco/Manual, GBR chuva, BRA variável | NOT_RUN |
| Pit Coordination | FIFO, uma equipe por garagem, double stack, revisão 018/019 | NOT_RUN |
| Wet Strategy | 020/019, chuva, incerteza, sem conhecer clima futuro | NOT_RUN |
| Ordens protegidas | Manual V21 nunca antecipada para V4 | NOT_RUN |
| Silverstone e Monza | 12 GPs completos (2 pistas × 3 climas × 2 repetições), integridade e clima observado | NOT_RUN |
| Matriz de 20 circuitos | 20 circuitos × clima/modo; repetir sementes (full 180 casos quando executado) | NOT_RUN |
| Endurance | Monza oficial 53 voltas/24 carros, hashes de replay, GBR molhado | NOT_RUN |
| UI 2D/3D | Baseline da HUD da PR #85, 1600×900 e 1920×1080 | NOT_RUN |
| Performance | Tick/FPS, 1×/10×/16×/32×, RSS, comparação A/B | NOT_RUN |
| Persistência | SaveGuard e migração de save/replays antigos | NOT_RUN |
| Export | Linux e Windows x86_64; smoke de execução | NOT_RUN |
| Quality Gate | READY 10/10 no commit exato + Gate final estrito 19/19 (incluindo a matriz completa e os 12 GPs) | NOT_RUN |

**Identidade da build:** `project.godot` apresenta `v0.6.6.9.9 — Core 2` nos PCK Linux/Windows; diretório de saves e revisão esportiva 020 não foram alterados. A identidade da build não garante aprovação funcional.

Status permitidos: `PASS`, `FAIL`, `NOT_RUN`, `INCONCLUSIVE`, `BLOCKED`. Um aviso de qualidade não pode ser apagado por mudança arbitrária de thresholds.

**Evidência-base v9.8 (não transfere aprovação para esta release):** 21/21 workflows, Quality Gate READY 10/10, 20 pistas, Monza 53 voltas com replay integral, SaveGuard e exportações Linux/Windows. Relatório: [release 9.8](APEX_RELEASE_v0.6.6.9.8_WET_STRATEGY.md).

## Passos de execução

```bash
python3 -m unittest discover -s tools/tests -p 'test_apex_pitwall_intelligence.py' -v
bash tools/run_pitwall_local.sh
godot --headless --path . --script res://tests/pit_coordination_06697_test.gd
godot --headless --path . --script res://tests/pit_queue_prevention_066971_test.gd
godot --headless --path . --script res://tests/wet_strategy_06698_test.gd
```

Usar ainda os workflows existentes de matriz, endurance, replay, SaveGuard, visuais, benchmarks e exportação. A branch candidata `qa/v0.6.6.9.9-race-quality` executa automaticamente a matriz `full` de **180 casos × 2 repetições** em PR, por configuração explícita do workflow. Nos demais PRs, o padrão continua `smoke`, com somente 20 combinações (10 voltas cada). Um job enfileirado ou interrompido não equivale a PASS.

## Homologação final

O workflow `apex-race-quality-final-gate.yml` verifica exclusivamente no SHA da candidata **19 jobs** obrigatórios: os 10 do Quality Gate existente, os quatro grupos da matriz full, regressões específicas Pit Wall/Pit Coordination/Wet Strategy/Core 2 e os **12 GPs integrais**. Retorna erro se qualquer check faltar ou falhar. O workflow genérico `apex-quality-gate.yml` continua operando em modo de auditoria e pode exibir `BLOCKED` apesar de o job técnico estar verde: esse resultado **não** é liberação.

O teste integral de clima variável exige evidência de mudança observada de pelo menos 0,05 no fator de água; ausência é `INCONCLUSIVE`, não PASS. Resultados devem ser recuperados dos logs/artefatos de execução reais.

## Bloqueadores de publicação

- Falha objetiva de corrida ou perda de determinismo/replay.
- Corrida completa interrompida, violação de ordem Manual, save corrompido ou pit de equipe duplicado.
- Divergência de hash sem revisão esportiva explicada e teste legado.
- Gaps de regressão do roadmap não executados (não publicar como estável).
- Métricas de desempenho sem hardware/cenário descrito.

## Rollback

Branch independente da `main`, sem alteração de lógica esportiva ou revisão. Conservar commit-base `736ba64`; reverter o PR se a auditoria falhar. Só realizar merge quando o relatório final e o Quality Gate confirmarem a aprovação.


## Correção comprovada — deadlock espacial em Mônaco

A matriz completa evidenciou travamento reproduzível no caso `mon_1_1_1764457695` (MON / Variável / Assistido): 22 dos 24 carros bloqueados após a volta 8; dois carros lado a lado (IDs 6 e 8) permaneceram empatados em progresso 7,0936, com pista mais estreita à frente. O Core 2 não encerrava a prova após 1.500 etapas; aumentar o timeout não corrigiria a causa.

A correção mínima no planejador `race_space_0655.gd` substitui apenas o empate ambíguo de prioridade em faixa lateral estreita por desempate determinístico pelo ID: um carro avança normalmente e o outro espera a abertura de espaço. **Não muda RNG, compostos, KERS, DRS, trajetória espacial autorizada, pit manual ou revisão 020**. O teste sintético `apex_monaco_deadlock_099_test.gd` protege a ordem determinística, a separação lateral, a ausência de teleporte e o avanço posterior dos dois carros.

Em execução nativa **isolada** no Godot 4.7.2 (PR de diagnóstico #89), a corrida passou duas vezes com **235 etapas, 24 classificados, 0 erros**, hash igual `20c4953a1f0dee6efb91c34a489a066c69171d0a94ab4cf87c485820feca9a14` e paradas manuais nas voltas 6 e 7. **A aprovação global 19/19 continua obrigatória no novo SHA da PR #87**; testes isolados não liberam publicação.
