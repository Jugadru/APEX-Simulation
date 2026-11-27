#!/usr/bin/env python3
"""Bind existing FAST results to the actual PR merge tree; never merge."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
from apex_quality_gate import GitHubAPI, GateError
from apex_ci_tiers import ALWAYS

SHA = re.compile(r"[0-9a-f]{40}\Z")
ROW = re.compile(r"[A-Za-z0-9_-]+\.gd\|[A-Za-z0-9_ .:-]{3,120}\Z")
BAD = re.compile(r"(^ERROR:|SCRIPT ERROR:|Parse Error:)", re.I | re.M)
MAX_LOG = 16 * 1024 * 1024

def require(ok, message):
    if not ok:
        raise ValueError(message)

def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args],
                                   text=True, timeout=20).strip()

def identity(event, env, root):
    require(env["GITHUB_EVENT_NAME"] == "pull_request", "Expected PR event")
    pr = event["pull_request"]
    base, head = pr["base"]["sha"], pr["head"]["sha"]
    merged = env["GITHUB_SHA"]
    repo = env["GITHUB_REPOSITORY"]
    require(all(SHA.fullmatch(x) for x in (base, head, merged)), "Invalid revision")
    require(pr["base"]["ref"] == "main" and pr["base"]["repo"]["full_name"] == repo,
            "Wrong target repository or branch")
    require(env["APEX_BASE_SHA"] == base and env["APEX_HEAD_SHA"] == head,
            "FAST routing identity disagrees with PR event")
    number = pr["number"]
    require(type(number) is int and number > 0, "Invalid PR number")
    require(git(root, "rev-parse", "HEAD") == merged, "Checkout is not exact GitHub merge SHA")
    require(git(root, "show", "-s", "--format=%P", "HEAD").split() == [base, head],
            "Tested merge does not have the expected base and candidate parents")
    tree = git(root, "rev-parse", "HEAD^{tree}")
    require(SHA.fullmatch(tree), "Invalid merge tree")
    run_id, attempt = int(env["GITHUB_RUN_ID"]), int(env["GITHUB_RUN_ATTEMPT"])
    require(run_id > 0 and attempt > 0, "Invalid CI execution identity")
    return {"schema": 1, "repo": repo, "pr": number, "base": base, "head": head,
            "head_repo": pr["head"]["repo"]["full_name"], "merge": merged, "tree": tree,
            "run_id": run_id, "attempt": attempt}

def verify_live(expected, live):
    require(live["number"] == expected["pr"] and live["state"] == "open",
            "PR closed or changed")
    require(live["base"]["ref"] == "main"
            and live["base"]["repo"]["full_name"] == expected["repo"]
            and live["base"]["sha"] == expected["base"],
            "main changed during FAST; refresh and revalidate")
    require(live["head"]["repo"]["full_name"] == expected["head_repo"]
            and live["head"]["sha"] == expected["head"],
            "Candidate changed during FAST; revalidate")
    require(live.get("mergeable") is not False, "PR now has conflicts")
    if live.get("merge_commit_sha"):
        require(live["merge_commit_sha"] == expected["merge"],
                "GitHub regenerated the merge candidate; revalidate")

def plan(path):
    rows = path.read_text(encoding="utf-8").splitlines()
    require(0 < len(rows) <= 100 and len(rows) == len(set(rows)), "Missing/duplicate test plan")
    require(all(ROW.fullmatch(row) for row in rows), "Invalid test plan entry")
    require(len({row.split("|")[0] for row in rows}) == len(rows),
            "Ambiguous fixture markers")
    require({s + "|" + m for s, m in ALWAYS}.issubset(rows), "Core invariant missing")
    return rows

def evidence(directory):
    expected, executed = plan(directory / "fast-plan.tsv"), plan(directory / "test-plan.txt")
    require(set(expected) == set(executed), "Executed plan differs from FAST plan")
    checks = []
    for row in executed:
        script, marker = row.split("|")
        log = directory / (script[:-3] + ".log")
        require(log.is_file() and 0 < log.stat().st_size <= MAX_LOG, "Missing or oversized log: " + log.name)
        raw = log.read_bytes()
        text = raw.decode("utf-8", errors="replace")
        require(marker in text and not BAD.search(text), "Missing success marker or engine error: " + script)
        checks.append({"fixture": script, "marker": marker, "log_sha256": hashlib.sha256(raw).hexdigest()})
    report = json.loads((directory / "lab-perf/report.json").read_text(encoding="utf-8"))
    require(report["status"] == "PASS" and report["cases"] == 4 and report["total_ticks"] == 2000,
            "Existing LAB performance contract not PASS")
    return checks

def write(path, record):
    path.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=["preflight", "finish"])
    parser.add_argument("--results", type=Path, default=Path("ci-results"))
    args = parser.parse_args()
    directory = args.results
    directory.mkdir(parents=True, exist_ok=True)
    try:
        event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text(encoding="utf-8"))
        expected = identity(event, os.environ, Path.cwd())
        if args.phase == "preflight":
            write(directory / "premerge-identity.json", expected)
            print("APEX_PREMERGE_IDENTITY " + json.dumps(expected))
            return 0
        before = json.loads((directory / "premerge-identity.json").read_text(encoding="utf-8"))
        require(expected == before, "Checkout or CI identity changed since preflight")
        checks = evidence(directory)
        api = GitHubAPI(expected["repo"], os.environ["GH_TOKEN"])
        live = api.get("/pulls/" + str(expected["pr"]))
        verify_live(expected, live)
        receipt = {**expected, "status": "PASS", "scope": "FAST_ONLY",
                   "draft_at_check": bool(live.get("draft")),
                   "tests": checks,
                   "limitations": ["No merge performed; recheck live PR immediately before merging.",
                                   "Only existing FAST coverage; targeted external checks remain separate."]}
        write(directory / "premerge-receipt.json", receipt)
        print("APEX_PREMERGE_PASS " + json.dumps({**expected, "tests": len(checks)}))
        return 0
    except (ValueError, KeyError, TypeError, OSError, subprocess.SubprocessError, GateError) as exc:
        write(directory / "premerge-blocked.json", {"status": "BLOCKED", "phase": args.phase,
                                                   "reason": str(exc)})
        print("APEX_PREMERGE_BLOCKED " + str(exc))
        return 2

if __name__ == "__main__":
    raise SystemExit(main())
