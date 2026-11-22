#!/usr/bin/env python3
"""APEX Quality Gate 2.0 — truthful, commit-specific CI evidence.

A successful run from a different branch, commit, or unrelated pull request is
NEVER sufficient. Audit mode reports missing checks without pretending they
passed; enforce mode fails closed. No branch protection is silently modified.
Only GitHub Actions read permissions are needed.
"""
from __future__ import annotations

import argparse
from http import client
from dataclasses import dataclass
import json
import os
from pathlib import Path
import re
import sys
import time
from typing import Any
from apex_quality_manifest import load_suites, full_checks, full_checks_for_paths
from urllib import parse

SHA_RE = re.compile(r"^[0-9a-fA-F]{40}$")
REPO_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")


@dataclass(frozen=True)
class Requirement:
    number: int
    key: str
    workflow: str
    job: str
    area: str
    # Comparisons depend on their PR baseline/candidate. A manual dispatch
    # may use unrelated defaults even when the run's head_sha is correct.
    comparison: bool = False


REQUIREMENTS = (
    Requirement(1, "gdunit4", "gdunit4-ci.yml", "Testes de logica 2012", "Motor"),
    Requirement(2, "benchmark_ab", "apex-benchmark-ab.yml", "A-B CPU / mesmo seed e hash", "Desempenho", True),
    Requirement(3, "screenshots", "apex-capturas-ci.yml", "Silverstone 2012 - HUD 2D e corrida 3D", "Apresentação"),
    Requirement(4, "gdscript_toolkit", "apex-gdscript-toolkit.yml", "gdlint + gdformat (informativo)", "Estilo"),
    Requirement(5, "bandit", "apex-seguranca-python.yml", "Bandit / auditoria gratuita informativa", "Segurança"),
    Requirement(6, "desktop_export", "apex-export-desktop.yml", "Exportar desktop Godot 4.7.2", "Distribuição"),
    Requirement(7, "visual_ab", "apex-regressao-visual-ab.yml", "Comparar HUD 2D e corrida 3D / Silverstone 2012", "Regressão visual", True),
    Requirement(8, "endurance", "apex-endurance-ci.yml", "Determinismo, GPs, memoria e 20 temporadas de dados", "Resistência"),
    Requirement(9, "race_intelligence", "apex-race-intelligence-ci.yml", "Pit Wall, chuva, manual e IA / 2012", "IA e estratégia"),
    Requirement(10, "saveguard", "apex-saveguard-ci.yml", "Saves / Replay / corrupcao — baseline vs candidata", "Persistência", True),
)


class GateError(RuntimeError):
    pass


def validate_identity(repo: str, sha: str) -> None:
    if not REPO_RE.fullmatch(repo):
        raise GateError("Repository must be owner/repo")
    if not SHA_RE.fullmatch(sha):
        raise GateError("Commit must be an exact 40-character SHA (no branches or tags)")


