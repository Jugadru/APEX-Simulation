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


## Increment 4 closure
PR #157 merged at bce1fe830e3a3d66a014012a53d705718ee82200; candidate 55ba69441db20737e239c14f93eda1c450d068ca. FAST 45879382566 PASS, Race Gaps 105/105, additional Race Engineer 45879382552 13/13 jobs PASS. No submitted independent review before merge; no native speed/FPS measurement.

## Increment 5 — Radio Polish
Source evidence: expired speech consumes bounded queue slots; noncritical speech persists at high speed; unavailable-language urgent packets can interrupt audible speech; replay scene refresh rebuilds historical text and can enqueue audio. Keep local optional DisplayServer TTS, original dialogue and visible subtitles. Expire before capacity and delivery, preserve priority and language, enforce fast-speed policy on active speech, explicit retry after no voices, mute replay reconstruction only. Test deterministic backend calls, queue limits, priority, expiry, speed, locale, text-only historical reconstruction and sporting parity via existing FAST. No fabricated audio playback proof, phoneme sync, DSP/voice assets or hardware test. Godot OS speech may depend on installed system voices; native listening and audio effects remain deferred. Next Smart Graphics after validation. Rollback is a revert; no save migration.


## Increment 5 closure
PR #158 merged at 23bec7d48a25aa56a553f7fd4845658e84695f70; exact candidate 3c9b09bc6626b2e8d86847cbba5f31c7ba6b8b1f, FAST 45880337210 PASS, 22/22 queue checks, Race Engineer 45880337108 13/13 jobs PASS. No independent submitted review or audible playback verification. Radio effects remain pending.

## Increment 6 — Smart Graphics
Source evidence: existing GTX1650 launch opt-in is inaccessible in normal race controls; default and historical GTX settings are split across builder and Track3D. Consolidate in Track3D and expose manual runtime choice, preserving default and environment override exactly. Economy option is explicitly experimental (MSAA disabled, Forward+ TAA off, 2 shadow splits/100 units, SSAO off). No automatic degradation, geometry, camera, sporting change, persistent preferences or native speed claim. Acceptance: existing FAST with directed real-scene software UI fixture validating default/GTX/economy property round trip, exact 24-car hash, unchanged models/route/camera and 2D/3D choices, two captures; complementary hosted /lab graphics where relevant. Software compatibility cannot prove Forward+ performance/appearance. Native/visual human review NOT_RUN unless separately authorized. Next Race Behaviour Polish based on reproducible evidence, all eleven objectives retained.


### Increment 6 — first validation failure and correction
Candidate 180ce962641412807e9d16747051e0a3c75f62f3: FAST 45881418318 FAIL (39/40, only "24 actual cars/models"); supplemental graphics 45881428604 PASS (5 cases, 5 software captures) and Race Engineer 45881418297 PASS (13 jobs). Source diagnosis: fixture disabled automatic host processing before starting race; build_start_grid creates grid markings, while actual car nodes are lazily created by main._process -> Track3D.set_race_cars. The correction is fixture-only: invoke the real paused presentation frame at delta zero before collecting model IDs; assert unchanged tick/hash, exact mapping of all 24 driver IDs to live model nodes, and identity after 2D/3D round trip. No assertion removed, no production change, no retry to conceal a failure. Require fresh exact-head FAST and graphics evidence before merge. Native GPU/human visual review remain NOT_RUN.


## Increment 6 closure
PR #159 merged at b6a09c9ae68690da6ad3f8b22b1e65d687221f98; exact corrected candidate bed0659d90c03f711b4f6545d43e1667b2e5402a. FAST 45882028944 PASS 66/66, 24 models/tick 0; graphics 45882029558 PASS 5 cases/5 captures, Race Engineer 45882028907 PASS. Initial failure retained above. No submitted independent review; native/human review NOT_RUN.

