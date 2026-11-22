#!/usr/bin/env python3
"""APEX QA registry 2.0: strict, additive manifest shared by FAST and FULL.

Never execute instructions from a manifest. A trusted baseline manifest is
unioned with a candidate manifest so candidates cannot remove existing checks.
"""
from __future__ import annotations

from fnmatch import fnmatchcase
import json
from pathlib import Path
import re

ID = re.compile(r"[a-z][a-z0-9_]{2,63}\Z")
PATH = re.compile(r"[A-Za-z0-9_./*?-]+\Z")
SCRIPT = re.compile(r"[A-Za-z0-9_-]+\.gd\Z")
MARKER = re.compile(r"[A-Za-z0-9_ .:-]{3,120}\Z")
WORKFLOW = re.compile(r"[A-Za-z0-9_-]+\.ya?ml\Z")
FILE = Path(".github/apex-quality-suites.json")


def _valid_path(value: str) -> bool:
    return (isinstance(value, str) and PATH.fullmatch(value) is not None
            and not value.startswith("/") and ".." not in value
            and not value.startswith("./") and "\\" not in value)


def _read(root: Path) -> list[dict]:
    path = root / FILE
    if not path.is_file():
        return []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, ValueError) as exc:
        raise ValueError(f"Invalid QA registry {path}: {exc}") from exc
    if not isinstance(data, dict) or data.get("schema") != 1 or not isinstance(data.get("suites"), list):
        raise ValueError("QA registry must have schema=1 and a suites array")
    if set(data) != {"schema", "suites"}:
        raise ValueError("Unknown top-level QA registry fields")
    parsed = []
    names = set()
    for entry in data["suites"]:
        if not isinstance(entry, dict) or set(entry) != {"id", "paths", "fast_tests", "checks"}:
            raise ValueError("QA suite requires exactly id, paths, fast_tests and checks")
        sid = entry["id"]
        if not isinstance(sid, str) or not ID.fullmatch(sid) or sid in names:
            raise ValueError("Invalid or duplicated QA suite ID")
        names.add(sid)
        patterns = entry["paths"]
        fast = entry["fast_tests"]
        checks = entry["checks"]
        if not isinstance(patterns, list) or not patterns or len(patterns) > 60 or not all(_valid_path(x) for x in patterns):
            raise ValueError(f"Invalid path patterns for {sid}")
        if not isinstance(fast, list) or not isinstance(checks, list) or len(fast) > 60 or len(checks) > 60 or not (fast or checks):
            raise ValueError(f"QA suite {sid} must define actual tests or checks")
        for test in fast:
            if not isinstance(test, dict) or set(test) != {"script", "marker"}:
                raise ValueError(f"Invalid fast test descriptor in {sid}")
            if not isinstance(test["script"], str) or not SCRIPT.fullmatch(test["script"]):
                raise ValueError(f"FAST script must be a tests/*.gd basename in {sid}")
            if not isinstance(test["marker"], str) or not MARKER.fullmatch(test["marker"]):
                raise ValueError(f"Invalid FAST success marker in {sid}")
        for check in checks:
            if not isinstance(check, dict) or set(check) != {"key", "workflow", "job", "area", "comparison"}:
                raise ValueError(f"Invalid FULL check descriptor in {sid}")
            if not isinstance(check["key"], str) or not ID.fullmatch(check["key"]):
                raise ValueError(f"Invalid FULL check key in {sid}")
            if not isinstance(check["workflow"], str) or not WORKFLOW.fullmatch(check["workflow"]):
                raise ValueError(f"Invalid workflow filename in {sid}")
            if not isinstance(check["job"], str) or not 1 <= len(check["job"]) <= 150 or any(ord(c) < 32 for c in check["job"]):
                raise ValueError(f"Invalid job name in {sid}")
            if not isinstance(check["area"], str) or not 1 <= len(check["area"]) <= 90 or any(ord(c) < 32 for c in check["area"]):
                raise ValueError(f"Invalid area in {sid}")
            if type(check["comparison"]) is not bool:
                raise ValueError(f"Invalid comparison flag in {sid}")
        parsed.append(entry)
    return parsed


def load_suites(candidate: Path, trusted: Path | None = None) -> list[dict]:
    """Additive union; a candidate cannot delete/replace trusted requirements."""
    combined: dict[str, dict] = {}
    roots = [trusted, candidate] if trusted is not None else [candidate]
    for root in roots:
        for entry in _read(root):
            target = combined.setdefault(entry["id"], {
                "id": entry["id"], "paths": [], "fast_tests": [], "checks": [],
            })
            for field in ("paths", "fast_tests", "checks"):
                for item in entry[field]:
                    if item not in target[field]:
                        target[field].append(item)
    return [combined[k] for k in sorted(combined)]


def fast_tests_for(paths: list[str], suites: list[dict]) -> list[tuple[str, str]]:
    found: list[tuple[str, str]] = []
    for suite in suites:
        if any(fnmatchcase(path, pattern) for path in paths for pattern in suite["paths"]):
            for test in suite["fast_tests"]:
                pair = (test["script"], test["marker"])
                if pair not in found:
                    found.append(pair)
    return found


def full_checks(suites: list[dict]) -> list[dict]:
    """All registered FULL requirements participate in FULL homologation."""
    out: dict[str, dict] = {}
    for suite in suites:
        for check in suite["checks"]:
            previous = out.get(check["key"])
            if previous is not None and previous != check:
                raise ValueError(f"Conflicting FULL check key: {check['key']}")
            out[check["key"]] = check
    return [out[k] for k in sorted(out)]

def full_checks_for_paths(suites: list[dict], paths: list[str]) -> list[dict]:
    """Require targeted FULL jobs only for modules touched by exact PR diff.

    All ten built-in requirements remain unconditional. Trusted manifests are
    combined with candidate manifests before evaluating affected modules.
    """
    if not paths or any(not isinstance(p, str) or not p for p in paths):
        raise ValueError("Cannot scope FULL checks to an empty or invalid diff")
    affected = [suite for suite in suites
                if any(fnmatchcase(path, pattern)
                       for path in paths for pattern in suite["paths"])]
    return full_checks(affected)
