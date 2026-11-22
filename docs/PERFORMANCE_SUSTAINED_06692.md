# APEX v0.6.6.9.2 — Sustained 32× / sporting-hash field caching

Status: **VALIDATED / INTEGRATED** — PR #70, commit `4c9d05db2fe1fff4c4048bfe46c2f0714940a67b`. QA 15/15 PASS, Quality Gate READY 10/10. One principal change: cache stable *field names* during sporting replay hashing. No changes in HUD screens, pace, tyres, strategies, pit, weather, RNG, fixed-step scheduler, save formats or race rules. This branch is independent of the Work/Codex HUD effort.

## Context and hypothesis

The user tested the previous 2D build with the speed set to 32×: effective speed was around 24× for several laps, briefly 19× and roughly 21× near the finish; CPU use rose only slightly. This is a **player observation**, not a measured A/B attribution. A historic APEX benchmark (`docs/BENCHMARK_0660.md`) found sporting replay hashes took about 2.65 ms of an earlier ~6.63 ms/tick pipeline. We are **not** assuming those older timings hold today.

`Codec.sporting_hash` historically calls `get_script_property_list()` for each race/weather/track-dynamics object **on every tick**, then hashes the complete authoritative data. These declared fields do not change during a running Godot script instance. Caching the ordered **String** names and reading every current value each tick may avoid repeated reflection without changing the serialized hash.

## Implementation

- `scripts/core/race_state_codec_0660.gd`: only the hot-path `sporting_hash()` uses cached ordered names. Public `fields()`, `capture()`, `restore()`, `canonical_hash()`, hashes, checkpoint schemas and replay archives retain the same behavior.
- `scripts/core/race_replay_0660.gd`: when Performance Profiler is explicitly enabled, record the real `replay.sporting_hash` section around the existing hash operation (diagnostic only; no sporting state).
- `tests/hash_cache_06692_test.gd`: for two independent official 2012 races (Monza dry and Spa wet, 24 cars, 1200 ticks each), compare each actual recorded tick hash against the **old uncached v9.1 algorithm**, not just against the optimized function itself.
- `tests/long_race_full_0663.gd`: include every 2000-tick CPU throughput window for the existing full 53-lap Monza live race and the last partial window, showing **beginning, middle and end**, with Godot static-memory monitor, checkpoints, driver laps and telemetry-history length. No extra GP or tick skip. Replay is still verified after all cars finish.

## Acceptance criteria

1. All old-hash comparisons **exact**, every recorded tick; 0 divergences and 24 cars.
2. Whole-GP Monza replays produce equal final sporting hashes and equal telemetry data; preserve real pits and radio decisions.
3. CPU A/B comparison on identical circuit, seed and tick count; report the delta including potential slowdown. Distinguish observed CPU tick throughput from native 2D effective speed and FPS.
4. Endurance window timing (first/mid/end); investigate any deterioration instead of asserting this change fixes the user's 21× finish behavior without evidence.
5. All GitHub CI checks and Quality Gate READY 10/10 on exact commit. No merge or Release until satisfied.

## Limitations

CI headless CPU throughput is **not** Windows/Linux native GPU FPS, frame pacing, or the user's requested 32×. Timing is sensitive to VM load. The new 2000-tick windows measure *full replay live CPU execution* and can include checkpoint spikes; compare distributions and avoid assuming that CPU throughput is equal to interactive acceleration.

## Rollback

Revert the cached field lookup in `race_state_codec_0660.gd`; `sporting_hash` can immediately return to `fields(..., false)` with no save/replay migration. The profiler section and diagnostic test modifications can be reverted independently. This proposal changes no gameplay assets or HUD Work branches.

## Version and distribution integrity

`project.godot` now identifies the game as **v0.6.6.9.2**; `main.gd` and the front-menu footer already read that setting dynamically. The Windows/Linux export workflow checks the packaged `.pck` contents for `APEX Motorsport Manager v0.6.6.9.2` and rejects the old 9.1 and 8.10 application identities. This avoids repeating the stale ZIP title problem experienced in v9.1. No rename of the existing `APEX_0650_SOUL_STAFF` user-data directory: saves remain compatible. A new README download link should point to the final validated v9.2 artifact after merge; the existing 9.1 download must remain until that validation.

## Resultados reais de validação — 21/11/2026

