# APEX Motorsport Manager v0.6.6.7.2.3 — Relatório técnico

**Base:** v0.6.6.7.2.2. **Escopo:** evitar travamento em velocidades altas e reduzir CPU de planejamento de pneus, sem modificar regras esportivas.

## Causa reproduzida

A partir da primeira volta, a IA aciona um otimizador recursivo de stints. Em benchmark controlado, cada planejamento requeria ~57 ms, e o sistema repetia vários planejamentos em eventos de volta e consultas do engenheiro. Além disso, `RaceReplay.advance()` acumulava toda a dívida do tempo real e tentava executar até 16 ticks em um quadro: quando a CPU não acompanhava 32x, a fila aumentava, cada quadro ficava mais longo e o ciclo degradava progressivamente.

## Correção

- `race_stint_optimizer.gd`: substitui chave string formatada de memoização por identificador inteiro sem colisões dentro do domínio de estado; reutiliza uma tabela exata de sufixos para até **28 contextos**, com descarte LRU. Entrada exata serializada como bytes (sem arredondamentos), incluindo perfis de pneus, desgaste futuro previsto, volta, regras de composto e custo dos boxes. **O primeiro stint depende do desgaste atual e é sempre recalculado.** A tabela não entra no RaceEngine, RNG, saves ou replay.
- `race_replay_0660.gd`: parâmetros adicionais opcionais `frame_budget_us` e `max_backlog_steps` em `advance()`. O comportamento sem limites permanece idêntico aos testes/replay históricos; em modo interativo rápido evita-se a espiral de dívida de quadros. **Se a CPU não sustentar o fator solicitado, a velocidade real fica temporariamente menor; não são pulados ticks esportivos.**
- `main.gd`: aplica orçamento de 12 ms de trabalho esportivo por quadro e até seis passos de dívida, apenas para 10x, 16x e 32x, mesmo se a câmera 3D foi selecionada manualmente.
- `apex_race_hud_0622.gd`: informa `CPU` discretamente ao lado do tempo quando a velocidade solicitada está limitada; tooltip esclarece a diferença entre valor selecionado e efetivo.
- `project.godot`, atualização de teste do Auto 2D e novos benchmarks.

## Medições reais, não promessas de FPS

| Teste | v0.6.6.7.2.2 | v0.6.6.7.2.3 |
|---|---:|---:|
| 24 recomendações completas de stints | 1.959,0 ms | 293,9 ms |
| Monza ticks 501–750 (média/tick, com instrumentação) | 36,1 ms | 10,4 ms |
| Hash esportivo aos 750 ticks | `f39d9736...` | Idêntico |

No teste sintético de 60 chamadas de apresentação a `delta=1/60`, foram concluídos **50 ticks a 10x, 80 a 16x e 120 a 32x**. Para 32x, a meta seriam 160 ticks no intervalo; aqui houve saturação e o sistema reduziu a taxa efetiva para ~24x em vez de congelar a interface. Os tempos médios de `_process()` variaram de 11,4 a 16,7 ms nesses cenários iniciais. Esses valores **não são FPS de hardware** e o ensaio não mede o tempo de GPU.

Depois de 1.200 ticks, o teste de 10x completou 50 ticks com média de 14,4 ms/quadro, mas registrou um **pico de 150 ms**. Outro ensaio de 16x terminou os 80 ticks previstos; picos isolados de dezenas a centenas de ms ainda são possíveis durante recálculos de estratégia e atualizações da HUD. **Não foi demonstrado 60 FPS estável em 16x/32x.**

## Regressão

Os GPs curtos de GBR seco (1.668 ticks), BEL chuva intensa (2.067), ITA seco (1.553) e SIN chuva intensa (2.050) terminaram e seus replays foram reproduzidos integralmente com os quatro hashes esportivos históricos. A unidade de replay e o teste de estratégia seca passaram. O mapa 2D Auto continua selecionado a partir de 10x, com opção manual de câmera. Histórico original de telemetria foi preservado.

**Limitações:** não foram executadas nesta versão a corrida completa de Monza 53 voltas, uma carreira de 20 temporadas jogáveis ou testes no PC do jogador. O erro X11 `BadWindow`, a lógica de ultrapassagens e a limpeza geral da HUD continuam fora deste escopo. O limite de orçamento evita travamento contínuo, mas não elimina picos de trabalho que ocorrem dentro de um único tick.
