# APEX Lab Hub — Autonomous Orchestration Foundation (1.0 candidate)

Existing entrypoint: Performance Hub issue #141 and apex-lab-command.yml.
Private Engineering Lab remains unchanged; private analyzer stays in its
existing repository. No parallel service or runner. Foundation PR #177 is
not a dependency for the default job and is not merged by this change.

Audit: game main 8ca21459d107cef978ed427d643cfb1863e4e6ac; private Lab main e3494473d7fc642a0209980802367f4f72dc4a1e.
AGENTS.md, Engineering Lab operational contract, Knowledge Index, private
README/bridge and existing hosted workflows reviewed. Official FAST remains
required at exact SHA, no automatic FULL, no local runner or publication.

## Usage (trusted, reviewed checkout, Python 3.10+)

    python3 tools/apex_lab_orchestrator.py capabilities
    python3 tools/apex_lab_orchestrator.py plan /path/to/task.json
    python3 tools/apex_lab_orchestrator.py run /path/to/task.json --head <exact-sha> --output /tmp/new-evidence-directory

Example manifest: docs/apex_lab_task.example.json. Reports preserve task
metadata, ordered jobs, status, attempts, exit/diagnosis, SHA and evidence
hashes. Higher priority first among ready jobs, stable ID tie-break. Missing
dependencies, cycles, arbitrary commands and permission escalation rejected.
One attempt; sequential, 16 tasks, 300 seconds subprocess budget; each
capability has its own shorter timeout. Block dependent jobs on non-PASS;
independent jobs can continue. No claims of CPU/RSS enforcement or recovery
after process loss. Do not run candidate code with secrets or on personal
machines without separate approval. CLI profiles are operator-selected
capability restrictions, not OS identity or sandbox boundaries.

After merge, existing owner-only comment interface accepts:
    /lab orchestrate <exact-main-or-open-same-repo-PR-SHA>
It runs the built-in inventory -> architecture DAG, on hosted runner, through
the existing authorized workflow. No arbitrary manifest in issue comments.
Discovery and planning do not constitute test PASS. Foundation catalog
adapter points to the reviewed validator and its three JSON inputs; missing
files are BLOCKED, not silently substituted. Catalog PASS validates structure
only. Asset production, native Godot/Blender, API/MCP, remote job dispatch,
automatic repair, persistence across sessions, CPU/RSS quotas and actual
role identity integration remain future work. No direct ChatGPT API access is
created. Do not infer successful owner-comment dispatch before live proof.

Acceptance: Python contract tests, existing command contracts, hosted
inventory/architecture smoke, exact-SHA official FAST as applicable.
Rollback: revert this isolated commit; no game data or schema migration.
