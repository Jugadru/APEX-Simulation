# APEX Autonomous Engineering Lab — roadmap and operational contract

Date: 2026-11-26. Independent of game version numbering. Existing REV1 and FAST remain the production development baseline. No reconstruction of private Lab, no automatic local benchmark, no repeat of historical ABC. One engineering capability per PR; do not delay gameplay features for unrelated tooling.

## Architecture and complete scope

ChatGPT coordinates engineering through GitHub. The command bridge is the orchestration entrypoint; the existing FAST router and Test Lab remain the authoritative routine checks. The independent Development Lab stays the advanced diagnostic and research center. Local runner and native GPU work require owner consent and idle confirmation; no unreviewed PR execution on personal machine. No shared personal tokens, arbitrary shell commands from comments, automatic publication, hidden ongoing agent, or automatic merge.

| Capability | Priority | Status / planned deliverable |
|---|---|---|
| Lab Command Bridge / Orchestrator | Very high | 1.0: owner-only exact-SHA hosted requests, allowlisted domains, structured results and artifact logs |
| Intelligent Test Router | Very high | Existing FAST diff router; 1.0 reuses it; 1.1 coverage audit and missing-fixture checks |
| Code Analyzer / Automatic Bug Hunter | Very high | 1.0 existing inventory; 1.1 integrate private static analyzer's reviewed version, resource references, duplicate classes/functions and risk findings |
| Self-Healing CI / Bug Hunter | High | 1.0 structured fail-first evidence; 1.1 classify failures, extract bounded relevant logs and propose reproducible fix PRs; human/agent review, no blind retries or auto patching |
| Performance Guardian / Performance Lab | High | Existing hosted smoke and private historical ABC; 1.0 hosted smoke only; 1.1 longitudinal diagnostics and prospective paired comparisons only on material changes |
| Regression Lab | High | Existing FAST and domain checks; 1.1 diagnosis evidence; no global FULL requirement |
| Architecture Guardian / Architecture Lab | High | 1.1 dependency graph, cycles, large functions and duplicate code heuristics; findings not automatic deletions |
| Simulation Validation Lab | High | 1.0 existing racecraft/strategy/replay fixtures; 1.2 expand fixtures for tyres, climate, overtaking, pit, driver behavior, AI, saves and replay, deterministic seeds |
| Graphics Lab | High | Existing native REV1 evidence; 1.2 targeted visual fixtures and optional real GPU validation; no claim of real GPU from hosted software display |
| Technical Knowledge Base / Knowledge Lab | High | 1.2 durable decisions, changelogs, system ownership, prior bugs and regression references with revision links |
| Automatic Release Builder | Medium | 1.3 versioned Linux test exports, checksums, executable and PCK verification, changelog and artifact; explicit publication approval |
| Optional dedicated agent/GitHub App | Future | Separate least-privilege integration if needed for workflow dispatch or continuing agent work; not installed or enabled here |

## 1.0 command interface

After this workflow has merged to main, repository owner Jugadru can post a new standalone comment on an open same-repository PR targeting main or Performance Hub issue #141:

    /lab replay <exact-40-character-commit-sha>

For a PR the requested SHA must match its current head at authorization. For #141 it must match main at event time. No forks, non-owner requests, arbitrary parameters or shell commands. The job only uses hosted ubuntu-latest, read-only token, no personal runner and no credentials persisted in checkout. The authorize job reads PR metadata using the standard read token, and the separate execute job runs candidate code without passing the API token. Commands are supplemental; official FAST remains required. No new permission/secret configuration needed in the intended setup; event delivery and real command execution must be verified after merge. A workflow that times out can lack complete evidence; never infer PASS from absent results.

| Command | 1.0 behavior |
|---|---|
| fast | Existing FAST diff selector, inventory, Godot import and bounded fixture run; supplemental, not official CI |
| audit | Existing source inventory and hard contract checks; heuristic diagnostic findings |
| diagnose | Same targeted execution as fast, structured failing fixture and raw log; deeper failure classifier deferred |
| racecraft | Existing targeted sporting fixtures |
| strategy | Existing pit, weather, radio, staff and orders fixtures |
| replay | Replay, hash and save migration fixtures |
| performance | Hosted track and CPU/memory smoke with existing report; no A/B, no GPU, no local runner |
| report | Plan preview only; no tests executed, historical consolidation deferred |
| build | Reserved for 1.3; deliberately rejected in 1.0 |

Use the Actions run log and artifact report.json. Status PASS/FAIL/BLOCKED for the requested command only; unexecuted stages are not evidence. Reports do not change historical benchmark verdicts. User should not need to download evidence when accessible in logs; artifact ZIP access may require manual extraction if the connector cannot read the bytes. The current connector can post comments and query jobs by known run ID, but does not list arbitrary issue-comment runs or dispatch all workflows. Verify real delivery before claiming autonomous command operation. A later narrowly scoped GitHub App could improve run discovery/dispatch, with separate owner authorization.

## Versioned acceptance

1.0: parser/authorization tests, fork/stale SHA rejection, fixture existence, strict failure markers, hosted contract workflow, actual owner comment smoke after merge. Keep standard CI; no FULL or heavy local benchmark.
1.1: diagnose at least one controlled failure and one success; analyzer pinned and provenance checked; avoid automatic changes and policy inflation. Improve performance report only if actionable.
1.2: new scenario fixtures and knowledge record per feature. Preserve same-seed behavior for unchanged sporting rules; when rules change, document intentional hash changes and replay compatibility.
1.3: isolated test export, actual executable/PCK verification, checksums and explicit publication authorization. Do not distribute private information or unlicensed assets.

All stages use separate PRs with exact revisions and explicit PASS/FAIL/NOT_RUN/INCONCLUSIVE/BLOCKED. Future feature development can proceed in parallel after routine FAST; do not make this roadmap a new mandatory release gate.
