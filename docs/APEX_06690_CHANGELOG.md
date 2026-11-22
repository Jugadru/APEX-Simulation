# APEX v0.6.6.9.0 — Performance Baseline 2.0

Status: **DRAFT / QA REQUIRED — not released or merged**.

Base main: `fef1ceed6604fc97c9bb8a34b71cd4e5c931da2d`. PR: [#64](https://github.com/Jugadru/APEX-Simulation/pull/64).

## Change log (diagnostics only)

- Reuses `scripts/debug/apex_perf_trace_0657.gd`, official RaceEngine, Replay, existing 2D/3D/HUD and telemetry. There is no duplication of Core 2 or a seventh refactor.
- Adds `tests/performance_baseline_06690.gd` for synthetic headless 24-car speed CPU metrics; verifies final hash against independent same-tick reference.
- Extends `apex-benchmark.yml` to collect speed matrix (1, 10, 16, 32), circuits GBR/ITA/BEL/SIN, wet tests BEL/SIN, profiler ON/OFF, process RSS and machine-readable logs.
- Adds `tests/performance_baseline_native_06690.gd` and runs it from the existing screenshot workflow with an actual rendering loop. Both supported view sizes, 3D at 1× and automatic 2D at 10×–32×. Virtual display uses software rendering and cannot represent the user's GPU.
- Extends endurance CI with the existing full-distance Monza 53-lap recording and full replay integrity check.
- Makes relevant CI checks run for the new diagnostic benchmark change, preserving existing workflows and their normal scope for unrelated PRs.
- Adds documentation for measurement limitations, replay and save invariants, and release gates.

## Exclusions

No changes to racing rules, pit stop mechanics, weather, tyres, RNG, 2012 roster, deterministic stepping, replay persistence, save schema, game title, or public release. No performance optimization is claimed.

## Acceptance

All required workflows for final commit must pass, including long-race replay, Pit Wall regressions, native graphical benchmark, visual A/B, saves, exports and 20-circuit scenario matrix. Quality Gate must report readiness rather than merely returning a green audit job. Any regression blocks merge. Native physical GPU FPS is a separate PC-target validation and must be labeled NOT_RUN until performed.

## Preliminary evidence, before final QA

The earlier candidate `c7f7d8e97bff222163c91777e6f5eab070e9d228` passed four headless Monza speeds, short GBR/BEL/SIN races, wet BEL/SIN cases and A/B sporting hash verification. A/B time difference was approximately −0.12% (not a proven improvement). These are not evidence for later SHA(s); final CI must run again.
