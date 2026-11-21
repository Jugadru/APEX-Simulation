# 14ª melhoria de gameplay — Largada determinística 1.0

## Foco único
Introduzir uma fase curta de aceleração inicial com custo de reação e tração, limitado aos primeiros 8 segundos simulados. O código de corrida continua sendo o Core 2. Trata-se de **modelo original de gameplay**, não reconstrução de telemetria FIA.

## Contrato
- `scripts/core/race_launch_14.gd` calcula o custo puro `pace_cost(car, elapsed_s, wetness)`, sem alterar o carro ou consumir RNG.
- `scripts/core/race_performance.gd` incorpora o custo ao ritmo-alvo **somente** enquanto `elapsed_s < 8`.
- `scripts/race_engine.gd` fornece o relógio da simulação. A fonte de umidade continua sendo o motor de clima.
- Habilidade do piloto e rating do carro reduzem as perdas iniciais; pista úmida amplifica a dificuldade de tração. A perda diminui continuamente até zero.
- Não cria ultrapassagens, teleporte, incidentes, pit stops, desclassificações nem ganhos artificiais de posição.
- Corrida após 8s, decisão de Pit Wall, pneus, save/replay e mecanismo de RNG mantêm seus contratos; **hashes esportivos de corridas inteiras podem mudar legitimamente porque as posições de largada influenciam o tráfego futuro**.

## Evidência necessária para merge
1. Teste Godot `tests/race_launch_14_test.gd`: custo finito, diferenças de habilidade e umidade, decaimento, zero após oito segundos, pureza e repetibilidade.
2. Core 2 CI, GdUnit4, Quality Gate, GDScript e segurança Python PASS.
3. Scenario Matrix (20 circuitos, 2 repetições), se disparada, sem violações novas.
4. Benchmark A/B: não aceitar regressão de desempenho sem avaliar o impacto real.
5. Não declarar testado em GPU/FPS real nem em GP completo sem execução específica.

## Rollback
Reverter isoladamente a PR e retirar `clock` do contexto, `RaceLaunch14.pace_cost` de `RacePerformance.evaluate`, o novo módulo, teste e registro do teste na CI. Nenhuma migração de save é exigida.

## Limitações e evolução posterior
Não simula embreagem, patinagem de roda individual, tempo de reação medido por piloto real, escolha de linha na primeira curva ou acidentes de largada. Não misturar esses sistemas com a 14ª entrega. Uma atualização futura poderá usar atributos próprios de largada, após coletar evidências.