class GitHubAPI:
    def __init__(self, repo: str, token: str):
        if not token:
            raise GateError("GITHUB_TOKEN not set; cannot verify current checks")
        if not REPO_RE.fullmatch(repo):
            raise GateError("Invalid owner/repo")
        self.repo = repo
        self.token = token

    def get(self, suffix: str) -> Any:
        # Pin the remote hostname at TLS connection time. Never follow HTTP
        # redirects or accept a caller-provided host, scheme, or arbitrary path.
        if not re.fullmatch(
            r"(?:/pulls/[1-9][0-9]*|/actions/runs(?:\?head_sha=[0-9a-fA-F]{40}&per_page=100&page=[1-4]|/[0-9]+/jobs\?per_page=100))",
            suffix,
        ):
            raise GateError("Blocked unexpected GitHub API endpoint")
        path = "/repos/" + self.repo + suffix
        headers = {
            "Authorization": "Bearer " + self.token,
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "APEX-Quality-Gate/2.0",
        }
        conn = client.HTTPSConnection("api.github.com", timeout=20)
        try:
            conn.request("GET", path, headers=headers)
            response = conn.getresponse()
            if response.status != 200:
                raise GateError(f"GitHub API rejected evidence request: HTTP {response.status}")
            data = response.read(16 * 1024 * 1024 + 1)
            if len(data) > 16 * 1024 * 1024:
                raise GateError("GitHub Actions evidence exceeded size budget")
            return json.loads(data)
        except (client.HTTPException, OSError, ValueError) as exc:
            raise GateError("GitHub Actions evidence unavailable: " + str(exc)) from exc
        finally:
            conn.close()

    def merged_pr_identity(self, pr_number: int, sha: str, base_sha: str) -> dict | None:
        """Recover exact PR provenance after GitHub removes run.pull_requests."""
        if pr_number < 1 or not SHA_RE.fullmatch(sha) or not SHA_RE.fullmatch(base_sha):
            raise GateError("Invalid PR identity request")
        pr = self.get(f"/pulls/{pr_number}")
        if not isinstance(pr, dict):
            raise GateError("Invalid GitHub pull request response")
        head, base = pr.get("head"), pr.get("base")
        if not isinstance(head, dict) or not isinstance(base, dict):
            raise GateError("Missing trusted PR head/base")
        head_repo = head.get("repo")
        if (pr.get("number") != pr_number or head.get("sha") != sha
                or base.get("sha") != base_sha or not isinstance(head_repo, dict)
                or head_repo.get("full_name") != self.repo):
            return None
        if (not isinstance(pr.get("created_at"), str)
                or not isinstance(pr.get("merged_at"), str)
                or not isinstance(head.get("ref"), str)):
            return None
        return {"head_ref": head["ref"], "repo": self.repo,
                "created_at": pr["created_at"], "merged_at": pr["merged_at"]}

    def runs(self, sha: str) -> list[dict]:
        if not SHA_RE.fullmatch(sha):
            raise GateError("Invalid SHA for GitHub Actions query")
        result: list[dict] = []
        for page in range(1, 5):
            query = parse.urlencode({"head_sha": sha, "per_page": 100, "page": page})
            body = self.get("/actions/runs?" + query)
            rows = body.get("workflow_runs") if isinstance(body, dict) else None
            if not isinstance(rows, list):
                raise GateError("Unexpected workflow runs API response")
            result.extend(rows)
            if len(rows) < 100:
                return result
        raise GateError("Too many runs for this commit; refusing an incomplete audit")

    def jobs(self, run_id: int) -> list[dict]:
        data = self.get(f"/actions/runs/{run_id}/jobs?per_page=100")
        rows = data.get("jobs") if isinstance(data, dict) else None
        if not isinstance(rows, list):
            raise GateError("Unexpected jobs API response")
        if int(data.get("total_count", len(rows))) > len(rows):
            raise GateError("More than 100 jobs in a workflow; refusing partial evidence")
        return rows


def validate_pr_context(pr_number: int, base_sha: str) -> None:
    if pr_number < 0 or (bool(pr_number) != bool(base_sha)):
        raise GateError("PR number and base SHA must be given together")
    if base_sha and not SHA_RE.fullmatch(base_sha):
        raise GateError("PR base must be an exact 40-character SHA")


def belongs_to_pr(run: dict, pr_number: int, base_sha: str, sha: str,
                  pr_identity: dict | None = None) -> bool:
    if pr_number <= 0 or not base_sha or run.get("event") != "pull_request":
        return False
    linked = run.get("pull_requests", [])
    if not isinstance(linked, list):
        return False
    if any(
        isinstance(pr, dict)
        and pr.get("number") == pr_number
        and isinstance(pr.get("base"), dict)
        and pr["base"].get("sha") == base_sha
        and isinstance(pr.get("head"), dict)
        and pr["head"].get("sha") == sha
        for pr in linked
    ):
        return True
    # GitHub deletes run.pull_requests after merge. Never borrow another PR:
    # require independently verified identity, repository, SHA and run window.
    if linked or not isinstance(pr_identity, dict):
        return False
    created = run.get("created_at")
    return bool(
        run.get("head_sha") == sha
        and run.get("head_branch") == pr_identity.get("head_ref")
        and isinstance(run.get("head_repository"), dict)
        and run["head_repository"].get("full_name") == pr_identity.get("repo")
        and isinstance(created, str)
        and pr_identity.get("created_at") <= created <= pr_identity.get("merged_at")
    )

def select_run(
    runs: list[dict], requirement: Requirement, sha: str,
    pr_number: int = 0, base_sha: str = "",
    pr_identity: dict | None = None
) -> dict | None:
    validate_pr_context(pr_number, base_sha)
    candidates = []
    for run in runs:
        if not isinstance(run, dict) or run.get("head_sha") != sha:
            continue
        filename = str(run.get("path", "")).split("@", 1)[0].rsplit("/", 1)[-1]
        if filename != requirement.workflow:
            continue
        if requirement.comparison and not belongs_to_pr(run, pr_number, base_sha, sha, pr_identity):
            continue
        # Never borrow results from another PR when auditing a PR.
        if run.get("event") == "pull_request" and pr_number:
            if not belongs_to_pr(run, pr_number, base_sha, sha, pr_identity):
                continue
        candidates.append(run)
    return max(
        candidates,
        # Older run may be retried after a newer run was created.
        key=lambda r: (
            str(r.get("run_started_at") or r.get("created_at") or ""),
            int(r.get("run_attempt", 0)),
            int(r.get("id", 0)),
        ),
        default=None,
    )


