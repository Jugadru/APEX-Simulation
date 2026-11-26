# Performance Recovery Consolidated — release candidate

Status: DRAFT / NOT HOMOLOGATED. One delivery; independent commits.
Base: 2ac0989655ada387631816648bf3246411fabb76.
Includes the pending Leader Resolution candidate 2a371d3c55afc341e2a1a0956d13e77c6e454046 without modifying PR #140. Its original INCONCLUSIVE result (including adverse pair) is not overridden.

## Changes
- Lateral occupancy: reuse frozen scalar progress/lane in both ordered sweeps, retain exact inequalities, tie order and all writes.
- Shared Tick Cache: two geometry values per active stable ID, scoped to one invocation of RaceSpace.plan; no reuse across ticks, sessions or track changes. Preserve ahead-car lookahead rather than substituting the follower's.
- Replay: avoid a second deep clone on freshly decompressed checkpoint exports; still clone legacy resident states and policies. All hashes, archive format, checkpoint retention and revision 040 unchanged.
- Scheduler: 10x/16x/32x bounded backlog of 6/8/12 respectively, 12ms frame budget and 16-tick hard cap unchanged. No sporting tick skipped. Actual speed continues to be displayed; effect on interactive speed is not yet measured.
- Optional graphics profile for Linux launch: `APEX_GRAPHICS_PROFILE=gtx1650 ./Godot --path .` (substitute the actual Godot executable). MSAA 2x, two directional shadow splits, 160 distance and no SSAO. Default rendering unchanged. This trades visual quality for potential GPU savings; no measured GTX 1650 FPS claim.
- Tests: existing SIM_SPACE leader/physical fixtures plus expanded replay detachment and bounded acceleration hash parity.

## Gate and rollback
FAST on exact candidate SHA; paired Lab A/B baseline vs consolidated candidate (no selective retests); dry/wet 24-car per-tick parity, replay export/seek and real GPU test for the optional graphics profile. No FULL without explicit authorization. No merge until required evidence is PASS. Use git revert of independent commits or discard the candidate branch; keep main and original PR #140 unchanged.
No native tests/benchmarks were executed during authoring; performance and sporting correctness are NOT_RUN for the consolidated SHA.
