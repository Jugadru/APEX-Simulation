#!/usr/bin/env python3
"""Developer-side preflight; never a new merge gate or a substitute for FAST."""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import subprocess
import sys
import tempfile

from apex_ci_tiers import ALWAYS, CASES, select
from apex_quality_manifest import FILE, load_suites

ROOT = Path(__file__).resolve().parents[1]
ERROR = re.compile(r"^ERROR:|SCRIPT ERROR:|Parse Error:", re.I | re.M)


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT).decode("utf-8")


def contracts(root: Path, paths: list[str], *, audit_all: bool = False) -> list[tuple[str, str]]:
    """Native plan follows FAST plus direct edits; all-registry review is static only."""
    result = list(select(paths, root))
    all_pairs = list(ALWAYS) + list(CASES.values())
    all_pairs += [(t["script"], t["marker"]) for s in load_suites(root)
                  for t in s["fast_tests"]]
    for pair in all_pairs:
        if audit_all or "tests/" + pair[0] in paths:
            if pair not in result:
                result.append(pair)
    return result


def marker_findings(root: Path, pairs: list[tuple[str, str]]) -> tuple[list[str], list[str]]:
    missing, review = [], []
    for script, marker in pairs:
        path = root / "tests" / script
        if not path.is_file():
            missing.append(f"Missing test: tests/{script}")
            continue
        source = path.read_text(encoding="utf-8")
        # A substring inside another identifier is not the same contract.
        # Literal presence remains advisory: only runtime output proves emission.
        pattern = r"(?<![A-Za-z0-9_])" + re.escape(marker) + r"(?![A-Za-z0-9_])"
        if not re.search(pattern, source):
            review.append(f"{script}: expected marker not found literally: {marker}")
    return missing, review


def indentation_findings(diff: str) -> list[str]:
    """Heuristic only: continuation alignment can legally mix whitespace."""
    return [line[1:] for line in diff.splitlines()
            if line.startswith("+") and not line.startswith("+++")
            and re.match(r"^[ \t]*\S", line[1:])
            and " " in re.match(r"^[ \t]*", line[1:]).group()
            and "\t" in re.match(r"^[ \t]*", line[1:]).group()]


def run(args: list[str], log: Path, timeout: int = 300,
        marker: str | None = None, godot_log: bool = False) -> None:
    print(f"RUN {log.name}", flush=True)
    with log.open("w", encoding="utf-8") as out:
        result = subprocess.run(args, cwd=ROOT, stdout=out,
                                stderr=subprocess.STDOUT, timeout=timeout)
    content = log.read_text(encoding="utf-8", errors="replace")
    if (result.returncode != 0 or (marker is not None and marker not in content)
            or (godot_log and ERROR.search(content))):
        raise ValueError(f"FAIL {log}: exit={result.returncode}, expected={marker!r}")
    print(f"PASS {log.name}", flush=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", default="origin/main", help="Fetched target ref or SHA")
    parser.add_argument("--native", action="store_true", help="Import and execute FAST fixtures locally")
    parser.add_argument("--audit-registry", action="store_true", help="Review all registered marker contracts without running all fixtures")
    args = parser.parse_args()
    logs = Path(tempfile.mkdtemp(prefix="apex-preflight-"))
    print(f"Logs: {logs}")
    try:
        if git("diff", "--name-only", "-z") or git("ls-files", "--others", "--exclude-standard", "-z"):
            raise ValueError("Stage intended files first; resolve unstaged/untracked files before preflight")
        base = git("merge-base", "HEAD", args.base).strip()
        paths = sorted(set(filter(None, git("diff", "--no-renames", "--name-only", "-z", base, "--").split("\0"))))
        if not paths:
            raise ValueError("No candidate changes relative to merge base")
        print(f"BASE {base}; candidate working tree; {len(paths)} changed paths")
        run(["git", "diff", "--check", base, "--"], logs / "git-diff-check.log")
        for path in paths:
            if path.endswith(".gd") and (ROOT / path).is_file():
                diff = git("diff", "--unified=0", base, "--", path)
                for line in indentation_findings(diff):
                    print(f"REVIEW indentation {path}: {line[:100]!r}")
        pairs = contracts(ROOT, paths)
        audited = contracts(ROOT, paths, audit_all=args.audit_registry or FILE.as_posix() in paths)
        missing, review = marker_findings(ROOT, audited)
        for finding in missing + review:
            print("REVIEW " + finding)
        if missing:
            raise ValueError("Registered test files are missing")
        run([sys.executable, "tools/apex_source_inventory.py", "--check",
             "--output", str(logs / "source-inventory.json")], logs / "inventory.log")
        for pattern in ("test_apex_ci_tiers.py", "test_apex_preflight.py"):
            run([sys.executable, "-m", "unittest", "discover", "-s", "tools/tests",
                 "-p", pattern, "-v"], logs / (pattern + ".log"))
        if not args.native:
            print("NOT_RUN Godot import and fixture execution; static marker review is not runtime proof")
            if review:
                print("INCONCLUSIVE marker contracts: inspect or execute native tests before push")
                return 2
            print("APEX_PREFLIGHT_STATIC_PASS (not FAST)")
            return 0
        version = subprocess.check_output(["godot", "--version"], cwd=ROOT, text=True).strip()
        if not re.match(r"^4\.7\.2(?:[.\s]|$)", version):
            raise ValueError(f"Godot 4.7.2 required; got {version}")
        # Same project import flags and isolated fixture runner as existing CI.
        # No deletion of developer files or automatic reformatting.
        run(["godot", "--headless", "--single-threaded-scene", "--path", ".", "--import"],
            logs / "godot-import.log", timeout=240, godot_log=True)
        # Native validation is bounded to the selected plan. Unselected static
        # findings need separate review; do not silently claim them validated.
        _, native_review = marker_findings(ROOT, pairs)
        unresolved = set(review) - set(native_review)
        for index, (script, marker) in enumerate(pairs):
            run(["bash", "tools/apex_ci_isolated_test.sh", script],
                logs / f"{index:03d}-{script}.log", marker=marker, godot_log=True)
            if script == "visual_stutter_06672_benchmark.gd":
                run(["env", "APEX_MOTION_PROFILE=developed", "APEX_MOTION_SEED=42",
                     "bash", "tools/apex_ci_isolated_test.sh", script],
                    logs / f"{index:03d}-motion-developed.log",
                    marker="VISUAL_STUTTER_06672_BENCHMARK", godot_log=True)
        if unresolved:
            print("INCONCLUSIVE unselected registry marker contracts require review")
            return 2
        print("APEX_PREFLIGHT_NATIVE_PASS (local candidate only; GitHub FAST still required)")
        return 0
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        print(f"APEX_PREFLIGHT_FAIL: {exc}; logs: {logs}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