## Increment 7 — Race Behaviour Polish, diagnostic prerequisite
Source evidence: race_engine.gd increments combat_passes by confirmed (possibly >1) and emits a single pass event. Existing audit intentionally counts signals; treating that as actual pass quantity is invalid. blocked_ticks aggregate does not distinguish sustained from intermittent blockage. Add a separate observer-only report of pass counter deltas between consecutive observations and per-driver blocked runs (segments, not incidents; no inferred time loss). Gap/missing driver/pit/finish/disqualification terminate a run; counter rollback flagged, no invented passes. Preserve old counters, revision 040, replay archive, sporting hashes and hot seek. Export on demand through existing F8 JSON, not another panel. Acceptance: injected multi-pass signal, gap/reset/pit/finish cases, synthetic dry/wet hash and hot replay parity, bounded existing real-track Lab scenario evidence and exact FAST. No actual sporting bug identified yet; no speculative change to driver decisions, no full GP or blanket behaviour completion claim. Next evaluate measured evidence, then performance engine; remaining objectives retained.


## Increment 7 closure
PR #160 merged at 4c315c8ce70c641f55702c6b2edaa6d980c83502; exact candidate 68cc6cb7a5e52fc7e438eea36fef0c06f17df89f. FAST 45883905530 PASS, 232/232 quality and 27/27 F8, six additional sporting workflows PASS; simulation command 45883909083 PASS (inventory/import/90-tick Monza dry and Silverstone rain fixture). Detailed numeric scenario metrics not printed in bridge job log; no claim of calibrated behaviour or full GP improvement. No submitted independent review or native/full test.

## Increment 8 — Race Performance Engine 2.0
Source inspection in existing race.pace_thermal_drs_kers region: RacePerformance.evaluate calls WeatherSetup15.evaluate using the frozen car setup/current_weather; DriverError0921.context calls the identical pure calculation again on non-straight phases after 24 seconds. Evaluate once per active car/tick and pass the read-only result to both consumers through optional arguments; independent callers retain original calculation path. No persistent cache, sporting field, revision change, altered formula or numerical approximation. Existing Perf optional counter race.setup_evaluation_reused counts avoided duplicate calls in loaded phases. Acceptance: exact-byte comparison of direct/shared pace/wear, context/hazard and advance outputs over dry/mixed/wet weather, valid/invalid settings and four phases; input immutability, existing driver error/manual pit/replay regressions, FAST and hosted simulation on exact SHA. No isolated timing evidence yet for this subfunction; no A/B benchmark, FULL or native speed claim. Next Spatial Context Cache only after validation. Rollback revert; no migration.


## Increment 8 closure
PR #161 merged at 6cbf2a250cff207b18a760c893cdd7fd3dd2a1eb; candidate 93dd094efd3dd64b8f940e94e7aad5d4d81cdfb4, FAST 45885487059 PASS including exact-byte 15 pace/60 phase comparisons and Driver Error/Weather Setup/replay; six additional sporting workflows PASS; simulation command 45885489574 PASS. No independent submitted review, no isolated timing or native acceleration claim.

## Increment 9 — Spatial Context Cache
Source evidence: lane_limit is repeatedly called for current and lookahead geometry in RaceSpace.plan (two samples always, five with merge rules). Each call repeatedly fetches static track width and converts the same sector dictionary fields; wrap is repeated per sector. Keep existing per-car sample cache and prepare static geometry once per invocation: Float64 sector triples in original order, borrowed read-only profile arrays, one wrapped fraction per sample. Original public lane_limit remains unchanged oracle. No broad pair cache/REV2 cherry-pick, no changed arithmetic, live progress, spatial decisions, RNG, persistent cache or revision. Acceptance: exact-byte differential geometry samples on all 20 catalog tracks, synthetic overlapping sectors, shape without widths, negative/wrapped progress, sector and profile boundaries, all five offsets; immutable input and fresh context after track change, existing safety/physical/tactical and replay tests, exact FAST and targeted hosted simulation. No isolated timing or throughput proof. Next Advanced Architecture evidence-based, no speculative C++/thread migration. Rollback revert, no migration.


