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
