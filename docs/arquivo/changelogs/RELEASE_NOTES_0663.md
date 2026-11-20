# APEX Motorsport Manager — Release Notes v0.6.6.3

**Long Race Performance 1.0** · Godot 4.7.2 · F1 2012

## O que mudou
A versão otimiza a retenção dos estados intermediários do replay e a leitura passiva de eventos de Racecraft sem alterar a simulação, a física, o RNG, os comandos, a classificação ou o formato externo das gravações.

- Checkpoints intermediários: estados compactados em memória (ZSTD) e descompactados para busca, restauração e exportação compatível.
- Racecraft Telemetry: acesso aos eventos inéditos sem percorrer repetidamente todo o buffer cronológico.
- Formato do replay e revisão esportiva: `APEX_REPLAY_0660` / `0661_driver_dynamics` **inalterados**.

## Medição A/B executada
Monza com seed 660, clima seco, 24 carros e 4.500 ticks headless no mesmo ambiente Godot 4.7.2:
- v0.6.6.2: **136,09 s**; memória estática Godot **80.612.430 bytes**.
- v0.6.6.3: **131,63 s**; memória estática Godot **39.157.289 bytes**.
- Redução observada: **3,28%** em tempo e **51,43%** em memória estática monitorada.
- Hash esportivo dos 4.500 ticks: **idêntico**.

A memória acima é do monitor Godot, não o uso de memória residente (RSS). Não extrapolar essas medidas para GPUs dedicadas.

## Compatibilidade
- Os quatro GPs curtos Silverstone, Spa, Monza e Singapura reproduziram exatamente os hashes e as contagens observadas na v0.6.6.2.
- Um replay de 650 ticks gerado pela v0.6.6.2 foi carregado e reproduzido na v0.6.6.3, e o replay novo é **byte a byte idêntico** ao anterior nas mesmas condições.
- As velocidades 1x, 2x, 5x, 16x e 32x preservaram os hashes. A ordem manual de pit na V21 não foi antecipada para a V4 em chuva intensa.
- Inventário, oficina, saves, Driver Dynamics, RaceSpace, estratégia, Pit Lane e HUD passaram nas suas fixtures.
- Capturas reais em Godot para 1600×900 e 1920×1080 (OpenGL Compatibility / llvmpipe).

## Corrida oficial Monza de 53 voltas
A corrida ao vivo alcançou a bandeirada com **24.431 ticks**, **24/24 carros classificados**, **24 posições exclusivas**, **24 paradas registradas**, em **544,70 s** de CPU-bound wall time. O replay integral desde o tick inicial foi **APROVADO**, em **531,83 s**, após conferir os **24.431 hashes**, as contagens do Racecraft e o digest integral da telemetria. Hash final: `2a7e27179177858b8754a0c65666b325499e4aa13d423de060181b11d9ae1c4b`. O processo combinado alcançou pico RSS observado de **788,2 MiB** (aproximadamente 175,2 MiB durante a corrida ao vivo e 788,2 MiB durante exportação/replay com estados descompactados retidos). Evidências em `qa/long_race_0663/monza_53.json` e `docs/RELATORIO_TECNICO_0663.md`.

## Escopo e status
A alteração principal é desempenho, sem modificar `race_engine.gd`. Testes de 20 temporadas e de GPU real do usuário não fizeram parte desta entrega. Esta release **não avança à v0.6.6.4**.

Para executar ou reverter a versão, abra `LEIA_PRIMEIRO_0663.md`. Para medições e classificações PASS/FAIL, leia `docs/RELATORIO_TECNICO_0663.md` e `qa/long_race_0663/test_results_0663.json`.
