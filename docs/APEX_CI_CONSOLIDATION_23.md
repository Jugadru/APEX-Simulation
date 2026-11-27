# CI Consolidation 2.3 — production grouped matrix

Base 917e483fd615650ae27b3a10a33d069273713e92: PR #189 merged; FAST post-merge run 45999348416 passed. The exact #189 candidate passed 104 checks, 7 optional skips, including 12/12 grouped pilot jobs (run 45997015023). Same-job execution observations: independent 1626.25 s, grouped 1043.06 s, 35.86% lower accumulated native process duration, not billing or controlled benchmark. Historical anchor took 253.65 s (old 240s budget too short in this observed execution).

## Migration

- Central existing tactical coordination workflow uses 12 ordinary PR jobs with five grouped comparisons per job, 1800 ticks, ITA/GBR/MON x Seco/Chuva intensa x 42/123. 72 primary drives instead of 120, 60 comparisons remain.
- All five fixed invariant fixtures execute once at ITA/Seco/42, in independent HOME/XDG processes, original markers and error checks preserved. Import is still a clean native import, once per job. No cross-SHA cache, no change to game or replay.
- The central workflow retains the original 12 coordination check names. Four former independent workflow names and all their matrix job names remain available via manual dispatch; central workflow also retains manual legacy-coordination and grouped-pilot (or explicit label event). Ordinary PRs do not run those duplicate jobs. The 48 old automatic checks are replaced by the 12 grouped checks, not declared passed/skipped as if executed.
- The central path filter is the union of all five old filters plus direct resource dependencies and import/runner/project files. Self-test verifies the union is still present. Any matching path conservatively runs all five comparisons. FAST and separate aero wake, FULL, graphical/native and other workflows unchanged.
- Production summary must prove five modes, successful native reports and assertion traces, exact scenario, 6 primary calls, 4 hits, shared sporting output equality, and five anchor fixture markers. No acceptance criterion relaxed. Fixture failure still blocks job even if grouped comparisons pass.
- Independent comparison of all five isolated baselines against grouped remains available explicitly. Do not run it on every ordinary PR.

## Integration gate and limitations

Exact candidate FAST and 12/12 production grouped jobs required, including anchor 5/5 fixtures and 60 sporting comparison records, and all other triggered required targeted regressions. Compare accumulated step times and critical path against equivalent prior runs, not simply number of jobs. The prior pilot and unchanged sporting assertion code are evidence, not a replacement for current candidate validation.

Administrative branch rules could not be fully inspected via connector (403). Classic branch metadata reports protected=true and legacy protection enabled=false, empty contexts; that does not establish ruleset requirements. **Do not merge** until the maintainer or authorized API verifies that the 48 old automatic contexts are not required, or updates required checks to the central matrix under explicit authorization. No bypass and no protection changes made. This PR is a candidate migration, not active on main until integration. Local native preflight unavailable; hosted tests pending.

Original filters: 21 unique paths. Central: 35 paths, no original filter removed.
