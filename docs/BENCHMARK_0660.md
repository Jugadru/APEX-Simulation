# Benchmark e limites — APEX 0.6.6.0

Godot 4.7.2 oficial, i5-7500, GTX 1650, Linux/X11, Forward+/Vulkan. Três repetições alternadas por versão/resolução, sem testes headless concorrentes. Mesmo roteiro nativo: Silverstone/24 carros/seed6558, 1×, 30 frames de aquecimento, 180 frames medidos, 90 pausados. Resoluções verificadas no viewport e PNG. Medianas das médias por execução.

| Resolução | CPU principal 0659 → 0660 (ms/frame) | Frames/parede 0659 → 0660 | CPU pausada 0659 → 0660 (ms/frame) |
|---|---:|---:|---:|
| 1600 | 11.352 → 6.271 | 50.32 → 59.91 | 1.396 → 1.363 |
| 1920 | 11.066 → 6.228 | 52.54 → 59.91 | 1.348 → 1.383 |

Esta versão muda o contrato de tempo: passos fixos de 0,20 s em vez de passos dependentes de cada frame. Logo, não há promessa nem expectativa de paridade esportiva com a 0659; os hashes antes/depois são distintos. Repetições dentro de cada versão são iguais. A cena de benchmark termina em 3,4 s simulados na nova versão e aproximadamente 3,5 s na antiga por causa do acumulador; são cargas curtas comparáveis, não posições esportivas idênticas. Resultados não provam desempenho de GP inteiro, pico de memória, tempo de GPU ou ganho em todo hardware. Frames/parede inclui vsync e scheduler.

O ensaio inicial de custo a passo 0,05 s mediu aproximadamente 3,98 ms de motor e 2,65 ms de hash por tick. Adotado 0,20 s, passo máximo nominal do Core 2, e removidas cópias profundas redundantes no hash. Aceleração 32× produz os mesmos ticks, mas pode acumular atraso se a máquina não acompanhar; backlog não é descartado. O limite é 16 ticks por frame, não 16 ticks por corrida.

## Correção de regressão durante o desenvolvimento
A primeira matriz indicou custo elevado da HUD após invalidar seu cache a cada tick. O profiler identificou recomputação de aconselhamento. A correção preserva o cache visual, mas usa um cache separado e vazio nas decisões esportivas de cada tick. A matriz anterior foi preservada em before_cache_fix; as medianas acima são da repetição após a correção. O GP curto manteve seu hash esportivo exato.

## Gravação e seek
Checkpoints a cada 300 ticks (60 segundos), retendo inicial e os oito mais recentes. Log e hashes até 400000 ticks. Seek para trechos antigos reconstrói desde o início se o checkpoint correspondente foi descartado; é síncrono e pode demorar em corridas longas. Não há alegação de seek instantâneo.

- gp_BEL_Seco.json: 3 voltas, 1957 ticks; corrida 13.22 s de CPU/parede headless, replay 13.04 s; pacote em memória 4.05 MiB.
- gp_CHN_Automático.json: 3 voltas, 1740 ticks; corrida 11.42 s de CPU/parede headless, replay 11.76 s; pacote em memória 3.25 MiB.
- gp_GBR_Seco.json: 3 voltas, 1669 ticks; corrida 13.22 s de CPU/parede headless, replay 13.45 s; pacote em memória 3.23 MiB.
- gp_GBR_Seco_3laps.json: 3 voltas, 1669 ticks; corrida 11.51 s de CPU/parede headless, replay 12.23 s; pacote em memória 3.23 MiB.
- gp_GBR_Seco_3laps_postfix.json: 3 voltas, 1669 ticks; corrida 13.22 s de CPU/parede headless, replay 13.45 s; pacote em memória 3.23 MiB.
- gp_GER_Chuva intensa.json: 3 voltas, 1536 ticks; corrida 10.11 s de CPU/parede headless, replay 10.12 s; pacote em memória 3.11 MiB.
- gp_ITA_Seco.json: 3 voltas, 1553 ticks; corrida 10.22 s de CPU/parede headless, replay 10.30 s; pacote em memória 3.26 MiB.
- gp_SIN_Chuva intensa.json: 3 voltas, 2050 ticks; corrida 13.58 s de CPU/parede headless, replay 13.96 s; pacote em memória 3.89 MiB.
- full_GBR_52laps.json: 52.0 voltas, 26855 ticks; corrida 515.28 s de CPU/parede headless, replay 502.17 s; pacote em memória 86.71 MiB.

Bytes acima são serialização do pacote, não heap/RSS/VRAM. O GP integral mede apenas uma corrida e sua reprodução. Logs/JSONs/capturas originais em qa/replay_0660. O teste baseline_variable documenta que chamadas de RaceEngine.step com diferentes deltas da base já produziam hashes distintos. O ponto de entrada determinístico do jogo é RaceReplay.advance/step_tick, não a antiga API de passo variável mantida para fixtures históricas.

## Reprodução
`tests/replay_0660_test.gd`, `replay_0660_boundaries.gd`, `replay_0660_integration.gd`, `replay_0660_weather.gd`, `replay_0660_gp.gd`. GP aceita APEX_TRACK, APEX_WEATHER e APEX_FULL=1. Benchmark nativo `tests/geometry_0659_benchmark.gd`: APEX_BENCH_WIDTH=1600/1920, APEX_BENCH_OUTPUT e APEX_BENCH_SCREEN=1. Use XDG_DATA_HOME isolado. Compatibility foi testado separadamente, não incluído nas medianas Forward+.
