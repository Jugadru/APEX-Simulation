#!/usr/bin/env python3
"""Opt-in grouped A/B pilot; compare isolated legacy runs against one grouped run."""
from __future__ import annotations

import argparse
import hashlib
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
FIXTURES = {
    "coordination": ("tactical_coordination_091712_test.gd", "COORDINATION_091712_PASS"),
    "corner": ("corner_battle_0919_test.gd", "CORNER_BATTLE_0919_PASS"),
    "traffic": ("driver_traffic_0920_test.gd", "DRIVER_TRAFFIC_0920_PASS"),
    "mega": ("traffic_mega_09201_test.gd", "TRAFFIC_MEGA_09201_PASS"),
    "error": ("driver_error_0921_test.gd", "DRIVER_ERROR_0921_PASS"),
}
CENTRAL_WORKFLOW = Path(".github/workflows/apex-tactical-coordination.yml")
# Union of the five legacy path filters plus the directly loaded dependencies
# and runner/import files. Keep this contract additive.
REQUIRED_ROUTES = {
    ".github/workflows/apex-corner-battle.yml",
    ".github/workflows/apex-driver-error-0921.yml",
    ".github/workflows/apex-driver-traffic-0920.yml",
    ".github/workflows/apex-tactical-coordination.yml",
    ".github/workflows/apex-traffic-mega-09201.yml",
    "data/season_2012.json",
    "project.godot",
    "scripts/core/race_aero_wake_091711.gd",
    "scripts/core/race_corner_battle_0919.gd",
    "scripts/core/race_driver_error_0921.gd",
    "scripts/core/race_driver_traffic_0920.gd",
    "scripts/core/race_independent_racecraft_091710.gd",
    "scripts/core/race_kers_2012.gd",
    "scripts/core/race_merge_traffic_0669174.gd",
    "scripts/core/race_performance.gd",
    "scripts/core/race_pit_lane.gd",
    "scripts/core/race_racing_line_091710.gd",
    "scripts/core/race_replay_0660.gd",
    "scripts/core/race_space_0655.gd",
    "scripts/core/race_state_codec_0660.gd",
    "scripts/core/race_tactical_coordination_091712.gd",
    "scripts/core/race_traffic_pack_09201.gd",
    "scripts/core/race_traffic_strategy_09201.gd",
    "scripts/core/race_tyre_thermal.gd",
    "scripts/core/race_weather_setup_15.gd",
    "scripts/race_engine.gd",
    "tests/aero_wake_091711_test.gd",
    "tests/corner_battle_0919_test.gd",
    "tests/driver_error_0921_test.gd",
    "tests/driver_traffic_0920_test.gd",
    "tests/tactical_coordination_091712_test.gd",
    "tests/traffic_mega_09201_test.gd",
    "tools/apex_ci_grouped_pilot.py",
    "tools/apex_ci_import.sh",
    "tools/apex_ci_isolated_test.sh",
}


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


def native_budget(env):
    anchor = {
        "APEX_AERO_GROUPED_PILOT": "1", "APEX_AERO_ASSERT_TRACE": "1",
        "APEX_AERO_TRACK": "ITA", "APEX_AERO_CLIMATE": "Seco",
        "APEX_AERO_SEED": "42", "APEX_AERO_TICKS": "1800",
    }
    return 1200 if all(env.get(k) == v for k, v in anchor.items()) and env.get("APEX_AERO_FULL") != "1" else 240


def native_failure(content, returncode, duration, budget):
    lines = content.splitlines()
    modes = [line.split(" ", 1)[1] for line in lines if line.startswith("AERO_WAKE_GROUP_MODE ")]
    errors = [line[:500] for line in lines if ERROR.search(line) or "AERO_WAKE_FAIL" in line or "AERO_WAKE_GROUP_INVALID" in line]
    return {
        "returncode": returncode, "seconds": round(duration, 2), "native_budget_s": budget,
        "timeout": returncode == 124 or returncode == "outer-timeout",
        "last_mode": modes[-1] if modes else None,
        "completed_comparisons": lines.count("AERO_WAKE_091711_PASS"),
        "errors": errors[-10:],
        "group_summary": [line[:500] for line in lines if line.startswith("AERO_WAKE_GROUP_REPORT ")][-1:],
    }