## Increment 9 closure
PR #162 merged at df376c718472d7323da560fcf4935ecaf62900b3; candidate 64c477fbd4fc4edb845f6d9a9986a29e5913ca29, FAST 45887386446 PASS including 90,670 exact-byte geometry comparisons across 20 catalog and one synthetic track; SIM_SPACE_PASS, replay and six extra sporting workflows PASS. Simulation command 45887389075 PASS. No independent submitted review, native or timing proof.

## Increment 10 — Advanced Architecture
Source evidence: RaceEngine._step_tick contains 18 separate overlapping revision membership lists and two helper gates repeat their corresponding compatibility conditions. Extract a pure exact-ID capability policy with one ordered whitelist and bit mask, retaining the noncumulative 024/025 start20 exception. Keep original public revision constants as aliases, original engine flag/dependency evaluation order, legacy-launch handling and no-session behaviour. Unknown/old revision IDs fail closed; no prefix inference, no persisted mask, no change to sporting state/hash/replay format. Acceptance: differential test against literal lists copied from the pre-refactor engine for all 18 historical IDs and 10 invalid/older IDs, test strategy/error helper flags and metadata hash, existing replay/manual V21 and sporting suites, FAST and hosted replay on exact SHA. No C++/parallel migration or speed claim. Next Endurance Laboratory using existing bounded contracts, no FULL without owner authorization.


## Increment 10 closure
PR #163 merged at 5e71ad8620d23f869cd189355c0c8f9466d42ab0; candidate b257d23a745d3761581d490edb1abfed0022429c. FAST 45889067854 PASS, 606 policy checks, six sporting workflows PASS, hosted replay 45889072674 PASS 5/5 exact checkout. No independent submitted approval or FULL.

## Increment 11 — Endurance Laboratory 1.0
Existing manual-only apex-endurance-ci.yml, tools/apex_endurance_ci.py and full GP/replay fixtures remain the FULL infrastructure; no dispatch or label authorized. Add bounded 320-tick synthetic LAB fixture to existing FAST manifest; exercise actual 140-event recent ring with 160 queued annotations, preserve complete telemetry, one periodic checkpoint, four-entry hot seek cache and 12 MiB compressed budget, exact seek and fork hash, archival save/load, valid primary surviving incomplete temporary write, rejection of invalid checksum. Record eight static memory/count samples and per-tick p50/p95/p99/mean and headless simulated seconds per wall second as advisory observations only. Existing save migration routed alongside. No runtime/schema changes; no artificial clipping of full telemetry. Permanent nine-anchor eviction, prolonged memory stability, actual process interruption, full race distance, GPU and native 32x remain NOT_RUN. Rollback revert PR; no migrations. FAST marker ENDURANCE_LAB_0923_PASS required.


## Increment 11 closure and 9.23 consolidation
PR #164 merged at 841cf72b3aa6efb882b3c086706b60c4d5634f45; exact candidate c8bcd35ac2cd20b6fdadf917cbda60cfff2a3edd, FAST 45891658057 PASS 1322/1322, 320 ticks, 160 annotations, 140 recent/183 total events, 2 permanent/4 hot anchors and 107658 compressed hot bytes, replay and save migration PASS. Headless tick-wall throughput 37.83x advisory only; no native acceptance. Automatic main FAST 45892271212 PASS. All 11 PRs #154–164 merged, exact candidate FAST runs confirmed, final Git tree identical. Owner audit comment 7202893589. No independent submitted approval.

Owner subsequently authorized closure of all six remaining items, including FULL. This consolidation changes only project identification and documentation, retaining custom user directory APEX_0650_SOUL_STAFF and revision 040; no release binary, no 9.24. Require FAST on consolidation candidate before merge. Existing manual workflow dispatch is not exposed by the connector; do not alter triggers or bypass authorization. Run endurance (6000 ticks, then larger only if needed), paired A/B baseline f57f383e967da14745c4d70f3121618d3058fdf3 vs exact consolidated candidate/merge, and full Core 2 via official manual workflows. Native GPU performance and human visual/audio review require owner idle/availability confirmation and evidence on trusted main; independent review requires a separate reviewer. Record actual statuses, never infer PASS from authorization or a synthetic measurement. Historic #143 remains draft.
