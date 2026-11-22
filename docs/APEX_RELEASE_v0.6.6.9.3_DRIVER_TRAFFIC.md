# APEX v0.6.6.9.3 — Driver Traffic Intelligence (integrada)

- **PR de implementação:** [#73](https://github.com/Jugadru/APEX-Simulation/pull/73), integrada à `main`.
- **Commit integrado:** `52ece869120b979dabb777de22a2be4acf0dd0a1`.
- **Commit testado:** `efa047589586bbc4fc7e9e346bd69235a52798fc` (mesma árvore de arquivos do commit integrado).
- **Base anterior:** v0.6.6.9.2, `8e0490be3d4d20459354971c766c1179acd2d7bc`.
- **Motor/runtime:** Godot 4.7.2, temporada 2012, Core 2.

## Mudanças esportivas

- `race_driver_traffic_06693.gd`: avaliação pura e determinística do encontro com retardatário; considera distância, consciência espacial, largura, chuva e lado escolhido para ultrapassagem.
- `race_space_0655.gd`: integra a cessão antecipada de espaço ao solucionador de corredores, sem impulsos de posição, sem RNG adicional e sem alterar a física a partir da HUD.
- `race_engine.gd`: controle da compatibilidade de tráfego para sessões de replay histórico.
- `race_replay_0660.gd`: revisão esportiva nova `016_driver_traffic_v1`; replays da v9.2 são reproduzidos com regras históricas, mantendo o marcador da revisão original.
- `race_state_codec_0660.gd`: exclui o controle de compatibilidade do esquema de checkpoints e do hash esportivo para preservar saves/replays antigos.
- `tests/driver_traffic_06693_test.gd`: testes de chuva, largura, carros nos boxes, determinismo, passagem esquerda/direita e paridade do replay.
- `project.godot`: identificação interna v0.6.6.9.3.

## Evidências executadas

| Verificação | Resultado |
|---|---|
| Workflows de CI no commit testado | **16/16 PASS** |
| [Quality Gate](https://github.com/Jugadru/APEX-Simulation/actions/runs/44944744292) | **READY 10/10** após reexecução da auditoria |
| Driver Traffic, Driver Dynamics, Core 2, GdUnit4 | PASS |
| [SaveGuard](https://github.com/Jugadru/APEX-Simulation/actions/runs/44944744315) | **PASS — 53 verificações**, replay v9.2 de 350 ticks, saves e checksums preservados |
| Scenario Matrix (20 circuitos, quatro grupos) | PASS (um grupo necessitou repetir importação Godot) |
| [Endurance Monza](https://github.com/Jugadru/APEX-Simulation/actions/runs/44944744360) | **PASS**, 53 voltas, 24 carros, 24.237 ticks, replay integral idêntico |
| Exportação [Windows/Linux](https://github.com/Jugadru/APEX-Simulation/actions/runs/44944744266) | PASS, identidade interna conferida e smoke Linux |
| Visual A/B, Race Intelligence, Pit Wall | PASS |

### Medições de CPU

Benchmark A/B headless, Monza seed 660, 24 carros, 1.000 ticks, mediana de 3 repetições: **7,0973 ms/tick na v9.2 e 7,2154 ms/tick na v9.3** (+1,66% no runner; cenário curto sujeito a ruído).

Monza completa na CI: **211,18 s** para 24.237 ticks gravados, mais **240,05 s** de reprodução; no arquivo de 13 janelas, início 7,52 ms/tick, trecho intermediário 9,05 ms/tick e última janela 6,21 ms/tick. Esses valores não medem a velocidade 32× no desktop nem FPS da GPU.

**Pendente:** investigar throughput sustentado e lentidão em 32×. A [issue #74](https://github.com/Jugadru/APEX-Simulation/issues/74) guarda o acompanhamento. Nenhum tick foi descartado para mascarar custos.

## Limitações e rollback

Esta versão não implementa punições formais de bandeira azul, rádio de aviso ou stewarding completo; são escopos futuros. O teste Windows validou a exportação e o conteúdo, mas não houve execução gráfica em hardware Windows real. O SaveGuard exercitou os arquivos e commits selecionados, não todas as versões históricas; restauração automática de `.bak` não foi adicionada.

Para rollback, usar a versão anterior v0.6.6.9.2 no commit `8e0490be3d4d20459354971c766c1179acd2d7bc`. Saves de usuários não foram sobrescritos.