**Evidências e escopo:** os dados abaixo vêm da CI do **SHA exato** `6cabc598ef2318ccf497accadde924c4cd89848c`, cuja árvore de arquivos é idêntica à do merge na `main`. Godot **4.7.2**, F1 2012, 24 carros. [PR #70](https://github.com/Jugadru/APEX-Simulation/pull/70), [A/B](https://github.com/Jugadru/APEX-Simulation/actions/runs/44938862536), [Endurance](https://github.com/Jugadru/APEX-Simulation/actions/runs/44938862442), [Quality Gate](https://github.com/Jugadru/APEX-Simulation/actions/runs/44938862525).

- **15/15 workflows de PR PASS**, incluindo quatro grupos da matriz 20 circuitos, Core 2, GdUnit4, SaveGuard, Race Intelligence, Pit Wall, testes gráficos, benchmark e exportação Windows/Linux. O grupo 1 da matriz foi repetido com sucesso após falha intermitente no Godot durante o import, antes de qualquer cenário.
- Quality Gate reexecutado depois dos demais testes: `APEX_QUALITY_GATE_READY`, `passed=10`, `total=10`, no mesmo SHA.
- Teste específico: 2.400 ticks em Monza seca e Spa molhada, **0 divergências** entre hash otimizado, hash registrado e algoritmo anterior sem cache.
- A/B pareado da CPU esportiva (1.000 ticks, mesmo seed): diferença **−1,38479%**, estado esportivo equivalente. Pequena melhoria observada; não afirmar significância estatística ou equivalência de ganho em FPS.
- Prova integral Monza 53 voltas: **24.409 ticks, 24/24 carros concluídos**, replay integral validado, hash esportivo idêntico ao da v9.1: `dc8b4f2c8b08a741a7db37eac20083ae3e84cee6d95ac6d98841a9f811b75486`.
- Duração live observada, CI headless: **v9.1 210,765137 s**; **v9.2 206,804104 s** (−1,88%). Replay: **v9.1 223,693526 s**; **v9.2 225,885846 s** (+0,98%). São apenas execuções em VM, não constituem teste estatístico nem diagnóstico de desempenho do PC do jogador.

### Degradação de desempenho ao longo da corrida — observação reproduzida

`tests/long_race_full_0663.gd` registrou **13 janelas contíguas**, das quais 12 têm 2.000 ticks completos e a última tem só 409 ticks. Estes são tempos CPU/parede da simulação headless **sem renderização**, não multiplicador efetivo da UI.

| Intervalo de ticks | Volta do líder ao fim | ms/tick (CPU/parede) | Segundos simulados por segundo de parede |
|---|---:|---:|---:|
| 0–2.000 | 5 | 7,521 | 26,59× |
| 6.000–8.000 | 19 | 8,291 | 24,12× |
| 12.000–14.000 | 33 | 8,611 | 23,23× |
| 18.000–20.000 | 46 | 8,855 | 22,59× |
| 20.000–22.000 | 50 | 9,558 | 20,93× |
| 22.000–24.000 | 53 | 9,487 | 21,08× |

O bloco **24.000–24.409** terminou a 5,628 ms/tick, mas não é comparável diretamente com blocos completos: apenas 409 ticks e parte dos carros já havia terminado.

A memória estática reportada pelo Godot nas janelas passou de aproximadamente 55 MB para 75 MB, enquanto o histórico de posições cresceu de 960 para 11.520 registros entre as janelas inicial e final completa. Essa correlação **não identifica isoladamente a causa**: custo de checkpoints, ordenação/estado esportivo, histórico, decisões, renderização e ruído de VM requerem profiling discriminado. Não atribuir a queda especificamente ao hash sem novas provas.

**Conclusão:** a v9.2 reduz modestamente o custo do hash sem mudar replay ou regras. A velocidade de cerca de **21× perto do final** é reproduzida no teste headless de Monza e **não está resolvida**. Alcançar **28–32× no 2D do computador do jogador** continua sendo objetivo posterior; não retirar ticks nem enfraquecer a física para forçar a velocidade indicada.

### Distribuição

[Artefato Windows/Linux v9.2](https://github.com/Jugadru/APEX-Simulation/actions/runs/44938862417/artifacts/14720252805), validade até **05/12/2026**. Ambos os `.pck` foram inspecionados: contêm `APEX Motorsport Manager v0.6.6.9.2`, não as identidades 9.1/8.10. ZIPs íntegros e inicialização Linux headless exit 0. Não foi publicada Release pública nem realizada aferição de FPS na GPU física do jogador. O diretório dos saves continua `APEX_0650_SOUL_STAFF`.

