#!/usr/bin/env python3
"""Opt-in grouped A/B pilot; compare isolated legacy runs against one grouped run."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

MODES = {
    "coordination": "APEX_COORDINATION",
    "corner": "APEX_CORNER_BATTLE",
    "traffic": "APEX_DRIVER_TRAFFIC",
    "mega": "APEX_TRAFFIC_MEGA",
    "error": "APEX_DRIVER_ERROR",
}
NONSPORTING = {"elapsed_us", "engine_us", "peak_static_bytes_sampled", "engine_us_per_tick"}
ERROR = re.compile(r"^ERROR:|SCRIPT ERROR:|Parse Error:", re.M | re.I)
SCRIPT = "aero_wake_091711_test.gd"


def require(ok, message):
    if not ok:
        raise ValueError(message)


def json_line(lines, marker):
    matches = [line[len(marker):] for line in lines if line.startswith(marker)]
    require(len(matches) == 1, f"expected one {marker!r}, got {len(matches)}")
    return json.loads(matches[0])


def read_case(lines, expected):
    result = json_line(lines, "AERO_WAKE_AB ")
    for key, value in expected.items():
        require(result.get(key) == value, f"unexpected scenario {key}")
    report = json_line(lines, "AERO_WAKE_REPORT ")
    trace = json_line(lines, "AERO_WAKE_ASSERT_TRACE ")
    fixture = json_line(lines, "AERO_WAKE_FIXTURE ")
    require(report.get("failures") == [] and type(report.get("checks")) is int and report["checks"] > 0, "failed or empty assertions")
    require(trace.get("count") == report["checks"] and re.fullmatch(r"[0-9a-f]{64}", str(trace.get("sha256", ""))), "invalid assertion trace")
    require(lines.count("AERO_WAKE_091711_PASS") == 1, "missing or repeated legacy PASS")
    for side in ("old", "new"):
        require(isinstance(result.get(side), dict) and NONSPORTING <= result[side].keys(), f"incomplete {side} report")
        require(re.fullmatch(r"[0-9a-f]{64}", str(result[side].get("hash", ""))), f"invalid {side} hash")
        require(result[side].get("ticks") == expected["ticks"], f"unexpected {side} tick count")
        result[side] = {k: v for k, v in result[side].items() if k not in NONSPORTING}
    return {"result": result, "report": report, "trace": trace, "fixture": fixture}


def grouped_cases(lines, expected):
    groups = {}
    mode = None
    for line in lines:
        if line.startswith("AERO_WAKE_GROUP_MODE "):
            mode = line.split(" ", 1)[1]
            require(mode in MODES and mode not in groups, "unexpected or duplicate mode")
            groups[mode] = []
        elif mode is not None:
            groups[mode].append(line)
    require(list(groups) == list(MODES), "missing or reordered grouped mode")
    summary = json_line(lines, "AERO_WAKE_GROUP_REPORT ")
    require(summary == {"primary_calls": 6, "hits": 4, "complete": True, "all_ok": True}, "wrong grouped execution counts")
    require(lines.count("AERO_WAKE_GROUP_PASS") == 1, "missing grouped PASS")
    return {mode: read_case(group, expected) for mode, group in groups.items()}


def compare(baseline, candidate):
    require(list(baseline) == list(candidate) == list(MODES), "missing comparison")
    for mode in MODES:
        for key in ("result", "report", "trace", "fixture"):
            require(baseline[mode][key] == candidate[mode][key], f"{mode}: mismatch in {key}")


def run_test(env, log_path):
    start = time.monotonic()
    with log_path.open("w", encoding="utf-8") as log:
        completed = subprocess.run(
            ["bash", "tools/apex_ci_isolated_test.sh", SCRIPT], env=env,
            stdout=log, stderr=subprocess.STDOUT, timeout=260,
        )
    duration = time.monotonic() - start
    content = log_path.read_text(encoding="utf-8", errors="replace")
    require(completed.returncode == 0 and not ERROR.search(content), f"failed native run: {log_path}")
    return content.splitlines(), duration


def self_test():
    from copy import deepcopy
    base = {mode: {"result": {"hash": "a"}, "report": {"checks": 2}, "trace": {"sha256": "b"}, "fixture": {"x": 1}} for mode in MODES}
    compare(base, deepcopy(base))
    for key in ("result", "report", "trace", "fixture"):
        candidate = deepcopy(base)
        candidate["corner"][key] = {"injected": True}
        try:
            compare(base, candidate)
        except ValueError:
            pass
        else:
            raise AssertionError(f"missed injected mismatch: {key}")
    candidate = deepcopy(base)
    del candidate["mega"]
    try:
        compare(base, candidate)
    except ValueError:
        pass
    else:
        raise AssertionError("missed missing mode")
    print("APEX_GROUPED_PILOT_SELF_TEST_PASS")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--track", choices=["ITA", "GBR", "MON"])
    parser.add_argument("--climate", choices=["Seco", "Chuva intensa"])
    parser.add_argument("--seed", type=int, choices=[42, 123])
    parser.add_argument("--output", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if None in (args.track, args.climate, args.seed, args.output):
        parser.error("track, climate, seed and output required")
    args.output.mkdir(parents=True, exist_ok=False)
    expected = {"track": args.track, "climate": args.climate, "seed": args.seed, "ticks": 1800, "full": False}
    env = os.environ.copy()
    for key in (*MODES.values(), "APEX_AERO_GROUPED_PILOT", "APEX_AERO_FULL"):
        env.pop(key, None)
    env.update(APEX_AERO_TRACK=args.track, APEX_AERO_CLIMATE=args.climate,
               APEX_AERO_SEED=str(args.seed), APEX_AERO_TICKS="1800", APEX_AERO_ASSERT_TRACE="1")
    try:
        baseline = {}
        baseline_seconds = {}
        for mode, flag in MODES.items():
            lines, duration = run_test(dict(env, **{flag: "1"}), args.output / f"legacy-{mode}.log")
            baseline[mode] = read_case(lines, expected)
            baseline_seconds[mode] = duration
        lines, grouped_seconds = run_test(dict(env, APEX_AERO_GROUPED_PILOT="1"), args.output / "grouped.log")
        candidate = grouped_cases(lines, expected)
        compare(baseline, candidate)
        summary = {
            "scenario": expected, "status": "PASS", "comparisons": list(MODES),
            "primary_calls": {"legacy": 10, "grouped": 6},
            "legacy_seconds": baseline_seconds, "grouped_seconds": grouped_seconds,
            "scope": "same job, native isolated processes, all reported sporting fields and assertion trace; not a controlled performance benchmark",
            "excluded_volatile_fields": sorted(NONSPORTING),
            "checkout": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
            "godot": subprocess.check_output(["godot", "--version"], text=True).strip(),
        }
        (args.output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
        print("APEX_GROUPED_PILOT_PASS", json.dumps(summary, ensure_ascii=False))
        return 0
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"APEX_GROUPED_PILOT_FAIL: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
