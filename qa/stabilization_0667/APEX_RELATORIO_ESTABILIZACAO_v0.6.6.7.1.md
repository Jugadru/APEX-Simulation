# Auditoria técnica e estabilização APEX v0.6.6.7.1

## Finalidade

Corrigir todos os problemas **comprovados** nos retestes da versão 0.6.6.7 antes de iniciar novas funcionalidades. Código esportivo, apresentação TV, formatos de saves e resultado 2012 preservados.

## Defeito confirmado no jogo

O processo `RaceEngine.schedule_pit` encaminha pedidos para `RaceReplay.enqueue` durante a gravação. Entre o clique e o tick seguinte, o estado `pit_scheduled_lap` permanece zero. Duas ordens na mesma atualização de interface conseguiam entrar no mesmo tick. Prova original: piloto 1 e piloto 2 agendados na volta 1, **2 comandos na fila**. Após a correção da ordem conflitante: piloto 1 volta 1, piloto 2 sem agendamento, **1 comando na fila**; um pedido posterior para o segundo piloto na **volta 2** é aceito. O bloqueio ocorre no registro de comandos novos; *não* reescreve replays legados.

## Falhas de testes antigas

- O teste de interface `pitwall_0649_ui_test.gd` exigia execução imediata: atualizado para `step_tick()` e comprovado visualmente em 1600×900 e 1920×1080.
- O teste de integração `core_0640_pitwall_intelligence_test.gd` tinha 5 verificações desatualizadas: comandos passam pela fila e a autonomia ativa é guardada em `replay_session.policy.fingerprints`. Teste corrigido **PASS**.
- A migração do Soul Staff e a integração pesada do replay anteriormente inconclusivas passaram em execução isolada.

## Bateria executada

| Cenário | Evidência | Resultado |
|---|---|---|
| Proteção contra double-stack no mesmo tick | `pitwall_same_tick_original_0667.log` e `pitwall_same_tick_fixed.log` | **PASS** no hotfix |
| Interface Pit Wall 1600/1920 | `pitwall_ui.log` e PNGs | **PASS** |
| Inteligência Pit Wall 0640 | `core_0640_pitwall_queue_aware.log` | **PASS** |
| Replay unitário (1/2/5/16/32x) | `replay_unit.log` | **PASS** |
| Compatibilidade binária do arquivo replay | `binary_replay_compat.json` | **PASS** |
| Proteção V21 vs chuva V4 | `replay_boundaries.log` | **PASS** |
| Staff/saves antigos | `staff_migration.log` | **PASS** |
| Integração pesada do replay | `replay_integration.log` | **PASS** |
| TV e Racecraft | regressões registradas em JSON | **PASS** |
| Silverstone, Spa, Monza, Singapura (3 voltas) | quatro arquivos `gp_*.log` | **PASS** |
| Navegação replay histórico Monza 24.431 ticks | `monza_53_historical_seek.log` | **PASS** |
| Monza nova corrida 53 voltas e replay completo | `monza_full_report.json` | **PASS** |
| 20 campeonatos administrativos, 400 resultados | `career_20_seasons_stress.log` | **PASS (somente dados)** |

## Medições de Monza

- 53 voltas, 24.431 ticks, 24 carros classificados e 24 posições únicas.
- Corrida: **624.322 s**. Replay integral: **539.264 s**.
- Hash esportivo histórico idêntico: `2a7e27179177858b8754a0c65666b325499e4aa13d423de060181b11d9ae1c4b`.
- A nova corrida foi iniciada antes da alteração de proteção da fila neste diretório de projeto. Essa alteração só incide no novo `schedule_pit` manual enfileirado; o fixture completo usa `order_pit` e não tem seu código esportivo alterado. A proteção em si foi testada na versão corrigida, e os replays curtos rodaram após a alteração. Não atribuir a execução longa isolada a um benchmark pós-hotfix A/B.

## Limitações e próximos riscos

- A gravação curta em ambas as versões produziu o mesmo arquivo binário, SHA-256 `a1f43f63fae9624f6c5300cdd95f735370574d2cf4e72f99882d62af00d38c1d` (161.096 bytes).
- O teste de 20 campeonatos usa classificações sintéticas para forçar save/load; não roda 400 GPs reais, não altera calendário histórico 2012, nem comprova carreira jogável por 20 anos.
- Renderização visual validada no ambiente Linux com Xvfb/Mesa; sem prova de desempenho em GPU dedicada.
- Não foi feita inspeção manual de todas as telas de gerenciamento. Qualidade final em hardware de usuário requer teste de aceitação.
- Preservar o arquivo anterior v0.6.6.7 para rollback até o jogador aprovar o hotfix.

## Fontes de prova

Os arquivos de logs e os testes GDScript estão incluídos no pacote completo, em `qa/stabilization_0667/` e `tests/`.
