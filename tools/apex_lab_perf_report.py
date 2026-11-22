#!/usr/bin/env python3
"""Fail-closed validation of an actual Godot APEX Test Lab CPU profile."""
from __future__ import annotations
import argparse
import json
import math
from pathlib import Path
import re

MARKER = "APEX_LAB_PERF_RESULT "
PASS_MARKER = "APEX_LAB_PERF_PASS "
HASH = re.compile(r"^[a-f0-9]{64}$")
WEATHERS = ("Seco", "Chuva intensa")
TICKS = 500

class LabPerfError(ValueError):
    pass

def read_log(content: str) -> dict:
    if len(content.encode("utf-8")) > 2_000_000:
        raise LabPerfError("Oversized log")
    if any(line.startswith(("ERROR:", "SCRIPT ERROR:", "Parse Error:", "APEX_LAB_PERF_FAIL"))
           for line in content.splitlines()):
        raise LabPerfError("Godot reported an error or failed assertion")
    payloads = [line.split(MARKER, 1)[1].strip() for line in content.splitlines()
                if line.startswith(MARKER)]
    passes = [line for line in content.splitlines() if line.startswith(PASS_MARKER)]
    if len(payloads) != 1 or len(passes) != 1:
        raise LabPerfError("Missing or duplicated actual Godot success markers")
    try:
        report = json.loads(payloads[0])
    except json.JSONDecodeError as exc:
        raise LabPerfError("Malformed benchmark JSON") from exc
    if not isinstance(report, dict) or report.get("schema") != 1 or report.get("status") != "PASS":
        raise LabPerfError("Unexpected benchmark schema or status")
    if report.get("track") != "LAB" or report.get("ticks") != TICKS:
        raise LabPerfError("Wrong synthetic circuit or tick budget")
    rows = report.get("runs")
    if not isinstance(rows, list) or len(rows) != 4:
        raise LabPerfError("Expected two weather profiles and two repetitions each")
    by_weather = {name: {} for name in WEATHERS}
    for run in rows:
        if not isinstance(run, dict):
            raise LabPerfError("Malformed scenario")
        weather, rep = run.get("weather"), run.get("repetition")
        if weather not in WEATHERS or type(rep) is not int or rep not in (1, 2):
            raise LabPerfError("Wrong weather or repetition")
        if rep in by_weather[weather]:
            raise LabPerfError("Duplicate scenario")
        if (run.get("seed") != 991420 or run.get("cars") != 24
                or run.get("ticks") != TICKS or run.get("finished") is not False):
            raise LabPerfError("Wrong fixed benchmark workload")
        if not isinstance(run.get("sporting_hash"), str) or not HASH.fullmatch(run["sporting_hash"]):
            raise LabPerfError("Missing sporting SHA-256")
        for key in ("mean_us", "p95_us", "max_us", "early_mean_us",
                    "late_mean_us", "wall_seconds", "simulated_seconds_per_wall_second"):
            value = run.get(key)
            if type(value) not in (float, int) or not math.isfinite(value) or value <= 0:
                raise LabPerfError(f"Invalid measured {key}")
        peak = run.get("peak_static_bytes")
        if type(peak) is not int or peak < 0:
            raise LabPerfError("Invalid observed static memory")
        if run["mean_us"] > run["max_us"] or run["p95_us"] > run["max_us"]:
            raise LabPerfError("Impossible CPU percentile")
        ratio = run["simulated_seconds_per_wall_second"]
        if not math.isclose(ratio * run["wall_seconds"], float(TICKS), rel_tol=0.01):
            raise LabPerfError("Inconsistent simulation speed")
        by_weather[weather][rep] = run
    observations = []
    for weather in WEATHERS:
        if set(by_weather[weather]) != {1, 2}:
            raise LabPerfError("Missing expected repetition")
        a, b = by_weather[weather][1], by_weather[weather][2]
        if a["sporting_hash"] != b["sporting_hash"]:
            raise LabPerfError(f"NONDETERMINISTIC sporting hash in {weather}")
        for row in (a, b):
            observations.append({
                "weather": weather, "repeat": row["repetition"],
                "mean_us": row["mean_us"], "p95_us": row["p95_us"],
                "peak_static_bytes": row["peak_static_bytes"],
                "end_over_start_ratio": row["late_mean_us"] / row["early_mean_us"],
                "simulated_seconds_per_wall_second": row["simulated_seconds_per_wall_second"],
            })
    return {"status": "PASS", "track": "LAB", "ticks_per_run": TICKS,
            "total_ticks": TICKS * 4, "cases": 4, "observations": observations,
            "weather_hashes": {name: by_weather[name][1]["sporting_hash"] for name in WEATHERS},
            "limitations": "headless CPU/engine memory only; no physical GPU FPS, no fixed CPU threshold"}

def write_report(report: dict, output: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)
    (output / "report.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    rows = ["### APEX Test Lab — perfil CPU headless", "",
            f"**{report['status']}** · {report['total_ticks']} ticks · 24 carros · 2 climas · 2 repetições",
            "", "| Clima | Rep. | Média (μs/tick) | p95 (μs) | Pico memória estática (MiB) | Evolução fim/início |",
            "|---|---:|---:|---:|---:|---:|"]
    for row in report["observations"]:
        rows.append(f"| {row['weather']} | {row['repeat']} | {row['mean_us']:.1f} | {row['p95_us']:.1f} | {row['peak_static_bytes']/1048576:.2f} | {row['end_over_start_ratio']:.2f}x |")
    rows.extend(["", "Medições observacionais: não são FPS de GPU nem prova de ausência de regressão entre commits.",
                 "Comparações A/B entre versões continuam em workflow separado.",
                 "A pista sintética não substitui os circuitos reais na homologação esportiva.", ""])
    (output / "report.md").write_text("\n".join(rows), encoding="utf-8")

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--log", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        report = read_log(args.log.read_text(encoding="utf-8"))
        write_report(report, args.output)
        print("APEX_LAB_PERF_REPORT_PASS scenarios=4 ticks=2000")
        return 0
    except (OSError, LabPerfError) as exc:
        print("APEX_LAB_PERF_REPORT_FAIL " + str(exc))
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
