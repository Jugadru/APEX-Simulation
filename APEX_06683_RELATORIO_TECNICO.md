# APEX Motorsport Manager v0.6.6.8.3 — Relatório técnico

**Base:** v0.6.6.8.1, Core 2 / HUD ReBroadcast QA. **Next Engine não incluída nem ativada.**

## Objetivo único
Reduzir o custo CPU das cópias internas congeladas que o Core 2 cria a cada tick para calcular física simplificada, ritmo e Racecraft, sem alterar estados, comandos, eventos ou hashes.

## Auditoria do código
`scripts/race_engine.gd` executava `entry.duplicate(true)` em cada um dos 24 carros a cada tick em `_advance`. Essas cópias traziam histórico de stints, estrutura de estratégia, soul e arrays que **não são utilizados** pelos consumidores desse snapshot em um tick: `RacePerformance.evaluate` e `RaceSpace.plan`. Foram examinados os usos desses campos.

## Alteração implementada
Substituída apenas a cópia interna de cada carro por `entry.duplicate(false)`, que mantém uma **cópia independente das chaves escalares** usadas pela simulação. Os módulos consumidores leem apenas esses valores; `TyreThermal.advance` aplica primeiro as mudanças no carro real e transfere valores escalares para a cópia. Arrays e dicionários internos passam a ser referências compartilhadas, portanto este snapshot é **restrito ao uso interno de leitura**, não podendo modificar membros aninhados. A fronteira pública `get_state_snapshot`, codec de save e replay **continuam usando cópias profundas**, sem mudança.

A versão foi identificada no `project.godot` e no título da janela; não alteramos HUD, física, regra esportiva, parâmetros de pilotos, trajetória, dados ou formatos de save.

## A/B e determinismo
Os quatro circuitos (GBR seco, BEL chuva intensa, ITA seco, SIN chuva intensa) executaram 750 ticks cada. Nos ticks 1/250/500/750, hashes e a classificação resultante coincidiram com a base **antes da alteração**; eventos, desgaste, compostos e número de ticks também coincidiram. O teste de Spa manteve V21 agendada, sem antecipação.

Benchmark A/B headless de Monza seco, seed 660, 24 carros, 750 ticks: duas duplas de processos Godot 4.7.2, com o mesmo hash final `f39d9736c199bcf1a3994082678c3e943040aee67bb79e1c9117f4ee842be4b0`. Mediana do custo de `race.snapshot`: **641,010 ms** na base vs **360,106 ms** nesta atualização, queda observada de **43,82%** nessa etapa. Mediana do tempo de parede pelos 750 ticks: **7132,170 ms** vs **6449,328 ms** (queda observada de **9,57%** nessa amostra). A terceira dupla planejada não terminou devido a limite de tempo. **Amostra insuficiente para promessa de ganho global ou FPS.**

## Regressões
- `replay_0660_test.gd`: PASS, 200 ticks, replay, salvar/carregar, 1×/2×/5×/16×/32×.
- `hud_rebroadcast_06681_pending_orders.gd`: PASS, 30 verificações; V21, cancelamento, PBOX.
- `hud_rebroadcast_06681_camera_policy.gd`: PASS, 18 combinações, 2D/3D automático/manual, headless.
- `hud_rebroadcast_06681_replay_isolation.gd`: PASS, seek 150/320/0.
- `driver_dynamics_0661_test.gd`: PASS, 17 verificações.
- `racecraft_0662_test.gd`: PASS, 1027 verificações, 500 ticks.
- `pit_incidents_double_stack_test.gd`: PASS.
- `pitwall_06491_stint_reset_test.gd`: PASS.
- `replay_0660_gp.gd` GBR chuva intensa, 3 voltas, 1786 ticks, com pit service, reparo e replay: PASS.

**Ocorrência de infraestrutura nos primeiros testes:** ao iniciar três processos de HUD antes de importar o conteúdo na pasta extraída, Godot emitiu erros de importação de SVG apesar do status impresso PASS. Estes resultados foram **descartados**. Uma importação headless do editor foi executada com status 0 e os três testes de HUD foram repetidos sequencialmente, agora sem erros. A matriz registra somente os retestes válidos.

## Limites e pendências
Corrida completa de 53 voltas de Monza, GPU real/FPS, 20 GPs e teste interativo de longa duração: **NOT_RUN** nesta atualização. O aumento de FPS deve ser medido no PC do usuário; o A/B testa tempo de CPU, não taxa de quadros renderizados. O Core 2 permanece o motor esportivo principal.


## Validação da entrega reextraída
CRC e SHA-256 do ZIP foram conferidos. A primeira importação headless **padrão** do Godot 4.7.2, na extração limpa, apresentou **FAIL** (SIGSEGV durante a importação de um CSV, com mensagem de thread `propagate_notification()` no editor). A tentativa seguinte com `--single-threaded-scene` terminou com saída 0 (**PASS**). Em seguida, o teste de equivalência de quatro circuitos foi executado nessa extração limpa (**PASS**) e a HUD de ordens pendentes repetiu 30 verificações (**PASS**). A ocorrência é documentada; não há prova de ser causada pela otimização. Recomendamos importar no editor gráfico habitual do PC de destino e, se necessário, usar a flag de contorno.

## Rollback
Feche o jogo; mantenha a versão v0.6.6.8.1 extraída em pasta separada. Para voltar, abra o `project.godot` da versão anterior. Salve/copie o diretório de saves antes de trocar versões. `config/custom_user_dir_name=APEX_0650_SOUL_STAFF` não foi alterado, nem formatos de save e replay.
