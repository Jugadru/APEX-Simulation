# QA 13.2 — triagem documentada dos dez alertas

Base: PR #50 (merge `d8b29877d9afa999d6d69518ea6e96fb5a0d8877`). Evidência: workflows concluídos com sucesso no commit `9174f4612cf63d26942a1c4c8c1095f5d1aadbc9`.

**Escopo e limitação:** leitura dos marcadores emitidos pelo Godot nos logs da CI e dos analisadores Python. Os logs confirmam ocorrências, **não** causas. Não há correção do motor, silenciamento de warning, nem execução nova realizada nesta etapa. Os arquivos JSON brutos dos artefatos e registros internos por carro ainda precisam ser inspecionados para concluir causalidade.

## Scenario Matrix — 20 pistas × 2 execuções, quatro avisos

| Ocorrência | Scenario ID | Pista | Clima (índice) | Controle (índice) | Seed | Evidência real | Classificação |
|---|---|---|---:|---:|---:|---|---|
| M1 | `aus_0_0_29213746` | AUS | 0 (Seco) | 0 (Manual) | 29213746 | 1 carro desclassificado; verificar pneus | INCONCLUSIVE |
| M2 | `ita_0_1_405439352` | ITA | 0 (Seco) | 1 (Assistido) | 405439352 | 1 carro desclassificado; verificar pneus | INCONCLUSIVE |
| M3 | `usa_0_0_125859146` | USA | 0 (Seco) | 0 (Manual) | 125859146 | 2 carros desclassificados; verificar pneus | INCONCLUSIVE |
| M4 | `bhr_0_1_951045693` | BHR | 0 (Seco) | 1 (Assistido) | 951045693 | 1 carro desclassificado; verificar pneus | INCONCLUSIVE |

A mensagem `inspect tyre regulations` é gerada pelo cenário de testes, não confirma infração real. Recuperar para cada desclassificado: car_id, piloto, equipe, compostos usados, número/voltas das paradas, motivo de desclassificação, regra 2012 implementada, decisões manuais/IA e eventos da corrida. Comparar com os resultados duplicados e a origem do código de desclassificação. Observar que os quatro casos são secos, em modos Manual/Assistido, mas sem atribuir causa.

## Pit Wall — 4 cenários × 2 execuções, seis flags de revisão

| Ocorrência | Scenario ID | Pista/clima | Seed | Volta | Car ID | Piloto | Wait (s) | Incidente (s) | Origem | Classificação |
|---|---|---|---:|---:|---:|---|---:|---:|---|---|
| P1 | `ita_dry_auto` | ITA/Seco | 13660 | 9 | 1 | Mark Webber | 4.2690 | 0.0 | `ia_estrategia` | REVIEW |
| P2 | `ita_dry_auto` | ITA/Seco | 13660 | 9 | 12 | Paul di Resta | 3.4097 | 0.0 | `ia_estrategia` | REVIEW |
| P3 | `ita_dry_auto` | ITA/Seco | 13660 | 9 | 16 | Daniel Ricciardo | 8.6319 | 0.0 | `ia_estrategia` | REVIEW |
| P4 | `ita_dry_auto` | ITA/Seco | 13660 | 9 | 21 | Charles Pic | 5.6852 | 0.0 | `ia_estrategia` | REVIEW |
| P5 | `ita_manual_v7` | ITA/Seco | 13663 | 9 | 1 | Mark Webber | 6.4604 | 0.0 | `ia_estrategia` | REVIEW |
| P6 | `ita_manual_v7` | ITA/Seco | 13663 | 9 | 21 | Charles Pic | 5.3799 | 0.0 | `ia_estrategia` | REVIEW |

O analisador sinaliza `PIT_QUEUE` quando `wait >= 3.0`. Isso é um limiar de revisão, não prova erro. **Ainda não há evidência para classificar como EXPECTED ou CONFIRMED_BUG.** Para cada evento, correlacionar timestamp de entrada/saída, box da equipe, companheiro de equipe, plano de pit e decisão, `double_stack`, `team_coordination`, fila de chegada e disponibilidade de mecânicos. `incident_delay=0` exclui somente atraso nessa categoria de métrica, não todas as causas de espera. Não interpretar `wait` como atraso contrafactual.

## Condições de aprovação e sequência

