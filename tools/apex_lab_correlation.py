#!/usr/bin/env python3
"""Correlate observed failures with immutable diff and literal dependencies."""
from collections import deque
import json
from pathlib import Path
import re
import subprocess

SHA = re.compile(r"[0-9a-f]{40}\Z")
MAX_CHANGED = 10000
MAX_RESULTS = 20
MAX_DEPTH = 3


def change_context(root, base, head):
    from apex_ci_tiers import changed_files, categories_for
    if not SHA.fullmatch(head) or (base and not SHA.fullmatch(base)):
        raise ValueError("Exact revision required")
    if not base:
        base = subprocess.check_output(
            ["git", "rev-parse", head + "^"], cwd=root, text=True, timeout=20).strip()
    if not SHA.fullmatch(base):
        raise ValueError("Exact base required")
    paths = changed_files(root, base, head)
    if len(paths) > MAX_CHANGED:
        raise ValueError("Diff path limit exceeded")
    return {"base": base, "head": head, "changed_files": paths,
            "domains": sorted(categories_for(paths))}


def neighborhood(graph, starts):
    # Keep both directions separate: a consumer is not its dependency.
    reverse = {node: [] for node in graph}
    for node, targets in graph.items():
        for target in targets:
            if target in reverse:
                reverse[target].append(node)
    for label, adjacency in (("literal_dependency", graph), ("literal_consumer", reverse)):
        for start in sorted(set(starts)):
            visited = {start}
            queue = deque([(start, [start])])
            while queue:
                node, path = queue.popleft()
                if len(path) - 1 >= MAX_DEPTH:
                    continue
                for target in sorted(set(adjacency.get(node, []))):
                    if target not in visited:
                        visited.add(target)
                        new_path = path + [target]
                        queue.append((target, new_path))
                        yield target, label, new_path


def correlate(context, cases, plan, architecture=None):
    changed = set(context["changed_files"])
    graph_complete = bool(architecture and architecture.get("complete") is True)
    graph = architecture["edges"] if graph_complete else {}
    failures = []
    for case in cases:
        if case.get("status") not in ("FAIL", "BLOCKED"):
            continue
        diag = case.get("diagnosis", {})
        locations = diag.get("locations", [])
        starts = sorted({loc["file"] for loc in locations})
        name = case["name"]
        fixture = "tests/" + name if re.fullmatch(r"[A-Za-z0-9_]+\.gd", name) else None
        if fixture:
            starts = sorted(set(starts + [fixture]))
        matches = {}
        for path in starts:
            if path in changed:
                matches[path] = {"file": path, "relation": "direct_path_match", "path": [path]}
        for target, relation, chain in neighborhood(graph, starts):
            if target not in changed:
                continue
            prev = matches.get(target)
            if prev is None or len(chain) < len(prev["path"]):
                matches[target] = {"file": target, "relation": relation, "path": chain}
        ordered = sorted(matches.values(), key=lambda r: (len(r["path"]), r["file"], r["relation"]))
        failures.append({
            "case": name, "status": case["status"], "kind": diag.get("kind", "UNKNOWN"),
            "locations": locations, "log_partial": diag.get("log_partial"),
            "candidate_count": len(ordered), "candidates": ordered[:MAX_RESULTS],
            "next_action": diag.get("next_action", "Inspect original log."),
            "suggested_validation": ([name] if fixture else []) + (
                ["Godot import"] if name == "import" else []),
            "root_cause": "NOT_ESTABLISHED"})
    seen = {case["name"] for case in cases}
    return {"schema": 1, "base": context["base"], "head": context["head"],
            "changed_file_count": len(changed), "domains": context["domains"],
            "graph_complete": graph_complete,
            "state": "FAILURE_EVIDENCE" if failures else "NO_CASE_FAILURE_OBSERVED",
            "failures": failures,
            "planned_not_executed": [r["script"] for r in plan if r["script"] not in seen],
            "limitations": ["Correlation is not causation or a code repair.",
                "Graph only includes literal current-revision GDScript edges, up to three hops in either direction.",
                "No match does not exclude changed or unchanged files.",
                "Planned fixtures not run have no result. Official FAST remains required."]}


def from_report(root, report, out):
    context = change_context(root, report["base"], report["head"])
    arch_path = out / "architecture.json"
    architecture = None
    if arch_path.is_file():
        architecture = json.loads(arch_path.read_text(encoding="utf-8"))
    return correlate(context, report["cases"], report.get("plan", []), architecture)
