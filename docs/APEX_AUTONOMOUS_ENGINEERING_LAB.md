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

For a PR the requested SHA must match its current head at authorization. For #141 it must match main at event time. No forks, non-owner requests, arbitrary parameters or shell commands. The job only uses hosted ubuntu-latest, read-only token, no personal runner and no credentials persisted in checkout. The authorize job reads PR metadata using the standard read token, and the separate execute job runs candidate code without passing the API token. An isolated receipt job has only issue/PR comment write permissions, does not check out or execute candidate code, and posts the accepted command's exact SHA and run link. Receipt failure does not prevent the read-only test job. Commands are supplemental; official FAST remains required. No new permission/secret configuration needed in the intended setup; event delivery and real command execution must be verified after merge. A workflow that times out can lack complete evidence; never infer PASS from absent results.

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

Use the Actions run log and artifact report.json. Status PASS/FAIL/BLOCKED for the requested command only; unexecuted stages are not evidence. Reports do not change historical benchmark verdicts. User should not need to download evidence when accessible in logs; artifact ZIP access may require manual extraction if the connector cannot read the bytes. The current connector can post comments and query jobs by known run ID, but does not list arbitrary issue-comment runs or dispatch all workflows. The receipt job is intended to close the run-discovery gap by returning the run URL to the originating issue/PR. Verify real delivery before claiming autonomous command operation. A later narrowly scoped GitHub App could improve run discovery/dispatch, with separate owner authorization.

## Versioned acceptance

1.0: parser/authorization tests, fork/stale SHA rejection, fixture existence, strict failure markers, hosted contract workflow, actual owner comment smoke after merge. Keep standard CI; no FULL or heavy local benchmark.
1.1: diagnose at least one controlled failure and one success; analyzer pinned and provenance checked; avoid automatic changes and policy inflation. Improve performance report only if actionable.
1.2: new scenario fixtures and knowledge record per feature. Preserve same-seed behavior for unchanged sporting rules; when rules change, document intentional hash changes and replay compatibility.
1.3: isolated test export, actual executable/PCK verification, checksums and explicit publication authorization. Do not distribute private information or unlicensed assets.

All stages use separate PRs with exact revisions and explicit PASS/FAIL/NOT_RUN/INCONCLUSIVE/BLOCKED. Future feature development can proceed in parallel after routine FAST; do not make this roadmap a new mandatory release gate.

## Increment 1.1a — failure diagnosis (candidate)

The 1.0 live audit ran successfully at 01428c088a8848bdfc4c8de96c0660e939d1cd53: run 45856870928, authorize/receipt/execute PASS; exact receipt returned to Hub #141. Only audit was exercised end-to-end.

1.1a adds deterministic classification of observed per-case failure evidence to every command execution: parse, resource, script-runtime, assertion, engine error, timeout, missing executable, missing success marker, nonzero exit and partial log. Existing success gates remain unchanged. A bounded prefix/tail scan returns at most eight project-relative locations, no arbitrary raw log excerpts, and explicit NOT_ESTABLISHED root cause. The full raw log remains in the existing artifact. No automatic correction or retries. Controlled subprocess failure and success are tested in contracts. These are not actual Godot fault injections.

Next increments within 1.1: integrate reviewed static analyzer without exposing private repository contents or assuming a license; graph/cycle diagnostics and routing coverage; longitudinal hosted performance evidence with explicit noncomparability limits. Do not restart ABC. The complete 1.2 and 1.3 roadmap above remains unchanged.

## Increment 1.1b — Architecture Guardian (candidate)

