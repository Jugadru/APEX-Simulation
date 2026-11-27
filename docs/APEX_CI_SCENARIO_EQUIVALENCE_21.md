# CI Consolidation 2.1 — audit of scenario equivalence

Base audited: `5374d96f45731c0a50a03006e95a7296c10673ec` (PR #186 merged, FAST main run 45925671915 completed successfully). Scope: audit only; no removal of tests, changes to gameplay, or changes to workflow triggers. Counts below describe source-level candidates, not measured CI savings.

## 1. A/B graph

Source: `tests/aero_wake_091711_test.gd` and six workflow files. The run() method selects two revision numbers based on the environment; drive() constructs a fresh Race with seed, team, track, weather and revision-controlled flags, then advances in 0.2-second ticks. Comparing only script names, seeds or climate is insufficient.

| Workflow | A/B revisions | Tracks | Climate | Seeds | Ticks | Cases |
|---|---|---|---|---|---|---:|
| apex-aero-wake.yml | 031 → 035 | ITA/GBR/MON | Seco/Chuva intensa | 42/7/19/123/2026 | 1800 | 30 |
| apex-tactical-coordination.yml | 035 → 036 | same | same | 42/123 | 1800 | 12 |
| apex-corner-battle.yml | 036 → 037 | same | same | 42/123 | 1800 | 12 |
| apex-driver-traffic-0920.yml | 037 → 038 | same | same | 42/123 | 1800 | 12 |
| apex-traffic-mega-09201.yml | 038 → 039 | same | same | 42/123 | 1800 | 12 |
| apex-driver-error-0921.yml | 039 → 040 | same | same | 42/123 | 1800 | 12 |

Five modes: 60 comparisons, 120 primary drive() calls. Six revision identities (035–040) per each of 12 combinations = 72 candidate unique calls; 48 possible repetitions (40%). Including the Aero matrix: 90 comparisons, 180 primary calls, 120 candidate unique calls (60 possible repetitions, 33.3%). This excludes additional historical drives, deliberate deterministic reruns, replay checks, inner fixtures, full GPs and camera tests. Those are not counted as savings. All 60/90 comparisons must remain independently evaluated with their original assertions.

## 2. Runtime evidence — ITA / Seco / 42 / 1800

Read raw AERO_WAKE_AB log events for PR #186 head f8e96bfeeb2f3aff38c9543bae294f234f09a744. All reported old/new ticks = 1800. All five jobs were successful.

| Mode | Job ID | Old hash | New hash |
|---|---:|---|---|
| Coordination | 140261032412 | 067ec801e8bef03f137cfcadd229f2662cc400f8ccdbbe17f8ed45ffa1fc9e85 | e3eeb1189ffb049d65706b8c189dcc3e3b67111e42efed3383c7ec665de0ff53 |
| Corner | 140261032756 | e3eeb1189ffb049d65706b8c189dcc3e3b67111e42efed3383c7ec665de0ff53 | 9190524493e933da0ce1268ebaaeea89d601f1ba6c1136dd1247643d684b440d |
| Traffic | 140261032559 | 9190524493e933da0ce1268ebaaeea89d601f1ba6c1136dd1247643d684b440d | 9190524493e933da0ce1268ebaaeea89d601f1ba6c1136dd1247643d684b440d |
| Mega | 140261032566 | 9190524493e933da0ce1268ebaaeea89d601f1ba6c1136dd1247643d684b440d | 9e3824534720489a637f11f8638e9ba04827bd71e38d63330abb5007f1dbea23 |
| Error | 140261032427 | 9e3824534720489a637f11f8638e9ba04827bd71e38d63330abb5007f1dbea23 | e072e7863215e4c90b8c79db50a5b6c28458f16008ff38d25e88c37600755334 |

Equal hashes are supporting evidence, not proof of equivalent tests. Revisions 037 and 038 are distinct despite equal hashes for this single case. Only five sample job logs inspected; full-matrix equivalence remains NOT_RUN. No timing or performance equivalence claim.

## 3. Other overlaps to preserve

- FAST registry includes aero, coordination, corner, driver traffic, mega and error fixtures. The FAST default aero run uses 600 ticks (not 1800); do not replace it with a matrix run. Dedicated fixture overlap between FAST and matrices is conditional on paths, not universal.
- The shared script calls fixture() before every A/B pair and runs deliberate determinism/archive checks on ITA/Seco/42. Audit these separately; do not remove deliberate repeats or silently change the checks count. Fixture-only currently returns before the normal PASS marker; it cannot be treated as a successful full A/B run.
- Aero full GP runs use 60000 tick cap and additional classification assertions, opt-in label or historical PR 126; camera is a native Xvfb job. Neither is equivalent to a headless 1800-tick scenario.
- Historical workflows apex-independent-racecraft.yml, apex-racing-line.yml, apex-racing-completion.yml, apex-race-traffic-hotfix.yml contain job guards tied to old branch names. Some script overlap exists (traffic_arc, full_gp, P15), but guards/renderer/pipeline/timeout differ. Do not claim skipped historical jobs are covered or remove them. Consider manual activation with equivalent cases and validated triggers in a separate PR.
- Existing router: tools/apex_ci_tiers.py + .github/apex-quality-suites.json, already unions baseline manifest and candidate; preserve unknown-module conservative fallback and mandatory FAST. No parallel router or new permanent Lab.

## 4. Proposed implementation boundary (next incremental PR)

First prove reusable results with one 12-case pilot matrix, keeping existing production gates. Use the existing A/B test and CI infrastructure. A scenario identity must include exact merge tree, engine version, revision and all effective feature flags, track/data and state, seed, weather, duration/tick step, team, renderer, invocation and isolation. Do not cache across commits or jobs without a verified identity and content/integrity proof. Prefer isolated runs per unique revision within a grouped job; audit transitive environment reads and global state before reuse. Separate reproducibility reruns and performance samples from memoized sporting state. Do not reuse timing/memory metrics as independent measurements.

For each pair, evaluate every original assertion against the appropriate old/new result, report mode, input identity, both hashes, assertion names and failures; missing result or missing comparison must fail closed. Compare old and new harnesses on same tree and engine, all 12 combinations and all 60 comparisons; verify complete deterministic sporting outputs (not only hashes), assertion coverage, historical replay and intentionally injected failure detection. Keep original workflow/check identities or establish explicit migration before changing mandatory checks. Do not switch triggers until the replacement is proven. Preserve all historical scripts, logs and rollback.

Stage 2.2: route by verified dependency closure with existing registry, safe conservative fallback for unknown paths and explicit opt-in expanded tests. Stage 2.3: group compatible jobs and reuse import/setup only with isolation proof. Stage 2.4: controlled baseline/candidate CI timing with separate runner-seconds and wall time, same workload and engine, all failures/cancellations retained. FULL manual per AGENTS.md. Stop infrastructure work when the quality/cost objective is achieved; return to simulation.

Status: static audit PASS for inspected paths; sampled shared-revision hash comparison PASS; full equivalence, grouped runner, timing gains, native local import/preflight NOT_RUN. No gameplay or workflow changes in this audit.
