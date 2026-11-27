# APEX — Pre-Merge Integrity Guard

## Motivation

The existing FAST checks actual Godot import, deterministic Test Lab and targeted fixtures. However, a green result is not a permanent approval of every future combination of PR head and main. The router also previously silently omitted a missing category fixture and read only the candidate registry, even though the manifest loader supports additive baseline requirements.

Repository inspection: #176 was open draft, mergeable with CI in progress; #173 was open draft and not mergeable. These observations are not a diagnosis of every earlier merge failure. All 24 built-in FAST fixture paths existed at the inspected baseline. No gameplay PR was changed.

## Workflow changes

Reuse .github/workflows/godot-setup.yml. On PRs, preflight binds the actual checked-out synthetic merge's two parents to the event base/head and records the tree, PR/run/attempt. Routing uses the actual checked-out tree. Read the baseline manifest from the exact base commit, union it with the current registry, and fail if any selected fixture is absent. There is no additional simulation, matrix, native runner or FULL requirement. Draft-to-ready triggers the ordinary FAST again to obtain fresh evidence.

After the existing required tests and LAB report pass, compare planned/executed fixtures, require their logs and success markers without engine errors, and query the live PR with read-only permissions. Block on a moved base/head, closed PR, conflict or changed synthetic merge identity. Artifact ci-results/premerge-receipt.json records exact identity and log SHA-256; a failure emits premerge-blocked.json. The receipt does not merge, certify other workflows, claim human review, or provide tamper-proof attestation against malicious candidate code. The job still uses the project's existing trusted contribution model.

## Merge operation

Follow AGENTS.md section 5.3. Recheck current main, head, base, draft, mergeability, review requirements, latest applicable FAST and targeted checks immediately before merge. Use expected_head_sha, never force or bypass. After merge, compare resulting tree and check main FAST. A failing post-merge result requires targeted diagnosis, not a blind rollback or new feature merge.

The read-only integration could not inspect branch protection settings in detail (HTTP 403). No ruleset or branch protection was changed. To enforce this policy at GitHub itself, an authorized administrator should require the existing **Import and Core 2 regression tests** check on main, require branches to be up to date before merging, retain any existing necessary checks, and avoid bypass where appropriate. Verify the actual check source and existing rules before editing; do not replace unrelated protections. Until configured/verified, the repository instructions and CI enforce the evidence during normal workflow execution, but do not guarantee an administrator cannot merge manually or that main cannot advance between API read and merge. There is no automatic merge. Native graphics, FULL, publication and performance comparison remain separate.

## Validation scope

Offline contracts cover missing selected fixtures, removed baseline requirements, wrong merge parents, moved head/base, conflict, missing/inconsistent evidence and engine errors. Real candidate FAST must validate actual GitHub API provenance and receipt before the guard is integrated. Do not claim success until observed.