def run_test(env, log_path, script=SCRIPT):
    budget = native_budget(env) if script == SCRIPT else 240
    start = time.monotonic()
    returncode = None
    with log_path.open("w", encoding="utf-8") as log:
        try:
            completed = subprocess.run(
                ["bash", "tools/apex_ci_isolated_test.sh", script], env=env,
                stdout=log, stderr=subprocess.STDOUT, timeout=budget + 20,
            )
            returncode = completed.returncode
        except subprocess.TimeoutExpired:
            returncode = "outer-timeout"
    duration = time.monotonic() - start
    content = log_path.read_text(encoding="utf-8", errors="replace")
    if returncode != 0 or ERROR.search(content):
        evidence = native_failure(content, returncode, duration, budget)
        print("APEX_GROUPED_NATIVE_FAILURE", json.dumps(evidence, ensure_ascii=False), flush=True)
        (log_path.parent / (log_path.stem + "-failure.json")).write_text(
            json.dumps(evidence, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        raise ValueError(f"failed native run: {log_path}; returncode={returncode}")
    require(f"APEX_TEST_TIMEOUT script={script} seconds={budget}" in content.splitlines(), "native timeout contract mismatch")
    print(f"APEX_GROUPED_NATIVE_PASS file={log_path.name} seconds={duration:.2f} budget={budget}", flush=True)
    return content.splitlines(), duration


def check_routing():
    text = CENTRAL_WORKFLOW.read_text(encoding="utf-8")
    paths = set(re.findall(r"^      - '([^']+)'$", text, re.M))
    require(REQUIRED_ROUTES <= paths, f"missing central routes: {sorted(REQUIRED_ROUTES - paths)}")


def validate_chain(candidate):
    require(list(candidate) == list(MODES), "missing grouped modes")
    cases = list(candidate.values())
    for left, right in zip(cases, cases[1:]):
        require(left["result"]["new"] == right["result"]["old"], "shared sporting result mismatch")


def run_fixtures(env, output, modes=tuple(MODES)):
    # Match the five old invariant gates. Never share their HOME/XDG or
    # silently skip a fixture when a previous fixture fails.
    passed = []
    failures = []
    for mode in modes:
        script, marker = FIXTURES[mode]
        try:
            lines, _ = run_test(env, output / f"fixture-{mode}.log", script)
            require(lines.count(marker) == 1, f"{mode}: missing or repeated fixture PASS")
            passed.append(mode)
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            failures.append(f"{mode}: {error}")
    require(not failures and passed == list(modes), f"fixture failure: {failures}")
    return passed


ANCHOR = ("ITA", "Seco", 42)


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"), allow_nan=False).encode("utf-8")).hexdigest()


def evidence_for(cases):
    return {mode: {"old": digest(case["result"]["old"]), "new": digest(case["result"]["new"]),
                   "checks": case["report"]["checks"], "trace": case["trace"]["sha256"]}
            for mode, case in cases.items()}


def verify_production(records, checkout):
    expected = {(track, climate, seed) for track in ("ITA", "GBR", "MON")
                for climate in ("Seco", "Chuva intensa") for seed in (42, 123)}
    seen = set()
    anchor = {}
    total_calls = 0
    fixture_total = 0
    for record in records:
        require(record.get("checkout") == checkout and record.get("status") == "PASS", "wrong candidate or failed report")
        require(record.get("godot", "").startswith("4.7.2."), "wrong Godot version")
        scenario = record["scenario"]
        key = (scenario["track"], scenario["climate"], scenario["seed"])
        require(key in expected and scenario == dict(track=key[0], climate=key[1], seed=key[2], ticks=1800, full=False), "wrong scenario")
        modes = record["comparisons"]
        if key == ANCHOR:
            require(len(modes) == 1 and modes[0] in MODES, "anchor must have one independent mode")
            require(record["primary_calls"] == {"legacy": 2, "grouped": 0}, "wrong anchor primary count")
            require(record["fixture_modes"] == modes, "missing anchor fixture")
        else:
            require(modes == list(MODES), "missing grouped modes")
            require(record["primary_calls"] == {"legacy": 0, "grouped": 6}, "wrong grouped primary count")
            require(record["fixture_modes"] == [], "unexpected non-anchor fixture")
        evidence = record["mode_evidence"]
        require(set(evidence) == set(modes), "missing mode evidence")
        for mode in modes:
            require((key, mode) not in seen, "duplicate scenario/mode")
            seen.add((key, mode))
            item = evidence[mode]
            require(type(item["checks"]) is int and item["checks"] > 0, "missing assertions")
            require(all(re.fullmatch(r"[0-9a-f]{64}", str(item[k])) for k in ("old", "new", "trace")), "invalid mode digest")
            if key == ANCHOR:
                anchor[mode] = item
        if key != ANCHOR:
            for left, right in zip(modes, modes[1:]):
                require(evidence[left]["new"] == evidence[right]["old"], "grouped boundary mismatch")
        total_calls += sum(record["primary_calls"].values())
        fixture_total += len(record["fixture_modes"])
    require(len(records) == 16 and seen == {(key, mode) for key in expected for mode in MODES}, "incomplete 60-comparison production matrix")
    require(total_calls == 76 and fixture_total == 5, "primary or fixture coverage mismatch")
    for left, right in zip(MODES, list(MODES)[1:]):
        require(anchor[left]["new"] == anchor[right]["old"], f"independent historical boundary mismatch: {left}/{right}")
    return {"jobs": 16, "comparisons": len(seen), "primary_calls": total_calls, "fixtures": fixture_total,
            "anchor_boundaries": 4, "checkout": checkout}


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
    anchor = {"APEX_AERO_GROUPED_PILOT": "1", "APEX_AERO_ASSERT_TRACE": "1",
              "APEX_AERO_TRACK": "ITA", "APEX_AERO_CLIMATE": "Seco",
              "APEX_AERO_SEED": "42", "APEX_AERO_TICKS": "1800"}
    require(native_budget(anchor) == 1200, "wrong historical grouped budget")
    for key in anchor:
        changed = dict(anchor)
        changed.pop(key)
        require(native_budget(changed) == 240, f"budget incorrectly extended without {key}")
    require(native_budget(dict(anchor, APEX_AERO_FULL="1")) == 240, "full GP budget leak")
    diagnostic = native_failure("AERO_WAKE_GROUP_MODE coordination\nAERO_WAKE_091711_PASS\nAERO_WAKE_GROUP_MODE corner\n", 124, 240, 240)
    require(diagnostic["timeout"] and diagnostic["last_mode"] == "corner" and diagnostic["completed_comparisons"] == 1, "timeout evidence contract")
    require(not native_failure("AERO_WAKE_FAIL example", 1, 3, 240)["timeout"], "sporting failure misclassified")
    require(list(FIXTURES) == list(MODES), "fixture coverage mismatch")
    chain = {mode: {"result": {"old": {"revision": i}, "new": {"revision": i + 1}}} for i, mode in enumerate(MODES)}
    validate_chain(chain)
    chain["corner"]["result"]["old"]["revision"] = -1
    try:
        validate_chain(chain)
    except ValueError:
        pass
    else:
        raise AssertionError("missed shared sporting mismatch")
    check_routing()
    records = []
    for track in ("ITA", "GBR", "MON"):
        for climate in ("Seco", "Chuva intensa"):
            for seed in (42, 123):
                historical = (track, climate, seed) == ANCHOR
                batches = [[mode] for mode in MODES] if historical else [list(MODES)]
                for modes in batches:
                    records.append({"checkout": "candidate", "status": "PASS", "godot": "4.7.2.test",
                                    "scenario": dict(track=track, climate=climate, seed=seed, ticks=1800, full=False),
                                    "comparisons": modes, "primary_calls": {"legacy": 2 if historical else 0, "grouped": 0 if historical else 6},
                                    "fixture_modes": modes if historical else [],
                                    "mode_evidence": {mode: {"old": digest(list(MODES).index(mode)), "new": digest(list(MODES).index(mode) + 1),
                                                            "checks": 1, "trace": digest("trace")} for mode in modes}})
    verify_production(records, "candidate")
    mutations = [records[:-1], records + [records[0]], deepcopy(records), deepcopy(records), deepcopy(records)]
    mutations[2][0]["mode_evidence"]["coordination"]["new"] = digest("wrong boundary")
    mutations[3][0]["fixture_modes"] = []
    mutations[4][0]["checkout"] = "stale"
    for broken in mutations:
        try:
            verify_production(broken, "candidate")
        except ValueError:
            pass
        else:
            raise AssertionError("matrix gate accepted invalid evidence")
    print("APEX_GROUPED_PILOT_SELF_TEST_PASS")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--track", choices=["ITA", "GBR", "MON"])
    parser.add_argument("--climate", choices=["Seco", "Chuva intensa"])
    parser.add_argument("--seed", type=int, choices=[42, 123])
    parser.add_argument("--output", type=Path)
    parser.add_argument("--self-test", action="store_true")
    mode_group = parser.add_mutually_exclusive_group()
    mode_group.add_argument("--grouped-only", action="store_true", help="production: five grouped comparisons outside historical anchor")
    mode_group.add_argument("--anchor-mode", choices=list(MODES), help="one historical comparison and its dedicated fixture")
    mode_group.add_argument("--verify-production", type=Path, help="verify all production artifacts for the current checkout")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if args.verify_production:
        try:
            paths = sorted(args.verify_production.rglob("summary.json"))
            records = [json.loads(path.read_text(encoding="utf-8")) for path in paths]
            checkout = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
            print("APEX_HYBRID_MATRIX_PASS", json.dumps(verify_production(records, checkout), sort_keys=True))
            return 0
        except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
            print(f"APEX_HYBRID_MATRIX_FAIL: {error}", file=sys.stderr)
            return 1
    if None in (args.track, args.climate, args.seed, args.output):
        parser.error("track, climate, seed and output required")
    is_anchor = (args.track, args.climate, args.seed) == ANCHOR
    if (args.anchor_mode and not is_anchor) or (args.grouped_only and is_anchor):
        parser.error("historical production anchor must use exactly one --anchor-mode")
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
        fixture_modes = []
        fixture_error = None
        grouped_seconds = 0.0
        if args.anchor_mode:
            mode = args.anchor_mode
            try:
                fixture_modes = run_fixtures(env, args.output, (mode,))
            except (OSError, ValueError, subprocess.SubprocessError) as error:
                fixture_error = str(error)
            lines, duration = run_test(dict(env, **{MODES[mode]: "1"}), args.output / f"legacy-{mode}.log")
            candidate = {mode: read_case(lines, expected)}
            baseline_seconds[mode] = duration
            require(fixture_error is None, fixture_error)
            primary_calls = {"legacy": 2, "grouped": 0}
        else:
            if not args.grouped_only:
                for mode, flag in MODES.items():
                    lines, duration = run_test(dict(env, **{flag: "1"}), args.output / f"legacy-{mode}.log")
                    baseline[mode] = read_case(lines, expected)
                    baseline_seconds[mode] = duration
            lines, grouped_seconds = run_test(dict(env, APEX_AERO_GROUPED_PILOT="1"), args.output / "grouped.log")
            candidate = grouped_cases(lines, expected)
            validate_chain(candidate)
            if not args.grouped_only:
                compare(baseline, candidate)
            primary_calls = {"legacy": 0 if args.grouped_only else 10, "grouped": 6}
        summary = {
            "scenario": expected, "status": "PASS", "comparisons": list(candidate),
            "primary_calls": primary_calls,
            "legacy_seconds": baseline_seconds, "grouped_seconds": grouped_seconds,
            "fixture_modes": fixture_modes, "mode_evidence": evidence_for(candidate),
            "scope": ("hybrid production native assertions and shared result integrity"
                      if args.grouped_only or args.anchor_mode else
                      "same job, native isolated processes, all reported sporting fields and assertion trace; not a controlled performance benchmark"),
            "excluded_volatile_fields": sorted(NONSPORTING),
            "checkout": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
            "godot": subprocess.check_output(["godot", "--version"], text=True).strip(),
        }
        (args.output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
        print("APEX_GROUPED_PRODUCTION_PASS" if args.grouped_only or args.anchor_mode else "APEX_GROUPED_PILOT_PASS", json.dumps(summary, ensure_ascii=False))
        return 0
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"APEX_GROUPED_PILOT_FAIL: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
