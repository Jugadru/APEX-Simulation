#!/usr/bin/env python3
"""Fail-closed APEX v0.6.6.9.9 release audit using exact GitHub PR evidence.

This is a QA-only check. It does not modify sport, simulate races or
classify high pit waits as defects. It waits for independent CI runs on
the exact HEAD, then verifies all required jobs and preserves a report.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import time

from apex_quality_gate import (
    GitHubAPI, GateError, REQUIREMENTS, Requirement, assess,
    validate_identity, validate_pr_context,
)

EXTRA_REQUIREMENTS = tuple([
    Requirement(11 + i, "matrix_" + str(i), "apex-scenario-matrix-ci.yml",
                f"Matrix 2012 / grupo {i} de 4", "20 circuitos / 180 casos")
    for i in range(4)
] + [
    Requirement(15, "pitwall_forensics", "apex-pitwall-intelligence-ci.yml",
                "Analisar escolhas do Pit Wall / 2012, sem modificar IA", "Pit / 5.8772 s"),
    Requirement(16, "pit_coordination", "apex-pit-coordination-ci.yml",
                "FIFO garage / safety hold / V21 / replay 017", "Garagem"),
    Requirement(17, "wet_strategy", "apex-wet-strategy-ci.yml",
                "Godot 4.7.2 / imperfect forecast / V21 / replay 019-020", "Chuva"),
    Requirement(18, "core2", "godot-setup.yml",
                "Import and Core 2 regression tests", "Motor Core 2"),
])
ALL_REQUIREMENTS = REQUIREMENTS + EXTRA_REQUIREMENTS
FULL_MATRIX_POLICY = "github.head_ref == 'qa/v0.6.6.9.9-race-quality' && 'full'"


def audit(root: Path, sha: str, number: int, base: str, api: GitHubAPI,
          jobs_cache: dict[int, list[dict]] | None = None) -> dict:
    validate_pr_context(number, base)
    validate_identity(api.repo, sha)
    matrix_workflow = (root / ".github/workflows/apex-scenario-matrix-ci.yml")
    if not matrix_workflow.is_file():
        raise GateError("Matrix workflow missing from candidate")
    if FULL_MATRIX_POLICY not in matrix_workflow.read_text(encoding="utf-8"):
        raise GateError("Full 180-scenario matrix is not enabled for release PR")
    workflow_dir = root / ".github/workflows"
    installed = {p.name for p in workflow_dir.glob("*.yml")}
    installed.update(p.name for p in workflow_dir.glob("*.yaml"))
    cache = jobs_cache if jobs_cache is not None else {}

    def cached_jobs(run_id: int) -> list[dict]:
        if run_id not in cache:
            cache[run_id] = api.jobs(run_id)
        return cache[run_id]

    result = assess(installed, api.runs(sha), sha, cached_jobs,
                    ALL_REQUIREMENTS, pr_number=number, base_sha=base)
    result["release"] = "v0.6.6.9.9"
    result["matrix_profile"] = "full (180 cases x 2 repetitions; 4 shards)"
    result["queue_58772_policy"] = "REVIEW until a causal defect is proven"
    result["limitations"] += [
        "No GPU/FPS proof on the user's local PC from headless CI.",
        "A matrix job proves its configured 10-lap cases, not 20 full-length GPs.",
        "The 5.8772s case is not marked an avoidable queue by this gate.",
    ]
    return result


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--repository", required=True)
    p.add_argument("--sha", required=True)
    p.add_argument("--pr-number", type=int, required=True)
    p.add_argument("--base-sha", required=True)
    p.add_argument("--project", type=Path, default=Path("."))
    p.add_argument("--output", type=Path, default=Path("ci_artifacts/race_quality_gate"))
    p.add_argument("--wait-seconds", type=int, default=0)
    args = p.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    try:
        if not 0 <= args.wait_seconds <= 3600:
            raise GateError("wait-seconds must be 0..3600")
        validate_identity(args.repository, args.sha)
        api = GitHubAPI(args.repository, os.environ.get("GITHUB_TOKEN", ""))
        deadline = time.monotonic() + args.wait_seconds
        cache: dict[int, list[dict]] = {}
        while True:
            result = audit(args.project.resolve(), args.sha, args.pr_number,
                           args.base_sha, api, cache)
            (args.output / "report.json").write_text(
                json.dumps(result, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
            pending = [c for c in result["checks"] if c["status"] != "PASSED"]
            lines = [
                "# APEX v0.6.6.9.9 — Release Gate por SHA", "",
                f"**{result['status']} ({result['passed']}/{result['total']})**",
                f"Commit: \`{args.sha}\`", "",
                "| Área | Verificação | Status |", "|---|---|---|",
            ]
            lines += [
                f"| {c['area']} | {c['key']} | {c['status']} |"
                for c in result["checks"]
            ]
            lines += ["", "**Fila de 5,8772 s:** REVIEW, sem ajuste artificial.",
                      "**Matriz:** full (180 casos x 2 repetições), sem equivaler a 20 GPs completos.",
                      "**Limitação:** FPS do PC do jogador não medido."]
            (args.output / "report.md").write_text(
                "\n".join(lines) + "\n", encoding="utf-8"
            )
            if not pending:
                print("APEX_RACE_QUALITY_GATE_READY",
                      json.dumps({"sha": args.sha, "passed": result["passed"],
                                  "total": result["total"]}), flush=True)
                return 0
            if any(c["status"] in ("MISSING_WORKFLOW", "FAILED",
                                   "JOB_NOT_SUCCESSFUL") for c in pending):
                break
            if time.monotonic() >= deadline:
                break
            time.sleep(min(60.0, max(0.0, deadline - time.monotonic())))
        print("APEX_RACE_QUALITY_GATE_BLOCKED", json.dumps({
            "sha": args.sha, "passed": result["passed"], "total": result["total"],
            "pending": [{ "key": c["key"], "status": c["status"] } for c in pending],
        }), flush=True)
        return 1
    except (GateError, OSError, ValueError, TypeError, KeyError) as exc:
        (args.output / "error.txt").write_text(str(exc) + "\n", encoding="utf-8")
        print("APEX_RACE_QUALITY_GATE_ERROR " + str(exc), flush=True)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
