# APEX Motorsport Manager — Performance Baseline 2.0
Version: v0.6.6.9.0 (diagnostic candidate, NOT a release)  
Reference main SHA: `fef1ceed6604fc97c9bb8a34b71cd4e5c931da2d`  
Working branch: `perf/06690-performance-baseline-2`

## Scope and invariant

This change adds **only an observational performance baseline**. It does not modify Core 2, physics, tire model, weather, pit strategy, RNG, replay format, checkpoints, save schema or graphics settings. Refactorings 01–06 are treated as finished, and no Refactoring 07 is started.

## Existing instruments reused

- `scripts/debug/apex_perf_trace_0657.gd`: bounded aggregate inclusive CPU scopes, counters and Godot monitors.
- `scripts/race_engine.gd`: sport tick and overtaking/pace/snapshot scopes.
- `scripts/core/race_replay_0660.gd`: 0.2 s deterministic sporting ticks, `advance()`, checkpoint and hash mechanisms.
- `scripts/apex_telemetry.gd`: positions, events, sectors and laps histories.
- `tests/high_speed_growth_066723_benchmark.gd`: existing long-running tick/memory growth probe.
- Existing separate visual/HUD probes: `tests/hud_rebroadcast_0668_benchmark.gd`, `tests/strategic_2d_benchmark_066722.gd`, `tests/visual_stutter_06672_benchmark.gd` and `tests/perf_0657_visual.gd`.

Known historical observations from `docs/BASELINE_PERFORMANCE_0657.md` include costs from race overtaking, race snapshots and visual occupancy. Those measurements describe an earlier baseline; **they are not measurements of this candidate or proof of a current bottleneck**.

## New diagnostic

`tests/performance_baseline_06690.gd` uses season_2012.json, the official 24-car RaceEngine, the official Replay and the existing Perf helper. It takes synthetic 60 Hz input deltas at 1x, 10x, 16x and 32x. For each run it records:

- season JSON parsing and race/replay session setup time (not entire cold startup);
- CPU wall time for the synthetic `advance()` loop, tick count, simulated time, time per tick and CPU frame p50/p95/p99/max;
- number of frames exceeding 16.667 ms **CPU cost**, not reported as game FPS;
- events, telemetric position/event/lap growth, retained replay checkpoints and Godot static memory;
- inclusive existing profiler sections and environment metadata;
- the final sport hash and an independent reference run at **the same number of ticks**.

A different hash fails the test. Telemetry observer, profiling and replay hashes must not change sporting decisions. Every report records methodological limitations.

**Important**: the benchmark does not pace frames to actual elapsed display time and runs without rendering. Its requested 1x/10x/16x/32x settings do **not** establish achieved real-world acceleration. It runs without interactive frame budget/backlog limits, and cannot prove native UI responsiveness, GPU speed, FPS, % CPU or process RSS. Separate native windowed measurements are mandatory for those claims.

## How to run

First import Godot 4.7.2, then run (from repository root):

```bash
godot --headless --path . --import
mkdir -p baseline-06690
for speed in 1 10 16 32; do
  APEX_BASELINE_SPEED="$speed" \
  APEX_BASELINE_TICKS=180 \
  APEX_BASELINE_TRACK=ITA \
  APEX_BASELINE_WEATHER=Seco \
  APEX_BASELINE_SEED=660 \
  APEX_BASELINE_PROFILE=1 \
  APEX_BASELINE_OUTPUT="$PWD/baseline-06690/monza-${speed}x.json" \
  /usr/bin/time -v godot --headless --path . \
    --script res://tests/performance_baseline_06690.gd \
    > "baseline-06690/monza-${speed}x.log" 2>&1
done
```

To assess observer overhead, repeat the same workload with `APEX_BASELINE_PROFILE=0` and then `1`, at least three runs per setting. Compare medians, ranges and sporting hashes. `/usr/bin/time -v` gives an external Linux peak-RSS measurement, not the Godot `MEMORY_STATIC` monitor. Use dedicated hardware CPU monitoring to obtain process CPU%.

For broader coverage, repeat with `APEX_BASELINE_TRACK=GBR`, `BEL` and `SIN`, and wet conditions, using fixed seeds, identical work and isolated reports. Increase `APEX_BASELINE_TICKS` in a controlled manner for time-series analysis.

## Distinct native presentation measurements (not covered by headless baseline)

Use the current native visual/HUD scripts and a real GPU/window at 1600×900 and 1920×1080. Compare 2D, 3D, map updates, HUD refresh, camera occupancy and frame-time p50/p95/p99 at the same race state; include frame pacing and GPU metrics when supported. At high speed, record both *requested* and *achieved* race acceleration under actual wall time. The project currently switches automatic presentation to 2D from 10× upward; test any manual overrides separately. The headless benchmark must never be treated as proof of stable 60 FPS.

## Required QA before merge

1. Godot 4.7.2 import and script compilation.
2. New benchmark, 24 cars, four target speeds, reproducible results and independent hash verification.
3. Silverstone, Monza, Spa and Singapore; include the 20-track matrix where applicable.
4. Long official 53-lap Monza recording and deterministic replay verification.
5. Existing Pit Wall V21/V4, double-stack, weather, Racecraft and save/load regressions.
6. Existing visual tests and real-world measurements on the target PC.
7. GitHub Actions checks for the *exact candidate commit*; evaluate all required/relevant workflows. The repository presently contains 17 workflow YAML files, not all of which trigger on pull requests. The quality gate currently checks 10 named pipelines; the project target of 13/13 does not by itself certify any run.
8. A/B profiler overhead, baseline growth, replay seek, loading and long-race stability.
9. Documentation: measurements, execution environment, caveats, and hashes in artifacts.
10. Only after successful verification, consider a release whose build artifacts match the validated commit.

Statuses at the moment this document was created: Godot import **NOT_RUN**; new benchmark **NOT_RUN**; native FPS **NOT_RUN**; four GPs **NOT_RUN**; replay full distance **NOT_RUN**; save regression **NOT_RUN**; CI **NOT_RUN**. Update with actual GitHub run evidence, never assume PASS.

## Next release

Do **not** proceed automatically to v0.6.6.9.1. Use the measured Baseline 2.0 data to determine whether High-Speed Scheduler needs a specific bounded change, while preserving all ticks and hashes.
