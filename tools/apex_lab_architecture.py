#!/usr/bin/env python3
"""Original APEX literal dependency and test coverage inventory. Read only."""
import argparse
from collections import Counter
import json
from pathlib import Path
import re
import subprocess
import sys

MAX_FILES = 5000
MAX_BYTES = 2_000_000
MAX_TOTAL = 64_000_000
# Consume complete quoted strings and comments before identifiers. This is
# deliberately not a GDScript parser. Dynamic/class_name/UID dependencies
# and runtime load() are outside the compile-reference graph.
LEX = re.compile(
    r'(?P<comment>#[^\n]*)|'
    r'(?P<string>"""(?:\\.|(?!""").)*"""|'
    r"'''(?:\\.|(?!''').)*'''|"
    r'"(?:\\.|[^"\\\n])*"|'
    r"'(?:\\.|[^'\\\n])*')|"
    r'(?P<word>[A-Za-z_][A-Za-z_0-9]*)|'
    r'(?P<punct>[().])|(?P<newline>\n)|(?P<other>[^\s])',
    re.S,
)
PATH = re.compile(r"""["']res://([A-Za-z0-9_./-]+\.gd)["']\Z""")
FUNC = re.compile(r"^(?:static\s+)?func\s+([A-Za-z_]\w*)\s*\(")


def tokens(source):
    for match in LEX.finditer(source):
        if match.lastgroup not in ("comment", "newline"):
            yield match.lastgroup, match.group(), match.start()


def literal_edges(source):
    ts = list(tokens(source))
    edges = set()
    for i, (kind, value, offset) in enumerate(ts):
        if kind != "word":
            continue
        if value == "preload" and i + 3 < len(ts):
            if i and ts[i-1][1] == ".":
                continue
            if ts[i+1][1] != "(" or ts[i+2][0] != "string" or ts[i+3][1] != ")":
                continue
            arg = ts[i+2][1]
        elif value == "extends" and i + 1 < len(ts) and ts[i+1][0] == "string":
            # Only a top-level extends directive, not arbitrary string usage.
            if source[source.rfind("\n", 0, offset)+1:offset].strip():
                continue
            arg = ts[i+1][1]
        else:
            continue
        match = PATH.fullmatch(arg)
        if match and all(p not in ("", ".", "..") for p in match[1].split("/")):
            edges.add(match[1])
    return sorted(edges)


def long_functions(source, threshold=80):
    # Approximate physical span of top-level functions; ignore multiline
    # strings/comments by examining lexical tokens, not raw quoted content.
    ts = list(tokens(source))
    import bisect
    starts = [0] + [m.end() for m in re.finditer("\n", source)]
    line_tokens = {}
    for kind, value, offset in ts:
        line = bisect.bisect_right(starts, offset)
        line_tokens.setdefault(line, (kind, value, offset))
    rows = []
    current = None
    for line, (_, value, offset) in sorted(line_tokens.items()):
        prefix = source[starts[line-1]:offset]
        if prefix.strip() or prefix:
            continue
        if current:
            name, first = current
            span = line - first
            if span >= threshold:
                rows.append({"function": name, "line": first, "physical_span": span})
            current = None
        match = FUNC.match(source[offset:])
        if match:
            current = (match[1], line)
    if current:
        name, first = current
        span = len(starts) - first + 1
        if span >= threshold:
            rows.append({"function": name, "line": first, "physical_span": span})
    return rows


def cycle_components(graph):
    """Iterative Kosaraju; report SCCs, not invented individual cycle paths."""
    visited, order = set(), []
    for start in sorted(graph):
        if start in visited:
            continue
        visited.add(start)
        stack = [(start, iter(graph[start]))]
        while stack:
            node, neighbors = stack[-1]
            nxt = next(neighbors, None)
            if nxt is None:
                order.append(node)
                stack.pop()
            elif nxt not in visited:
                visited.add(nxt)
                stack.append((nxt, iter(graph[nxt])))
    reverse = {node: [] for node in graph}
    for node, targets in graph.items():
        for target in targets:
            reverse[target].append(node)
    visited.clear()
    groups = []
    for start in reversed(order):
        if start in visited:
            continue
        visited.add(start)
        group, stack = [], [start]
        while stack:
            node = stack.pop()
            group.append(node)
            for nxt in reverse[node]:
                if nxt not in visited:
                    visited.add(nxt)
                    stack.append(nxt)
        if len(group) > 1 or start in graph[start]:
            groups.append(sorted(group))
    return sorted(groups)


