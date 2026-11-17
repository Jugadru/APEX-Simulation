# APEX v0.6.6.8.8 — Racecraft 2.0 | Relatório técnico

## Escopo
Base oficial v0.6.6.8.7, ZIP SHA-256 `4abc0b0a0eadca91577620b4fd49d3b9a2ff4abb172832c164b99878117780b1`. Godot 4.7.2; **Core 2** permanece motor principal, APEX Next Engine suspensa.

## Problema e solução
O `race_driver_dynamics_0661.gd` permitia uma defesa antecipada baseando-se predominantemente na agressividade e distância ao rival. A regra nova integra `race_defense_grip_06688.gd`, uma avaliação pura/determinística da cautela do defensor, modulada por chuva, desgaste e percepção espacial. Ela modifica **apenas** a escolha de defender cedo. O solver de corredores, ultrapassagens, ritmo e física não foi alterado.

A linha já estabelecida durante uma disputa continua bloqueada; não há segunda mudança defensiva. A regra seca retorna ao comportamento da 8.7. A métrica de cautela é aproximação de gameplay, não modelo físico de aderência real ou índice FIA.

## Incompatibilidade esperada de replay
Como decisões da corrida molhada podem mudar, atualizamos `Replay.SIMULATION_REVISION` de `0661_driver_dynamics` para `06688_grip_aware_defense`. Um replay gerado com regras antigas é rejeitado com erro explícito; replays novos preservam hash e determinismo. O formato dos saves e checkpoints não foi migrado.

## Resultados medidos
- Importação headless no Godot 4.7.2: PASS.
- Teste específico 06688: **27 verificações PASS**, com 200 ticks de replay e agendamento manual BOX V21 preservado.
- Driver Dynamics 0661: **17** verificações PASS; Tyre Judgement 06687: **23** PASS; HUD 06687: **12** PASS.
- Racecraft 0662: **1.027** verificações PASS; double stack, sort contract 06686, modelo 3D e replay 0660 (200 ticks, 5 velocidades): PASS.
- A/B 4 pistas × 750 ticks: **GBR e ITA secos 100% hashes iguais** à v8.7 nos checkpoints 1/80/250/500/750; **BEL e SIN chuvosos divergiram a partir de 500**, resultado esperado de uma decisão esportiva alterada. Em todos os quatro cenários, a ordem final de 24 carros, número de eventos e checkpoints foi igual.
- Replay integral Monza (53 voltas): **avaliação prolongada em andamento**; resultado será registrado antes do merge.

## Limites
Ganho de FPS não é demonstrado (esta é uma mudança de gameplay). Save/load de temporadas múltiplas não foi revalidado. Outras pistas e combinações de chuva não foram completamente homologadas. O novo jogo não recupera replays históricos sob regras anteriores; conserve a versão 8.7 para assisti-los.

## Reproduzir
Executar em Godot 4.7.2 (Linux):

```bash
godot --headless --single-threaded-scene --path . --import
godot --headless --single-threaded-scene --path . --script res://tests/racecraft_06688_grip_defense_test.gd
godot --headless --single-threaded-scene --path . --script res://tests/driver_dynamics_0661_test.gd
godot --headless --single-threaded-scene --path . --script res://tests/racecraft_0662_test.gd
```