1.1a integrated at 4ca31ee03c68349fe64077417b09bd6594451e5a (PR #146, contracts 22 tests, FAST 5 tests, Lab performance smoke 16 checks; no independent review). 1.1b adds a separate original, read-only analyzer to the public game repository. It inventories tracked GDScript files, literal preload/extends edges, strongly connected components, reference counts, approximate large top-level function spans, and existence of registered FAST fixtures. It produces a structured JSON artifact and bounded summary in command logs. Both audit and diagnose run it; CI exercises the real project's static scan. Findings alone do not fail the scan, imply a bug, prove performance regression or trigger refactoring. Scan incompleteness is not PASS. Dynamic references, class_name, UIDs and scene dependencies are outside its narrow graph. No game code, existing FAST gate or private analyzer source changed.

Remaining 1.1 scope: securely use the reviewed private analyzer without copying its source into the public repository, correlate observed CI failures with relevant change evidence, and add performance history with explicit comparability limits. Keep 1.2 and 1.3 intact; no local benchmark or new universal game merge gate.

## Increment 1.1c — failure/change correlation (candidate)

1.1b integrated at f6bd81b793b1a29d73d165bfc91d74630dc4f3b3 (PR #147, contracts 28 PASS, FAST 5 PASS, Test Lab 16 checks PASS; real static scan 161 scripts, 284 literal edges, 0 cyclic components, 48 large-function candidates, 63 registered fixtures present). No independent review. These are narrow lexical observations, not proof of absence of bugs.

1.1c extends /lab diagnose with immutable base/head diff, existing router domains, direct matches to reported locations or failing fixture, and bounded current-head literal dependency/consumer paths (three hops). It emits correlation.json and structured command logs; lists unexecuted planned fixtures and suggested validation of the observed failure. Correlation PASS means the diagnostic was generated, never that a failed test passed. No matches, absent/partial graph, or incomplete logs are limitations, not evidence of innocence. Unit tests include a real temporary Git diff, synthetic graph evidence, and a mocked failed command preserving its FAIL result. No Godot fault injection, no automatic patches, no local runner, no new mandatory game merge gate. The existing official FAST remains unchanged; correlation is on-demand, not yet hooked to all CI failures.

Remaining 1.1: advanced analyzer integration without disclosing private source, performance history, and agent-guided fix PRs based on evidence. Preserve 1.2 Simulation & Knowledge and 1.3 Release Automation as above. Gameplay development need not wait for these tooling increments.

## Increment 1.1d — private Advanced Analyzer

Game PR #148 merged at 65b6a3ea026ccd78c23ab3ff8986d89544e979f4: 34 contract tests, 5 FAST tests, 16 Test Lab checks PASS. Private Development Lab PR #22 merged at e3494473d7fc642a0209980802367f4f72dc4a1e. After a real multiline GDScript lexer fix, all four workflows passed and pinned analyzer 0.2.1 scanned 161/161 scripts with zero scan errors (254 structural metric occurrences, 220 heuristics; not bug counts). The original blocked run is preserved. Use the owner-only private command hub issue #21 in the Development Lab; the public bridge remains unchanged. Live authorization and receipt confirmed, real scan outcome to be checked independently. No private source copied into the game repository.

## Increment 1.1e — Performance Guardian (candidate)

Reuse the already required headless LAB probe (24 cars, two weather cases, two repetitions, 500 ticks each, fixed seed 991420). No additional simulation or benchmark. After the official report passes, optionally retain a compact validated observation with exact candidate and actual checkout SHAs, probe blob, engine version, runner metadata, run ID/attempt, sporting hashes and four measured rows. Main push runs may retrieve up to six earlier successful main push observation artifacts from the latest ten successful runs; PRs record only current evidence. No extraction of historical ZIP paths. The history summary contains per-weather medians and explicit uncontrolled-host limitations. Old artifacts without observation records are not reconstructed or invented. Retention requested 30 days, historical API retrieval can be PARTIAL, and a first run can be CURRENT_ONLY. The optional collection/upload is nonblocking; the original validated report and mandatory sporting tests remain unchanged. Unit contracts test invalid/partial data, ZIP handling, and historical provenance; actual historical retrieval needs at least two qualifying main runs. Never infer GPU performance, RSS, causation, or a cross-machine regression gate from these records. ABC remains unchanged. The remaining planned 1.2 Simulation & Knowledge and 1.3 Release Automation are preserved.

## Increment 1.2a — Simulation & Knowledge Intelligence (candidate)

Private Advanced Analyzer live command 45864200406 completed authorize/receipt/scan PASS: 161/161 scripts, zero errors, pinned analyzer 0.2.1. Performance Guardian PR #149 integrated at 947ee5d4066e08401aa897734aff00f3d640f62b: five history contracts, five FAST fixtures, 16 Test Lab checks, current observation generation and upload PASS. Historical multi-run retrieval remains unverified; retain optional collection without extra benchmarking.

1.2a adds /lab simulation with a bounded actual-engine sporting scenario (90 replay ticks each, Monza dry and Silverstone heavy rain, 24 cars, seed 991321). Assertions cover manual booking without premature pit request, pace command acceptance, finite state, complete unique classification, replay hashes and seek. It is selected by FAST only when its own fixture changes, or on demand via the bridge; no universal matrix. A technical knowledge index in docs/APEX_LAB_KNOWLEDGE_INDEX.md maps existing systems and tests and records decisions with evidence and limitations. Full races, actual pit completion, tyre evolution, overtaking and native GPU remain outside this short scenario. Candidate requires normal FAST and bridge contracts. Next 1.2b: targeted software-rendered UI validation, retaining native GPU consent boundary. Then 1.3 verified export and release preparation. All previous roadmap commitments preserved; gameplay can proceed without waiting for tooling.

## Increment 1.2b — Graphics Lab (candidate)

Simulation & Knowledge PR #150 integrated at 5d66d16368c1d25674b4bfb9d3a194a22f79802a. Exact-head 39 bridge contracts, six FAST fixtures, 305 real-track sporting checks and 16 existing Test Lab checks PASS (run 45865092772). No full race or native graphics claim. The simulation command still needs a live command smoke when useful.

1.2b adds /lab graphics for the existing pitwall_0649_ui_test.gd and race_engineer_0922_ui_test.gd actual framebuffer fixtures under Xvfb GL compatibility and car_model_smoke_test.gd headless mesh contract. It clears only the five known capture outputs in the disposable checkout before running, requires fresh PNG signature/header, requested dimensions, end marker and bounded size, then stores screenshots, SHA-256 and graphics.json in the command artifact. This is capture metadata plus existing fixture assertions, not image decoding or aesthetic approval; visual_review stays NOT_RUN. Dedicated hosted PR smoke runs only for changes to the graphics collector, its contracts or graphics workflow. No new general graphical gate, no local runner, no game code changes, no claim of real GPU performance. Native GPU review remains separate and requires owner authorization. Follow-up 1.3 is verified Linux test export and release preparation, not automatic publication. Existing FAST unchanged. Historical performance multi-run retrieval not yet verified; connector currently lists PR-triggered runs only. Preserve all roadmap items and resume gameplay without expanding universal release gates.

## Increment 1.3 — Automatic Release Builder (candidate)

Graphics PR #151 merged at 430fba389d54a6058bf00f0a0ef98ee72d0e235d. Exact-head 42 bridge contracts, five FAST fixtures, 16 Test Lab checks and three actual graphics fixtures PASS (run 45865990419); five fresh framebuffer PNGs with correct dimensions and checksums. Visual review remains NOT_RUN, software renderer only. No independent review.

1.3 implements owner-only /lab build <exact SHA>, reusing the existing APEX Linux x86_64 export preset and pinned setup-godot official 4.7.2 templates. The isolated hosted command checks inventory, editor version and import, then exports a real release-mode executable and separate PCK to temporary storage. It checks ELF64 little-endian x86_64 header, executable permission, PCK magic, sizes, SHA-256, exported runtime version, headless startup using the actual exported pack outside the source checkout with disposable user data, and tar.gz member sizes/hashes/permissions. Generates release-test.json, SHA256SUMS, BUILD_NOTES.md and logs. It does not infer FULL, native GPU, an official release or rights to redistribute third-party assets. A dedicated PR smoke is limited to builder tooling changes, not a general merge gate. Test binary and archive remain runner-temp only and are removed; only evidence is uploaded to the public repo. Retaining a downloadable package requires a separately authorized distribution/asset-rights decision or private delivery design. No tag, release, arbitrary shell, personal runner, or automatic publication. This deliberately separates verified export preparation from distribution. Actual export and startup must pass before integration. Live build command still requires post-merge verification when needed. Prior historical performance multi-run retrieval remains unverified; no benchmark reruns just to prove that optional feature.

## Operational handoff after 1.3 validation

The Lab expansion is bounded by this roadmap. Resume normal gameplay feature PRs after the builder validation, with FAST and only relevant supplemental checks. Use docs/APEX_LAB_KNOWLEDGE_INDEX.md, AGENTS.md and current game source as starting points; do not require all Lab tools on every change. Keep explicit NOT_RUN/BLOCKED/INCONCLUSIVE states. No automatic patch/merge or publication. Future Lab changes must be motivated by actual blockers, not an indefinite tooling roadmap.

### 1.3 startup correction — first export evidence

Run 45866939549 at dcd45c76254fd79e9c446b0a90518917911d4898: official Godot templates installed, actual Linux export and ELF/PCK verification passed (73,519,416-byte executable; 1,203,532-byte pack). Startup BLOCKED: artifact 15140208445 startup.log explicitly rejects --main-pack in official release template compiled without path overrides. The existing preset already creates an adjacent same-stem PCK. Remove unsupported --main-pack, require adjacent matching pack name, launch outside checkout with disposable user directories as before. Add regression contract prohibiting --main-pack and --path and rejecting wrong/remote pack names. Do not weaken startup or archive checks; first failed run remains blocked. New exact-head CI pending. No game code changed or binaries published.

## Final evidence closure (targeted follow-up, not a new feature roadmap)

PR #152 integrated at cfa105b9a42ee1db4106a356f5465ea78f62f455; exact candidate 395c36ed8a51d24cb6800fb47a07af95c377dc66, three workflows PASS. Actual Linux export, adjacent PCK startup and archive hash/permission verification PASS (run 45867818872). Executable 73,519,416 bytes, PCK 1,203,532 bytes, tar.gz 29,349,570 bytes. Evidence only; no binary publication. Live owner build command not separately exercised.

At owner's request, add a targeted artifact-only performance history verification using the existing collector. At least two distinct successful main-push commit observations and no retrieval errors are required to report PASS; otherwise INCONCLUSIVE. No additional simulation or historical ABC reruns. The dedicated workflow is hosted, restricted to same-repository owner requests, reads Actions artifacts, and is not a universal merge gate. New verification pending. All ordinary FAST behavior preserved.

Native graphical review is now recorded in docs/APEX_NATIVE_GRAPHICS_REVIEW.md, linking the actual REV1 native baseline and owner confirmation in Hub #141. This is a review procedure and durable historical record, not new GPU evidence. Current version native execution and visual review remain NOT_RUN; explicit permission and machine availability are still required before native execution. No new personal runner, benchmark, or automatic native dispatch. Only relevant visual changes need this optional targeted review. No change to game runtime.
