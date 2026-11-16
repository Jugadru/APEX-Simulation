# Baseline de desempenho v0.6.5.7

Medições realizadas no Godot 4.7.2, Linux, Intel Core i5-7500 @ 3,40 GHz (4 threads), GPU NVIDIA GTX 1650 no teste visual. Build debug do editor. Coleta local, sem promessa de equivalência de desempenho em outras máquinas. A v0.6.5.7 instrumenta: não implementa otimizações.

## CPU headless, comparação controlada
Silverstone, 24 pilotos, seed 6557, corrida curta de **3 voltas**, cenários Seco/Chuva intensa. Dois pedidos de pit Ferrari, pneus válidos, incidentes aleatórios de pit desativados neste benchmark. Warm-up idêntico de 8 segundos simulados; medição do loop restante até todos terminarem. Passos de 4s com subpassos internos de até 0,2s. Custo do loop inclui assertivas leves; não inclui inicialização, exportação JSON nem hashing final.

18 execuções: 3 repetições × 3 modos × 2 climas. Execuções seriais, ordem base/OFF/ON rotativa. Mediana e faixa mínima–máxima em segundos de parede. Resultados esportivos completos (carros, classificação, tempos, eventos, pits) iguais por clima nas nove execuções. Não se compara resultado seco com chuvoso.

| Clima | Modo | Mediana s | Min–máx s | Simulação / segundo real (mediana) |
|---|---|---:|---:|---:|
| Seco | base | 6.398326 | 6.339784–6.462924 | 50.64× |
| Seco | off | 6.492849 | 6.475292–6.613514 | 49.90× |
| Seco | on | 6.505680 | 6.484059–6.601948 | 49.80× |
| Chuva intensa | base | 7.120829 | 7.016610–7.243480 | 47.75× |
| Chuva intensa | off | 7.161194 | 7.120816–7.254074 | 47.48× |
| Chuva intensa | on | 7.220606 | 7.085470–7.227689 | 47.09× |

**Overhead observado, não ganho:**

- Seco: OFF versus base +1.48%; ON versus OFF +0.20%. Hash esportivo `0618280f76d1ea1f1580ccf1381c02521a6900fc651e7da82e9dc6b9212d99ff`.
- Chuva intensa: OFF versus base +0.57%; ON versus OFF +0.83%. Hash esportivo `fe69acc40c277e05accab0bcc35b73dc14cbd4ed77be94487e634addce58d4a3`.

Três repetições não permitem afirmar significância estatística para diferenças pequenas; ruído de scheduler/cache/térmica continua possível. Instrumentação desligada mantém branches e variáveis locais, sem consultas de relógio nas seções e sem coleta contínua de monitores. Ligada inclui seu próprio custo nos escopos pais.

## Perfil CPU (uma execução ON seca)
Escopos são **inclusivos**, não somar pais e filhos. `strategy.plan` também pode estar dentro de `ai.pit_decision`; `race.step` engloba subescopos. O profiler limita agregados a 64 seções/64 contadores; não armazena histórico por frame ou piloto.

| Seção | Chamadas | Média ms/chamada | Total ms |
|---|---:|---:|---:|
| ai.pit_decision | 22 | 1.1340 | 24.948 |
| pit.advance | 3771 | 0.0076 | 28.507 |
| race.overtaking | 1620 | 1.6473 | 2668.673 |
| race.pace_thermal_drs_kers | 1620 | 0.6797 | 1101.081 |
| race.snapshot | 1620 | 0.9464 | 1533.159 |
| race.step | 81 | 80.0283 | 6482.289 |
| strategy.plan | 70 | 0.4756 | 33.291 |

As medições desta amostra mostram custo relevante de disputa espacial e snapshot no motor. São prioridades de investigação, não autorização para trocar o snapshot congelado ou modificar regras esportivas.

## Cena nativa Vulkan / Forward+
1600×900, 24 pilotos, Silverstone/seed 6557, 30 frames de aquecimento + 180 frames medidos. O teste chama o process com delta fixo 1/60 para o mesmo avanço esportivo, aguardando frames reais da engine entre chamadas. **`frame.input_delta` é o delta fornecido, não tempo CPU nem FPS medido.** O tempo de parede real permanece livre e inclui renderização/esperas. Painel aberto apenas depois da medição.

Janela ativa: 3.728001s; 180 frames / parede = 48.28 frames/s. Última amostra do monitor Godot: FPS 48.0, frame 31.978ms. Esses monitores têm janela/atraso próprios e não precisam corresponder à média. Memória estática Godot: 171.67 MiB; órfãos 0 no instante amostrado.

| Seção | Chamadas | Média ms/chamada | Máximo ms |
|---|---:|---:|---:|
| ai.team_autonomy | 360 | 0.0670 | 0.1170 |
| frame.input_delta | 180 | 16.6660 | 16.6660 |
| frame.main_cpu | 180 | 14.7287 | 25.2960 |
| hud.update | 12 | 9.7583 | 10.5640 |
| race.overtaking | 180 | 2.1288 | 2.3920 |
| race.pace_thermal_drs_kers | 180 | 0.8109 | 0.9880 |
| race.snapshot | 180 | 0.8231 | 1.0600 |
| race.step | 180 | 4.5245 | 4.9950 |
| route.2d_direction | 4500 | 0.0068 | 0.0290 |
| route.2d_position | 13680 | 0.0016 | 0.0550 |
| route.3d_direction | 12960 | 0.0053 | 2.1280 |
| route.3d_occupied_pose | 4320 | 0.1727 | 4.7220 |
| route.3d_position | 30240 | 0.0007 | 0.0580 |
| visual.build_states | 180 | 1.0861 | 1.3190 |
| visual.maps | 180 | 0.1968 | 0.2940 |
| visual.occupancy | 180 | 6.3386 | 11.3030 |
| visual.world_3d | 180 | 7.9188 | 15.2330 |

A ocupação visual e sua projeção 3D pesam mais que consultas 2D nesta amostra. O HUD tem custo por atualização maior, porém atualiza menos vezes (0,25s). Não comparar custo de uma chamada de HUD com um frame inteiro sem ponderar frequência. Não houve medição de tempo GPU, RSS do processo, percentis de longa duração nem investigação conclusiva de vazamento; contagem de órfãos zero em uma amostra não prova ausência de vazamentos.

## Reproduzir
Importe cada projeto no Godot 4.7.2 antes do benchmark. Use saves isolados. Execute `tests/perf_0657_race_cpu.gd` com `APEX_BENCH_WEATHER=Seco` ou `Chuva intensa`, `APEX_BENCH_ON=0/1` e `APEX_BENCH_OUTPUT=/caminho/resultado.json`. Para a base, use `--path` apontando para v0.6.5.6 e `--script` com caminho absoluto do script novo: ele detecta a ausência do profiler. Não execute outros benchmarks simultaneamente. Repita três vezes por modo e compare hashes, medianas e faixas. Teste visual: `--script res://tests/perf_0657_visual.gd` sem `--headless` em ambiente GPU.

Evidências completas em `qa/profiler_0657/benchmarks_summary.json`, `cpu_*.json`, `sporting_checks.json`, `native_visual.json` e logs. Capturas do painel em 1600×900 e 1920×1080 não constituem benchmark comparativo de resolução; a medição visual ocorreu em 1600×900.