def assess_requirement(req: Requirement, installed: set[str],
                       runs: list[dict], sha: str, jobs_loader,
                       pr_number: int = 0, base_sha: str = "",
                       pr_identity: dict | None = None) -> dict:
    info = {
        "number": req.number, "key": req.key, "workflow": req.workflow,
        "area": req.area, "job": req.job, "status": "MISSING_WORKFLOW",
        "url": None, "note": "",
    }
    if req.workflow not in installed:
        info["note"] = "Workflow not installed in the checked-out candidate revision"
        return info
    run = select_run(runs, req, sha, pr_number, base_sha, pr_identity)
    if run is None:
        info["status"] = "NO_RUN"
        info["note"] = (
            "No valid pull_request comparison for this exact SHA"
            if req.comparison else "No run found for this exact SHA"
        )
        return info
    info["url"] = run.get("html_url")
    if run.get("status") != "completed":
        info["status"] = "PENDING"
        info["note"] = "Selected workflow run is not finished"
        return info
    if run.get("conclusion") != "success":
        info["status"] = "FAILED"
        info["note"] = "Latest run conclusion: " + str(run.get("conclusion"))
        return info
    entries = jobs_loader(int(run["id"]))
    matches = [job for job in entries if job.get("name") == req.job]
    if len(matches) != 1 or matches[0].get("status") != "completed" or matches[0].get("conclusion") != "success":
        info["status"] = "JOB_NOT_SUCCESSFUL"
        info["note"] = "Required job did not run successfully; skipped jobs do not count"
        return info
    info["status"] = "PASSED"
    info["note"] = "Successful job, exact candidate SHA"
    if req.key in ("gdscript_toolkit", "bandit"):
        info["note"] += "; existing audit is informational, not zero warnings"
    return info


def assess(installed: set[str], runs: list[dict], sha: str, jobs_loader,
           checks: tuple[Requirement, ...] = REQUIREMENTS,
           pr_number: int = 0, base_sha: str = "",
           pr_identity: dict | None = None) -> dict:
    validate_pr_context(pr_number, base_sha)
    details = [
        assess_requirement(req, installed, runs, sha, jobs_loader,
                           pr_number, base_sha, pr_identity)
        for req in checks
    ]
    passed = sum(item["status"] == "PASSED" for item in details)
    return {
        "status": "READY" if passed == len(details) else "BLOCKED",
        "candidate_sha": sha,
        "pr_number": pr_number if pr_number > 0 else None,
        "pr_base_sha": base_sha or None,
        "passed": passed,
        "total": len(details),
        "checks": details,
        "codeql": "OPTIONAL_NOT_COUNTED: private GitHub Code Security license not assumed",
        "limitations": [
            "Evidence must originate from the exact candidate commit.",
            "Benchmark, visual comparison and SaveGuard require matching PR number, candidate SHA and PR base SHA.",
            "A successful historical branch run cannot approve an unmerged main branch.",
            "GDScript Toolkit and Bandit are informational by their current policies, even when their jobs pass.",
            "This script does not enable branch protection or auto-merge; GitHub admins must configure required checks separately.",
        ],
    }


def markdown_report(data: dict, mode: str) -> str:
    result = [
        "### APEX Quality Gate 2.0 — relatório por commit",
        "",
        f"**Readiness: {data['status']}** | **Modo: {mode.upper()}** | {data['passed']}/{data['total']} checks.",
        "",
        f"Commit: `{data['candidate_sha']}`",
        "",
        "| # | Área | Verificação | Situação |",
        "|---:|---|---|---|",
    ]
    for item in data["checks"]:
        result.append(
            f"| {item['number']} | {item['area']} | `{item['workflow']}` | {item['status']} |"
        )
    result.extend([
        "", f"CodeQL: {data['codeql']}", "",
        "**AUDIT** gera diagnóstico e não autoriza merge. **ENFORCE** retorna falha quando BLOCKED.",
        "Um status PASSED significa que o job do workflow passou, não ausência total de bugs.",
        "",
        "#### Pendências",
    ])
    for item in data["checks"]:
        if item["status"] != "PASSED":
            result.append(f"- **{item['key']}** ({item['status']}): {item['note']}")
    if data["status"] == "READY":
        result.append("- Nenhuma pendência detectada nas verificações obrigatórias desta política.")
    result.extend(["", "#### Limites"] + ["- " + v for v in data["limitations"]] + [""])
    return "\n".join(result)


