# 0.7.2.4 — Native Batch Optimization Experimental

Base 524bd90a19aeaafe6920b4cdb774c77729d78fbd, PR #195 merged, FAST pós-merge 46065911101 PASS. User authorized experimental scope, not activation. 0723 FAST 46060974438 and native 46060974449 PASS. Scalar speedup Linux 0.872x / Windows 0.906x; batch24 micro 5.194x / 4.596x; no scenario reached 10% macro reduction for scalar. Keep GDScript authoritative.

## Contract
Audit original RaceSpace.plan: final lateral occupancy loop writes only current intent; reads other cars' original progress/lane, not proposed next positions. Vehicle072.propose uses L.motion_envelope and P.advance, creates local limits/tyre/offer; no RNG or mutation of car. Two phases are dependent: coast end speed determines powered force cap. Only in scratch copy, defer 045 physical proposals to a stable ordered list at the existing boundary before MergeTraffic.queue and prevent_convergence; 041/044 retain original path. Prepare all envelopes/offer, packed binary64 coast batch, compute powered limits from coast, packed powered batch, reconstruct original dictionaries in original field order and commit intents in original order. No changes to solver, settle/account, RNG, replay schema, state hash, pit or engine ownership. Preserve original scalar propose for other uses. Template derived from pinned original 696c81e0d16da2ff47e58c08754f4b8c802ddf5d; space patch pinned d1427138fda7c610a31970d38e806f1dc471df6f. Fail closed on missing class, batch shape or anchor. Counters static diagnostic only, require >1 cars/group, two calls/group, zero legacy usage. No silent fallback in performance experiment; missing-library fallback remains 0722 gate.

## Predeclared evaluation
Reuse exact source and fixture transport, 0722 oracles, 0723 micro and scalar A/B, seven scenarios and 5 repetitions, 100 warmup + 500 measured ticks, headless 24 cars, 045 recording ON/OFF and 041/044 controls. Add third scratch arm, alternate A/B/C and C/B/A; same input and per-tick SHA/RNG/events and replay seek. Retain raw samples, RSS process tree, timings, counters, generated source, first difference; compare against identical baseline in each repetition. Prior criteria stay unchanged: 2x micro including bridge, >=10% median macro improvement in representative target, P99 <=1.05x, RSS <=1.10x, zero sporting divergence. Batch phase micro is not proof of macro gain. 65-min hosted job timeout covers added arm; no new workflow, no FULL, no runner personal. Existing 0723 source baseline remains pinned at 2171247 (runtime identical to 524bd90; confirmed diff only experiment/docs/CI). Further matrix, full GP, V21 entry and cross-save/replay required only if promotion is justified; no official integration without separate authorization. Local preflight BLOCKED (container unavailable); CI pending. Rollback: abandon PR or revert experimental commit only.

## Directed pre-macro oracle
Compare 68 complete ordered proposal dictionaries via var_to_bytes with original propose on dry/wet, batch sizes 1/2/7/24, mixed speed, pace, mass, shift, DRS/KERS, zero/partial/normal/long dt and reversed IDs; verify input dictionaries unchanged, empty batch and exact counters. Must pass on both hosted OSs before macro. No tolerance or canonicalization.


## Measured decision — PR #196, original head 0ba1713
Native run 46068901917 PASS on Linux (job 140740818461) and Windows (job 140740818215). FAST 46068901888 PASS with receipt for old base 524bd90, tree 319beae320db5613ccb440334366eaca540039dd. Both native jobs completed APEX_BATCH_0724_PASS, including directed oracle and per-tick sporting/RNG/event equivalence, no divergence in bounded scenarios. Micro batch24 speedup Linux 4.499x / Windows 4.732x; batch240 4.873x / 5.225x. Macro batch median time reduction (positive is faster):

| 045 scenario | Linux | Windows |
|---|---:|---:|
| Monza dry | +0.022% | +0.636% |
| Silverstone heavy rain | +0.790% | -0.846% |
| LAB dry | +0.897% | -0.326% |
| LAB heavy rain | -1.369% | +1.623% |
| Monza replay | +0.626% | +0.972% |

No 045 scenario meets the predeclared >=10% macro target. Reject both tested scalar and batch phase adapters for official activation; retain GDScript and experimental source for future investigation of larger measured bottlenecks. This is an execution PASS, not a performance promotion PASS. No need to run expanded promotion matrix for a rejected candidate. Recommend continuing 0.7.3 Overtaking Preparation after experimental PR is integrated and post-merge FAST passes. No FPS/GPU claim.

## Concurrent base synchronization
Main advanced to 561b19d105b3c1c4d19254ee158538095bf5b30f (Foundation Metadata Adapter; six changed files, no overlap with this PR and no changes to official runtime or pinned benchmark inputs). Its FAST 46071563713 PASS. Synchronize without rewriting history, keep both branches' files and record this historical result. New head requires fresh FAST receipt and native validation before merge. No tests waived. Local preflight remains BLOCKED.
