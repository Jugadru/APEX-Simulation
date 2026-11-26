# APEX 9.23 — integrated engineering plan / first increment

Base game f57f383e967da14745c4d70f3121618d3058fdf3; private Lab e3494473d7fc642a0209980802367f4f72dc4a1e. Version remains 9.22 until 9.23 completion. See AGENTS.md, CHANGELOG.md, APEX_LAB_KNOWLEDGE_INDEX.md, APEX_NATIVE_GRAPHICS_REVIEW.md and APEX_AUTONOMOUS_ENGINEERING_LAB.md. The approved external product roadmap is not replaced.

| System | Initial classification | Remaining work |
|---|---|---|
| 01 Race Performance Engine 2.0 | Partial | Preserve REV1; measured bottlenecks only |
| 02 Spatial Context Cache | Partial | Existing per-call geometry and scalar caches; expansion needs prospective evidence |
| 03 Adaptive Scheduler | Needs correction | Explicit slower speed transition discards whole unsimulated wall-clock debt; retain fractional phase |
| 04 Race Quality Analyzer | Partial | Reuse RacecraftAudit and Lab sporting fixtures; extend only missing useful diagnostics |
| 05 Race Quality Center | Partial | Extend existing F8 profiler, not a parallel lab |
| 06 Race Behaviour Polish | Experimental/evidence dependent | Reproduce and correct actual sporting failures |
| 07 Smart Graphics | Partial | Existing optional GTX1650 profile; targeted settings/visual work |
| 08 HUD Optimization | Partial | Existing throttling and hidden-widget skips; measure/select remaining redundant updates |
| 09 Radio Polish | Partial | Existing TTS, subtitles and priority; fix proven audio/queue issues |
| 10 Advanced Architecture | Experimental/evidence dependent | No speculative C++/threading migration |
| 11 Endurance Laboratory | Existing infrastructure | Reuse FAST/domain tests; long endurance only with explicit authorization |

Historical ABC 45742636267/1 remains INCONCLUSIVE. REV1 (#142) is integrated; REV2 (#143) stays draft. Native REV1 effective ~14x at 16/32x is not a 32x result. No new local test, ABC, FULL or release. Use official FAST on each exact SHA; supplemental hosted Lab only for relevant domain.

## Increment 1 — scheduler transition
Code inspection: interactive backlog can contain up to 12 requested steps at 32x; previous controller changed only sim_speed and displayed speed counters. On explicit reduction to 1x, advance() consumes existing whole-step demand without the high-speed budget, potentially jumping ahead in wall time. Fix in interactive controller and replay transport, not in sporting engine. Keep fractional phase; don't alter pause, upshift, legacy advance() or archives. Acceptance: exact next-tick hash/RNG/commands, no step without new demand, fractional remainder, exact boundary, pause and fast-to-fast reduction, official FAST on candidate SHA. No claimed CPU throughput gain. Rollback: revert this increment; no migration needed.

Next increment after validation: light Quality Center/Analyzer integration using current F8 and RacecraftAudit, followed by targeted HUD/Radio/Graphics improvements; revisit sporting behavior and architecture only on reproducible evidence. All 11 retained; separate smaller PRs if scope warrants.


## Increment 1 closure
PR #154 merged at 6fe26c6557f47568f8998dc663467bf6ad8b4749; candidate f5ecc0cd4e5da98b45f580f8dd5d42cf53d61e9d. Official FAST run 45871763438 PASS (including 16 performance smoke checks and REPLAY_UNIT_PASS), hosted replay command 45871767430 five cases PASS. Independent Codex review blocked by account limit; no native GPU or FULL.

## Increment 2 — Race Quality Analyzer
Existing RacecraftAudit already counts tactical events. Extend that observer, rather than build a second Lab: bounded integrity counters and samples, finite state, grid/position/identity integrity, tyre wear, negative pit/gap and backwards on-track progress. Distinguish pit/finished transitions, skip comparison across gaps, explicit observed coverage, preserve diagnostics through hot seek. No new sporting rules or numerical score; absence of findings is not certification. No automatic correction. Candidate acceptance: injected faults identified, no repeated same-tick observations, bounded samples, pit/finish exclusions, checkpoint coverage, read-only state and tick-by-tick hash parity, hot-seek parity, normal FAST. No native benchmark or throughput claim. Next: F8 Quality Center consumes the existing report (not a parallel system). Rollback: revert this increment, no save migration.


## Increment 2 closure
PR #155 merged at 3a767267c24305e1c6f9df5c3a4b48a0c4c84270; candidate 4ee2045bb30f007c839e6470e2c9558fb27dda6d. FAST run 45874861005, 214 quality checks and replay/CPU smoke PASS; simulation command 45874864587 three cases PASS. Six additional sporting workflows PASS; skipped not counted. No independent submitted review before merge, no native GPU/FULL and no measured incremental observer overhead.

## Increment 3 — Race Quality Center
Extend existing F8 window, retaining CPU profiler and original JSON. New tab consumes existing bounded quality report; display explicitly inactive, not observed, disabled, partial and observed coverage. Requested and measured acceleration separated; measurement validity reset on session or speed change. New combined diagnostic export, no extra observer or scoring. Only active tab rebuilt on existing 0.5s interval. Acceptance: actual F8 window, both tabs, state/coverage and export correctness, exact sporting hash before/after panel operations, two fresh software-rendered frame captures and normal FAST on candidate SHA. No native GPU or visual review claim. Next: HUD Optimization after validation. Rollback: revert this increment; no save migration.


## Increment 3 closure
PR #156 merged at 626f8906965d5e78cbcb0e0d4ccf15e6c4a99667; exact candidate 3c3ee9a8cd1c09f25311c0abc433a332278bc658. FAST 45878241985 PASS, F8 fixture 26/26, software framebuffer captures at 1280 and 1600 saved, existing replay and Lab checks PASS. No independent submitted review before merge; no native GPU, human visual review or FULL.

## Increment 4 — HUD Optimization
Source evidence: HudRaceGaps066916.observe is quadratic and only consumed by ranking metric 7 (DIST. PISTA); previously runs every HUD refresh for all eight metrics. Gate the projection on that metric and clear stale data when leaving; use presenter-provided order only within the same synchronous refresh (no persistent cache). Keep independent callbacks, sporting behavior, update cadence, radio and all controls. Acceptance: existing race_gaps fixture expanded with zero unused projections at 1/16/32x, exact original 24-row radar/text/tooltip parity, immediate paused selection, clearing stale hints, no sporting hash changes, official FAST. No native or throughput claim; no new Lab/workflow. Other HUD optimization proposals require separate evidence; next Radio Polish after validation.