def run_gate(root: Path, repository: str, sha: str, mode: str,
             output: Path, api: GitHubAPI,
             pr_number: int = 0, base_sha: str = "",
             trusted_project: Path | None = None,
             changed_paths: list[str] | None = None) -> tuple[int, dict]:
    validate_identity(repository, sha)
    validate_pr_context(pr_number, base_sha)
    workflow_dir = root / ".github" / "workflows"
    installed = {path.name for path in workflow_dir.glob("*.yml")} | {
        path.name for path in workflow_dir.glob("*.yaml")
    }
    suites = load_suites(root, trusted_project)
    extra = (full_checks_for_paths(suites, changed_paths)
             if changed_paths is not None else full_checks(suites))
    if any(item["key"] in {req.key for req in REQUIREMENTS} for item in extra):
        raise GateError("Manifest duplicates a protected built-in check key")
    checks = REQUIREMENTS + tuple(
        Requirement(len(REQUIREMENTS) + idx + 1,
                    item["key"], item["workflow"], item["job"], item["area"],
                    item["comparison"])
        for idx, item in enumerate(extra)
    )
    # A four-shard workflow should be fetched once, not once per shard.
    cache: dict[int, list[dict]] = {}
    def cached_jobs(run_id: int) -> list[dict]:
        if run_id not in cache:
            cache[run_id] = api.jobs(run_id)
        return cache[run_id]
    pr_identity = (api.merged_pr_identity(pr_number, sha, base_sha)
                   if pr_number and hasattr(api, "merged_pr_identity") else None)
    report = assess(installed, api.runs(sha), sha, cached_jobs,
                    checks=checks, pr_number=pr_number, base_sha=base_sha,
                    pr_identity=pr_identity)
    report["mode"] = mode
    report["repository"] = repository
    output.mkdir(parents=True, exist_ok=True)
    (output / "report.json").write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    (output / "report.md").write_text(markdown_report(report, mode), encoding="utf-8")
    # Audit succeeds as a *diagnostic command*, never reports readiness PASS.
    code = 1 if mode == "enforce" and report["status"] != "READY" else 0
    return code, report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", default=os.environ.get("GITHUB_REPOSITORY", ""))
    parser.add_argument("--sha", default=os.environ.get("GITHUB_SHA", ""))
    parser.add_argument("--mode", choices=("audit", "enforce"), default="audit")
    parser.add_argument("--pr-number", type=int, default=0)
    parser.add_argument("--base-sha", default="")
    parser.add_argument(
        "--wait-seconds", type=int, default=0,
        help="Bounded retry for still-pending workflows (never treats missing as success)",
    )
    parser.add_argument("--project", type=Path, default=Path("."))
    parser.add_argument("--trusted-project", type=Path, default=None,
                        help="Trusted base checkout; candidate cannot remove its required checks")
    parser.add_argument("--changed-files", type=Path, default=None,
                        help="Trusted exact base/head PR diff JSON to scope dynamic FULL checks")
    parser.add_argument("--output", type=Path, default=Path("ci_artifacts/quality_gate"))
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    try:
        validate_identity(args.repository, args.sha)
        validate_pr_context(args.pr_number, args.base_sha)
        api = GitHubAPI(args.repository, os.environ.get("GITHUB_TOKEN", ""))
        if not 0 <= args.wait_seconds <= 180:
            raise GateError("wait-seconds must be between 0 and 180")
        changed = None
        if args.changed_files is not None:
            if not args.pr_number:
                raise GateError("Scoped dynamic checks require verified PR context")
            changed = json.loads(args.changed_files.read_text(encoding="utf-8"))
            if (not isinstance(changed, list) or not changed
                    or any(not isinstance(p, str) or not p or p.startswith("/")
                           or ".." in Path(p).parts for p in changed)):
                raise GateError("Missing or unsafe exact PR changed-files list")
        deadline = time.monotonic() + args.wait_seconds
        while True:
            code, report = run_gate(
                args.project.resolve(), args.repository, args.sha, args.mode,
                output, api, args.pr_number, args.base_sha,
                args.trusted_project.resolve() if args.trusted_project else None,
                changed_paths=changed
            )
            # Never wait when dependent workflows are not installed; report
            # the correct MISSING_WORKFLOW state immediately.
            statuses = {item["status"] for item in report["checks"]}
            if (
                report["status"] == "READY"
                or "MISSING_WORKFLOW" in statuses
                or not statuses.intersection({"NO_RUN", "PENDING"})
                or time.monotonic() >= deadline
            ):
                break
            time.sleep(min(15.0, max(0.0, deadline - time.monotonic())))
        print(
            "APEX_QUALITY_GATE_" + report["status"],
            json.dumps({"mode": args.mode, "sha": args.sha, "passed": report["passed"],
                        "total": report["total"]}),
            flush=True
        )
        return code
    except (OSError, GateError, ValueError, KeyError, TypeError) as exc:
        (output / "error.txt").write_text(str(exc) + "\n", encoding="utf-8")
        print("APEX_QUALITY_GATE_ERROR " + str(exc), file=sys.stderr, flush=True)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
