# CI Consolidation 2.2 — opt-in grouped scenario pilot

Base: 9dfc18de49083260b1a9524513b415e1551fdabf (audit #188, candidate FAST PASS, integrated tree verified). The main post-merge FAST must also be checked before any promotion.

## Complete retrospective comparison

PR #186 head f8e96bfeeb2f3aff38c9543bae294f234f09a744: all 60 AERO_WAKE_AB records retrieved, track/climate/seed/ticks checked. For each of the 12 configurations, compare new result from each mode with old result of adjacent mode. Sort object keys recursively, preserve array order, compare all top-level sporting fields (including nested values). Exclude only elapsed_us, engine_us, peak_static_bytes_sampled, engine_us_per_tick. 48/48 adjacent result pairs equal; no differing sporting fields. This is equivalence of existing reports, not proof of a new executor.

| Track | Climate | Seed | Coord job | Corner job | Traffic job | Mega job | Error job |
|---|---|---:|---:|---:|---:|---:|---:|
| ITA | Seco | 42 | 140261032412 | 140261032756 | 140261032559 | 140261032566 | 140261032427 |
| ITA | Seco | 123 | 140261032508 | 140261032793 | 140261032610 | 140261032348 | 140261032403 |
| ITA | Chuva intensa | 42 | 140261032461 | 140261032898 | 140261032642 | 140261032662 | 140261032510 |
| ITA | Chuva intensa | 123 | 140261032474 | 140261032699 | 140261032579 | 140261032603 | 140261032373 |
| GBR | Seco | 42 | 140261032392 | 140261032459 | 140261032819 | 140261032576 | 140261032394 |
| GBR | Seco | 123 | 140261032404 | 140261032852 | 140261032304 | 140261032692 | 140261032547 |
| GBR | Chuva intensa | 42 | 140261032371 | 140261032727 | 140261032537 | 140261032687 | 140261032561 |
| GBR | Chuva intensa | 123 | 140261032165 | 140261032685 | 140261032729 | 140261032658 | 140261032584 |
| MON | Seco | 42 | 140261032473 | 140261032590 | 140261032587 | 140261032569 | 140261032344 |
| MON | Seco | 123 | 140261032518 | 140261032730 | 140261032618 | 140261032810 | 140261032686 |
| MON | Chuva intensa | 42 | 140261032396 | 140261032999 | 140261032713 | 140261032879 | 140261032155 |
| MON | Chuva intensa | 123 | 140261032453 | 140261032885 | 140261032523 | 140261032900 | 140261032440 |

## Candidate architecture

- Existing normal execution remains non-cached; old/new calls use the same drive() implementation. Grouped mode is opt-in and only accepts the explicit 12-case matrix, one scenario per process, no full GP or conflicting mode flags.
- Grouped mode uses the same run_case() assertion body for all five comparisons. Primary drive calls cached only by revision within the single fixed scenario, deep copies on storage/read; no cross-job or cross-commit reuse. Fixtures and all independent determinism/replay reruns are retained. Primary call counts must be 6, hits 4, cache size 6.
- Python pilot invokes five separate isolated baseline Godot processes and one grouped process in the same job. Compares every recorded sporting result, fixture, assertion count, ordered assertion outcome digest and success markers. Fail closed on missing reports, duplicate/reordered modes, mismatch or native failure. Timing/memory excluded from equality and preserved in raw logs. Self-test injects comparator mismatches and missing mode. Not a controlled performance benchmark.
- Existing coordination workflow gains an opt-in job (label ci:grouped-pilot or workflow_dispatch). The original production jobs remain; no check is replaced. Manual dispatch runs only pilot. PR labeling can incur an extra coordination matrix once; no FULL requested. The pilot is intentionally additional work until proven; do not count its runtime as production savings.
- No gameplay files changed. No claim of native PASS before real logs.

## Gate before promotion

Exact merge candidate FAST and ordinary targeted workflows PASS, plus all 12 pilot jobs with all 60 paired comparisons and independent replay checks. Review baseline vs grouped evidence; if a mismatch occurs, do not relax criteria or promote. The pilot does not yet implement dependency router consolidation, grouping setup/import in production, or a change of required check identities. Full native local preflight unavailable in current environment; pending hosted CI. Keep the production matrix unchanged until a later independently reviewed PR.
