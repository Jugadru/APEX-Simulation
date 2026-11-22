# APEX v0.6.6.9.7.1 — Issue #82: prevenção conservadora de filas obrigatórias (CANDIDATE)

**Base imutável:** `a9534852360afd478209bd7f79e95f84b6dae2cb` (main da v0.6.6.9.7).  
**Status:** CANDIDATE — implementação submetida; testes de CI e impacto real nas corridas ainda não comprovados.  
**Escopo:** aprimorar SOMENTE a coordenação estratégica preventiva de paradas obrigatórias na última entrada legal. A fila física FIFO v9.7 e seus tempos continuam intactos.

## Diagnóstico baseado em registros reais

Fonte primária: [Pit Wall Intelligence Analyzer, run 44973100061](https://github.com/Jugadru/APEX-Simulation/actions/runs/44973100061), head aprovado da PR #81 (`689aaf75`), cenário de 10 voltas e 24 carros, repetido duas vezes.

As **sete flags PIT_QUEUE de revisão** aconteceram na **volta 9 de 10** em Monza seco, com `order_origin=ia_estrategia`, `incident_delay=0.0` e o companheiro da mesma equipe também parando na V9 para trocar de composto (dois slicks, temporada 2012).

| Cenário | Piloto/car_id | Espera observada (s) |
|---|---|---:|
| `ita_dry_auto` | Mark Webber / 1 | 4.2690 |
| `ita_dry_auto` | Daniel Ricciardo / 16 | 8.2319 |
| `ita_dry_auto` | Charles Pic / 21 | 5.6852 |
| `ita_manual_v7` | Mark Webber / 1 | 6.2604 |
| `ita_manual_v7` | Bruno Senna / 15 | 3.8577 |
| `ita_manual_v7` | Jean-Eric Vergne / 17 | 3.1594 |
| `ita_manual_v7` | Charles Pic / 21 | 5.1799 |

A causa **física** de cada espera é a equipe de mecânicos compartilhada. A hipótese de falha tática é mais específica: o planejador de corrida completa concentra paradas **obrigatórias** na V9, enquanto `race_team_pit_coordination_06497.gd` exige pelo menos **25% de desgaste** para antecipar para V8; nesses registros, o desgaste foi tipicamente 16–18%. Adiar V9 para V10 é corretamente proibido. **Isso não prova que todas as sete esperas eram evitáveis economicamente**, somente identifica uma oportunidade não avaliada pela IA antes da última janela.

## Correção candidata

1. Manter prioridade estável por posição/ID e a regra de uma alteração por stint.
2. Abrir uma exceção ao desgaste **mínimo** de 25% somente para o **primeiro uso obrigatório** do segundo slick, quando ambos os planos independentes selecionaram `race_laps - 1` e ainda existe a entrada anterior.
3. Usar unicamente estado observado dos carros (`progress`) e duração estimada **dock + service** baseada no mesmo modelo de equipe (`PitMath.service_durations`). Só autorizar a antecipação se a possível espera projetada for pelo menos 2,5 s, com pneus e previsão seguros; esse valor é um **limiar tático**, não previsão exata/resultado contrafactual.
4. Não deslocar paradas críticas, chuva, controle Manual, ordens agendadas V21 ou carros cuja diferença observada sugere garagem livre.
5. Preservar estado da fila FIFO, tempo real de serviço/espera e RNG. O conteúdo do log de coordenação distingue estimativa de resultado.
6. Introduzir revisão esportiva `019_last_legal_pit_queue_v1`, preservando replays `018_pit_coordination_v1` com a coordenação anterior. O flag de sessão fica fora do hash/checkpoint e o schema de save permanece 1.

## Testes exigidos antes de integrar

- `tests/pit_queue_prevention_066971_test.gd`: V9→V8 plausível, corredor livre sem antecipação, chuva, pneu crítico, Manual, última entrada inválida, pureza, hash e compatibilidade de replay 018.
- Regressões `pit_coordination_06697_test.gd`, `team_pit_06497_{unit,integration}_test.gd`, `pitwall_prediction_06696_test.gd`, SaveGuard e agendamento V21.
- Rodar novamente o **mesmo** Pit Wall Analyzer `ita_dry_auto` e `ita_manual_v7` (mesmas seeds 13660 e 13663, 10 voltas), comparar quantidade e segundos reais de fila por equipe e paradas sem ocultar `REVIEW`.
- Rodar Monza 53 voltas, 20 circuitos, replay determinístico (inclusive 017/018), Windows/Linux e Quality Gate. Mudança esportiva 018→019 exige comparação de resultados entre seeds **dentro da mesma revisão**; hashes novos não precisam ser iguais aos da 018.
- Se a execução mostrar regressão ou fila não evitável, ajustar/reverter somente este patch. **Não declarar PASS até o workflow efetivamente concluir.**

## Rollback

A `main` não foi modificada. Descartar a branch candidata, caso falhe. Em caso de integração futura e regressão confirmada, usar `git revert` no commit de merge corretivo, nunca reescrever o histórico.

**Relacionado:** [issue #82](https://github.com/Jugadru/APEX-Simulation/issues/82) · [v9.7 integrada](APEX_RELEASE_v0.6.6.9.7_PIT_COORDINATION_2.md)
