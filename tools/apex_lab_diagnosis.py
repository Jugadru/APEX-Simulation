#!/usr/bin/env python3
"""Bounded, deterministic diagnosis of observed CI failures; no source editing."""
import re
from collections import deque
from pathlib import Path

MAX_BYTES = 512 * 1024
MAX_LINE = 300
MAX_LOCATIONS = 8
# Only project-relative script/resource paths; never copy arbitrary log text.
LOCATION = re.compile(r"res://([A-Za-z0-9_./-]+\.(?:gd|tscn|tres|gdshader))(?::([0-9]{1,8}))?")
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
RULES = (
    ("PARSE", re.compile(r"Parse Error:|Parser Error:|Failed to parse", re.I),
     "Inspect the first reported script and its typed dependencies; rerun import after a real fix."),
    ("RESOURCE", re.compile(r"Failed loading resource|Cannot open file|Resource file not found|Unable to load resource|Missing mandatory FAST test", re.I),
     "Check tracked resource path, case, imports and dependency availability."),
    ("SCRIPT_RUNTIME", re.compile(r"SCRIPT ERROR:|Invalid (?:access|call|assignment|operands|get index|set index)|Out of bounds", re.I),
     "Inspect the reported function and reproduce with the same fixture and seed."),
    ("ASSERTION", re.compile(r"Assertion failed|AssertionError|^.*\b(?:APEX_[A-Z0-9_]+_FAIL|FAIL:)\b", re.I),
     "Read the fixture assertion and verify the sporting or UI contract before changing code."),
    ("ENGINE_ERROR", re.compile(r"^\s*ERROR:", re.M),
     "Inspect the engine diagnostic and relevant resource or runtime state."),
)
ACTIONS = {
    "TIMEOUT": "Check workload, deadlock and resource evidence; do not retry blindly.",
    "EXECUTABLE_UNAVAILABLE": "Verify runner dependency and executable installation.",
    "MISSING_MARKER": "Inspect the fixture exit path and required success marker; absence is not PASS.",
    "NONZERO_EXIT": "Inspect the raw job log and exit status; do not infer a root cause.",
    "INCOMPLETE_LOG": "Inspect the complete original log; the bounded scan omitted data.",
    "NONE": "No failure observed in this case.",
}

def diagnose(log: Path, *, status: str, exit_code=None, reason="", marker=None):
    """Classifies evidence, not root cause. PASS cannot be inferred from logs here."""
    locations = []
    found = set()
    truncated = False
    try:
        with log.open("rb") as stream:
            prefix = stream.read(MAX_BYTES + 1)
            truncated = len(prefix) > MAX_BYTES
            if truncated:
                # Sample both ends, without scanning unlimited logs.
                stream.seek(0, 2)
                size = stream.tell()
                stream.seek(max(0, size - MAX_BYTES // 2))
                data = prefix[:MAX_BYTES // 2] + b"\n" + stream.read(MAX_BYTES // 2)
            else:
                data = prefix
        for raw in data.decode("utf-8", errors="replace").splitlines():
            line = ANSI.sub("", raw)[:MAX_LINE]
            matched = [name for name, pattern, _ in RULES if pattern.search(line)]
            found.update(matched)
            for match in LOCATION.finditer(line):
                path, number = match.groups()
                if any(part in ("", ".", "..") for part in path.split("/")):
                    continue
                loc = {"file": path, "line": int(number) if number else None}
                if loc not in locations and len(locations) < MAX_LOCATIONS:
                    locations.append(loc)
    except OSError:
        truncated = True
    if status == "PASS":
        kind = "NONE"
    elif reason == "timeout":
        kind = "TIMEOUT"
    elif reason == "executable unavailable":
        kind = "EXECUTABLE_UNAVAILABLE"
    else:
        kind = next((name for name, _, _ in RULES if name in found), None)
        if not kind:
            if truncated:
                kind = "INCOMPLETE_LOG"
            elif exit_code not in (0, None):
                kind = "NONZERO_EXIT"
            elif marker:
                kind = "MISSING_MARKER"
            else:
                kind = "NONZERO_EXIT"
    action = next((suggestion for name, _, suggestion in RULES if name == kind), ACTIONS.get(kind, "Inspect evidence."))
    return {"kind": kind, "signals": [name for name, _, _ in RULES if name in found],
            "locations": locations, "log_partial": truncated,
            "next_action": action, "root_cause": "NOT_ESTABLISHED" if status != "PASS" else "NOT_APPLICABLE"}
