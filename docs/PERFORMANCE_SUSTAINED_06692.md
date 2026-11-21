# APEX v0.6.6.9.2 — Sustained 32× / sporting-hash field caching

Status: **CANDIDATE / tests pending.** One principal change: cache stable *field names* during sporting replay hashing. No changes in HUD screens, pace, tyres, strategies, pit, weather, RNG, fixed-step scheduler, save formats or race rules. This branch is independent of the Work/Codex HUD effort.

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