def scan(root, names):
    root = root.resolve()
    names = sorted(set(p for p in names if p.startswith("scripts/") and p.endswith(".gd")))
    if not names or len(names) > MAX_FILES:
        raise ValueError("Empty or oversized script scope")
    graph = {name: [] for name in names}
    external, large, errors = [], [], []
    total = 0
    for name in names:
        p = root / name
        try:
            if p.resolve() != p or not p.is_file():
                raise ValueError("Not a regular in-tree file")
            size = p.stat().st_size
            if size > MAX_BYTES or total + size > MAX_TOTAL:
                raise ValueError("Scan byte limit exceeded")
            total += size
            source = p.read_text(encoding="utf-8-sig")
            for target in literal_edges(source):
                if target in graph:
                    graph[name].append(target)
                else:
                    external.append({"source": name, "target": target})
            for row in long_functions(source):
                large.append({"file": name, **row})
        except (OSError, UnicodeError, ValueError) as error:
            errors.append({"file": name, "reason": type(error).__name__})
    inbound = Counter(target for targets in graph.values() for target in targets)
    return {"schema": 1, "complete": not errors, "scope": "tracked scripts/**/*.gd",
            "scripts": len(names), "edges": graph, "edge_count": sum(map(len, graph.values())),
            "cyclic_components": cycle_components(graph),
            "external_literal_targets": external,
            "long_function_candidates": sorted(large, key=lambda r: (-r["physical_span"], r["file"], r["line"])),
            "most_referenced": [{"file": name, "references": count}
                                for name, count in sorted(inbound.items(), key=lambda p: (-p[1], p[0]))[:20]],
            "errors": errors, "limitations": [
                "Lexical heuristic, not parser or proof of actual dependency cycles.",
                "Only literal res:// .gd preload and extends; dynamic load, class_name, UID and scenes omitted.",
                "Physical span is approximate, not complexity or runtime cost.",
                "External targets and large functions require inspection; no edits, no finding-based gate."]}


def coverage(root):
    from apex_ci_tiers import ALWAYS, CASES
    from apex_quality_manifest import load_suites
    # Inspect existing manifest directly; validate with the existing loader.
    load_suites(root)
    raw = json.loads((root / ".github/apex-quality-suites.json").read_text(encoding="utf-8"))
    refs = set(ALWAYS) | set(CASES.values())
    for suite in raw["suites"]:
        refs.update((test["script"], test["marker"]) for test in suite["fast_tests"])
    missing = sorted(script for script, _ in refs if not (root / "tests" / script).is_file())
    return {"registered_fixture_count": len({script for script, _ in refs}),
            "missing_registered_fixtures": sorted(set(missing)),
            "limitations": ["Existence only; no semantic coverage or PASS inferred."]}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--output", required=True, type=Path)
    args = p.parse_args()
    root = Path.cwd().resolve()
    try:
        raw = subprocess.check_output(["git", "ls-files", "-z", "--", "scripts"], cwd=root, timeout=30)
        report = scan(root, [v.decode("utf-8") for v in raw.split(b"\0") if v])
        report["coverage"] = coverage(root)
        args.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print("APEX_LAB_ARCHITECTURE " + json.dumps({
            "complete": report["complete"], "scripts": report["scripts"], "edges": report["edge_count"],
            "cyclic_components": len(report["cyclic_components"]),
            "long_function_candidates": len(report["long_function_candidates"]),
            "coverage": report["coverage"],
            "most_referenced": report["most_referenced"]}))
        return 0 if report["complete"] else 2
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print("APEX_LAB_ARCHITECTURE_BLOCKED " + type(error).__name__, file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