1. Inspecionar os JSONs originais dos artefatos do run Pit Wall `44850769185` e Matrix `44850769195` e os logs dos 8 casos Pit Wall e 40 execuções Matrix.
2. Identificar car_ids das 5 desclassificações e cadeia causal das 6 esperas; atualizar cada linha para EXPECTED, CONFIRMED_BUG ou INCONCLUSIVE, anexando evidência verificável.
3. Se e somente se houver CONFIRMED_BUG: abrir uma PR de correção pequena por causa raiz, com teste de reprodução **antes** da mudança.
4. Regressão após cada correção: manual V21 ≠ V4, manual V6/V7 da Matrix, seed/hash, pneus 2012, Core 2, GdUnit4, Scenario Matrix smoke 20×2, Pit Wall 4×2, save/replay, benchmarks aplicáveis.
5. Não iniciar melhoria 14 antes de concluir a issue #49. Não alterar a PR #26.
6. Classificar testes não executados como NOT_RUN; não confundir CI verde com diagnóstico resolvido.

## Fontes rastreáveis

- [PR #50](https://github.com/Jugadru/APEX-Simulation/pull/50)
- [Pit Wall run 44850769185](https://github.com/Jugadru/APEX-Simulation/actions/runs/44850769185)
- [Matrix run 44850769195](https://github.com/Jugadru/APEX-Simulation/actions/runs/44850769195)
- [Issue #49](https://github.com/Jugadru/APEX-Simulation/issues/49)

## Conclusão da análise causal — coleta adicional no run 44853203822

A nova instrumentação foi executada com sucesso em 20 cenários × duas repetições e identificou **todos os cinco carros desclassificados** nos quatro cenários secos Manual/Assistido:

| Cenário | Piloto | Car ID | Pneus usados | Causa observada |
|---|---|---:|---|---|
| AUS Manual, seed 29213746 | Felipe Massa | 5 | Médio → Médio | Agendamento do mesmo composto |
| ITA Assistido, seed 405439352 | Fernando Alonso | 4 | Duro → Duro | Agendamento do mesmo composto |
| USA Manual, seed 125859146 | Fernando Alonso | 4 | Duro → Duro | Agendamento do mesmo composto |
| USA Manual, seed 125859146 | Felipe Massa | 5 | Duro → Duro | Agendamento do mesmo composto |
| BHR Assistido, seed 951045693 | Felipe Massa | 5 | Médio → Médio | Agendamento do mesmo composto |

**Defeito confirmado:** `tests/ci/apex_scenario_matrix_probe.gd` escolhia `available_pit_compounds()[1]` como alvo único de parada manual/assistida para ambos os carros, sem consultar o composto inicial de cada piloto. Como `race_tyre_regulations_2012.gd` exige utilização dos dois compostos de seco em corrida seca, a penalidade aplicada pelo motor foi coerente com a regra, mas foi provocada por um agendamento inválido do *harness* de QA, não por evidência de decisão defeituosa da IA de produção.

**Correção aplicada na PR #51:** nas corridas sem chuva intensa, cada piloto recebe o composto nominado diferente do que estava instalado no início, preservando V6 e V7. Uma asserção adicional rejeita uma futura desclassificação de piloto da equipe do jogador em cenário seco Manual/Assistido. As corridas de chuva intensa mantêm a escolha de pneus de chuva. A correção altera as entradas do cenário e, por consequência, pode alterar legitimamente o hash esportivo desses cenários; **não** modifica fórmula, regra, RNG ou estado interno do motor. A rodada anterior é a prova antes da alteração; a validação pós-correção depende da CI do SHA final.

### Double stacks: causa imediata explicada

Os seis registros PIT_QUEUE estão em Monza V9. Em todos, o companheiro da mesma equipe também parou na V9, e o histórico de rádio contém eventos explícitos de espera por vaga e liberação. Os registros são **EXPECTED quanto à causa da fila**. `race_double_stack_coordinator_06492.gd` impede adiar quando `entry_lap + 1 >= race_laps`, evitando que uma tentativa de corrigir o congestionamento produza uma parada inválida no fim da corrida. A qualidade da escolha estratégica antecipada continua **REVIEW**, e não `CONFIRMED_BUG`, sem dados contrafactuais.

Não alterar o Pit Wall apenas para ocultar as seis flags. Não liberar melhoria 14 antes de verificar o resultado final do QA e atualizar a issue #49.
