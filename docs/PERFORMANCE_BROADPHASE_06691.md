# APEX 0.6.6.9.1 — Racecraft Visual Sweep Broadphase

**Scope:** One optimization for the presentation-only continuous collision detection used in 3D vehicle occupancy. No sporting physics, race tick, pit, weather, tyre, AI, or persistence change. This follows the v0.6.6.9.0 measured performance baseline and respects AGENTS.md.

## Why

The historical performance profiler (`docs/BASELINE_PERFORMANCE_0657.md`) measured `visual.occupancy` and `visual.world_3d` as significant CPU sections. The recent v0.6.6.9.0 CI measured limited 3D FPS under Xvfb/llvmpipe software rendering. Neither finding establishes that the new change improves **physical GPU FPS**. This PR targets a narrower CPU cost: unnecessary full continuous separating-axis collision tests for distant cars.

## Change and proof obligation

`scripts/apex_racecraft_0654.gd::swept()` now makes a *conservative* early rejection for relative linear motion. If relative X or Y stays strictly outside ±7 scene units at **both** endpoints, the original continuous SAT test cannot represent contact for unit directions, since each car's bounding radius is `sqrt(2.80²+1.40²)`, or about 3.13; combined radius is about 6.26. The 7-unit margin provides room for numerical approximation. Paths that cross an axis threshold still enter the **unchanged** original SAT. This optimization only changes CPU control flow in visual collision projection, not the official car positions.

The 3D road sampler in `scripts/track_3d.gd::_sample_occupied_pose()` uses normalized orientation from the road normal. The broadphase relies on that input contract.

## QA

- `tests/racecraft_broadphase_06691_test.gd` compares the new predicate with the **unmodified v0.6.6.9.0 swept algorithm** for 16,005 fixed adversarial and seeded cases. Any differing boolean fails CI.
- The existing `tests/racecraft_0654_test.gd` checks attacker/defender, no visual overlap, no tunneling, traffic, narrow road, pause and source immutability.
- The existing `tests/visual_stutter_06672_benchmark.gd` checks GBR, MON, BEL and SIN for 125 race updates per circuit, stationary visual frames, visual collisions and smoothing.
- The existing `apex-benchmark-ab.yml` compares old/main and candidate visual projections in three alternating repetitions, requires exact **non-timing** visual report equality, and measures CPU per presentation update. A larger than 20% median slowdown blocks the PR, but noise-sensitive small changes are reported without claiming a win.
- All repository mandatory CI tests, including determinism, full Monza replay, saves, Pit Wall, and Quality Gate, must be completed on **the exact candidate SHA**. Actual native PC GPU FPS remains `NOT_RUN` until separately measured.

**Acceptance:** Boolean and visual outputs equal to baseline, no regression in required CI checks, and a reproducible CPU improvement versus the same scenario on main. If performance does not improve measurably, do not promote this version as an optimization.

## Rollback

The change is completely reversible by reverting the visual `swept()` prefilter and the accompanying tests/docs/workflow step. No save migration and no serialization format changes are involved. Do not merge or tag this PR until its measurements and regression tests are reviewed.
