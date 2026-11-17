#!/usr/bin/env python3
"""APEX CPU/headless A/B comparison using the existing Monza 2012 benchmark.

Measures CPU time inside the GDScript benchmark (not end-user FPS, GPU or 32x).
Runs independent Godot processes in alternating order with isolated user data.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import statistics
import subprocess
import sys

BENCHMARK = Path("tests/high_speed_growth_066723_benchmark.gd")
MARKER = "GROWTH_DONE "


class BenchmarkError(RuntimeError):
    pass


def parse_growth_log(log: str, expected_ticks: int) -> dict:
    """Parse and validate one completed GDScript benchmark invocation."""
    lines = [line.split(MARKER, 1)[1].strip()
             for line in log.splitlines() if MARKER in line]
    if len(lines) != 1:
        raise BenchmarkError(f"Expected one {MARKER.strip()} marker, found {len(lines)}")
    try:
        result = json.loads(lines[0])
    except (ValueError, TypeError) as exc:
        raise BenchmarkError("Invalid GROWTH_DONE JSON") from exc

    if not isinstance(result, dict):
        raise BenchmarkError("GROWTH_DONE is not a JSON object")
    if result.get("ticks") != expected_ticks:
        raise BenchmarkError(f"Expected {expected_ticks} ticks, got {result.get('ticks')}")

    rows = result.get("rows")
    if not isinstance(rows, list) or len(rows) != expected_ticks // 250:
        raise BenchmarkError("Missing or incomplete 250-tick measurements")
    elapsed = 0.0
    memory_samples = []
    for index, row in enumerate(rows, 1):
        if not isinstance(row, dict) or row.get("tick") != index * 250:
            raise BenchmarkError(f"Invalid tick number in sample {index}")
        try:
            block_ms = float(row["block_ms"])
            memory = int(row["memory_static_bytes"])
        except (ValueError, TypeError, KeyError) as exc:
            raise BenchmarkError(f"Invalid time or memory sample {index}") from exc
        if not math.isfinite(block_ms) or block_ms <= 0 or memory < 0:
            raise BenchmarkError(f"Non-finite, zero or negative measurement {index}")
        elapsed += block_ms
        memory_samples.append(memory)

    sporting_hash = result.get("hash")
    if not isinstance(sporting_hash, str) or not sporting_hash:
        raise BenchmarkError("Missing deterministic sporting hash")

    return {
        "ticks": expected_ticks,
        "sporting_hash": sporting_hash,
        "elapsed_cpu_ms": round(elapsed, 6),
        "ms_per_tick": elapsed / expected_ticks,
        "peak_static_monitor_bytes": max(memory_samples),
    }


def summarize(base: list[dict], candidate: list[dict],
              base_script_sha: str, candidate_script_sha: str) -> dict:
    if not base or not candidate:
        raise BenchmarkError("Both revisions require measured repetitions")
    for name, samples in (("base", base), ("candidate", candidate)):
        hashes = {sample["sporting_hash"] for sample in samples}
        if len(hashes) != 1:
            raise BenchmarkError(f"NONDETERMINISTIC: {name} produced different sporting hashes")

    base_ms = statistics.median(sample["ms_per_tick"] for sample in base)
    candidate_ms = statistics.median(sample["ms_per_tick"] for sample in candidate)
    if base_ms <= 0:
        raise BenchmarkError("Baseline CPU measurement is zero")

    same_script = base_script_sha == candidate_script_sha
    same_state = base[0]["sporting_hash"] == candidate[0]["sporting_hash"]
    comparable = same_script and same_state
    delta = ((candidate_ms / base_ms) - 1.0) * 100.0 if comparable else None
    return {
        "status": "COMPARABLE" if comparable else "INCOMPARABLE",
        "benchmark_script_identical": same_script,
        "sporting_hash_identical": same_state,
        "baseline_median_ms_per_tick": base_ms,
        "candidate_median_ms_per_tick": candidate_ms,
        "delta_percent": delta,
        "advisory": (
            "Potential slowdown >= 10%; confirm on dedicated hardware"
            if delta is not None and delta >= 10 else
            "Runner variability: do not use these numbers as gameplay FPS"
        ),
        "base_samples": base,
        "candidate_samples": candidate,
    }


def markdown_report(report: dict) -> str:
    delta = report["delta_percent"]
    difference = f"{delta:+.2f}%" if delta is not None else "N/A (not comparable)"
    lines = [
        "# APEX — Benchmark A/B (CPU/headless)",
        "",
        f"**Status:** {report['status']}",
        "",
        "| Measure | Base | Candidate |",
        "|---|---:|---:|",
        f"| Median CPU ms/tick | {report['baseline_median_ms_per_tick']:.4f} | {report['candidate_median_ms_per_tick']:.4f} |",
        f"| Repetitions | {len(report['base_samples'])} | {len(report['candidate_samples'])} |",
        "",
        f"**Change in CPU ms/tick:** {difference} (positive = slower)",
        "",
        f"- Identical benchmark source: {report['benchmark_script_identical']}",
        f"- Identical sporting hash: {report['sporting_hash_identical']}",
        f"- Advisory: {report['advisory']}",
        "",
        "Only compare percentages when both checks are true. Each reference must",
        "also reproduce its own sporting hash across all repetitions.",
        "The benchmark runs Monza 2012 / 24 cars / seed 660 in headless CPU mode.",
        "It does not measure GPU, rendered FPS, complete GP or effective 16x/32x.",
        "GitHub-hosted runners are noisy; results are advisory, not release gates.",
        "MEMORY_STATIC, if present in JSON, is not process RSS or VRAM.",
        "",
    ]
    return "\n".join(lines)


def run_once(godot: str, project: Path, label: str, index: int,
             ticks: int, out: Path, timeout: int) -> dict:
    isolation = out / "isolated_user" / f"{label}-{index}"
    env = os.environ.copy()
    for key, subdir in (("XDG_DATA_HOME", "data"),
                        ("XDG_CONFIG_HOME", "config"),
                        ("XDG_CACHE_HOME", "cache")):
        directory = isolation / subdir
        directory.mkdir(parents=True, exist_ok=True)
        env[key] = str(directory)
    env["APEX_TICKS"] = str(ticks)
    command = [
        godot, "--headless", "--path", str(project),
        "--script", "res://" + BENCHMARK.as_posix(),
    ]
    try:
        proc = subprocess.run(command, env=env, capture_output=True,
                              text=True, errors="replace", timeout=timeout,
                              check=False)
    except subprocess.TimeoutExpired as exc:
        raise BenchmarkError(f"{label} repetition {index} timed out") from exc

    log = proc.stdout + "\n" + proc.stderr
    (out / f"{label}-{index}.log").write_text(log, encoding="utf-8")
    if proc.returncode != 0:
        raise BenchmarkError(f"{label} repetition {index} exited {proc.returncode}")
    return parse_growth_log(log, ticks)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-dir", type=Path, required=True)
    parser.add_argument("--candidate-dir", type=Path, required=True)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--ticks", type=int, default=1000)
    parser.add_argument("--repetitions", type=int, default=3)
    parser.add_argument("--timeout", type=int, default=180)
    parser.add_argument("--output-dir", type=Path, default=Path("benchmark-ab"))
    args = parser.parse_args()

    if args.ticks < 250 or args.ticks % 250:
        parser.error("--ticks must be a positive multiple of 250")
    if args.repetitions < 2 or args.repetitions > 10:
        parser.error("--repetitions must be between 2 and 10")

    out = args.output_dir.resolve()
    out.mkdir(parents=True, exist_ok=True)
    projects = {"base": args.base_dir.resolve(),
                "candidate": args.candidate_dir.resolve()}
    try:
        source_hashes = {}
        for label, path in projects.items():
            script = path / BENCHMARK
            if not (path / "project.godot").is_file() or not script.is_file():
                raise BenchmarkError(f"Missing APEX project or benchmark: {label}")
            source_hashes[label] = hashlib.sha256(script.read_bytes()).hexdigest()

        samples = {"base": [], "candidate": []}
        # First iteration warms up both cases. Subsequent runs alternate A/B order.
        for index in range(args.repetitions + 1):
            order = ("base", "candidate") if index % 2 == 0 else ("candidate", "base")
            for label in order:
                print(f"APEX_AB {label} {'warmup' if index == 0 else index}", flush=True)
                measured = run_once(args.godot, projects[label], label, index,
                                    args.ticks, out, args.timeout)
                if index:
                    samples[label].append(measured)

        result = summarize(samples["base"], samples["candidate"],
                           source_hashes["base"], source_hashes["candidate"])
        result.update({
            "ticks_per_run": args.ticks,
            "warmup_runs_per_revision": 1,
            "benchmark": BENCHMARK.as_posix(),
            "base_benchmark_sha256": source_hashes["base"],
            "candidate_benchmark_sha256": source_hashes["candidate"],
        })
        (out / "report.json").write_text(
            json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        (out / "report.md").write_text(markdown_report(result), encoding="utf-8")
        print(f"APEX_AB_DONE status={result['status']} delta_percent={result['delta_percent']}")
        return 0  # Different sporting rules are INCOMPARABLE, not a false speedup.
    except (OSError, BenchmarkError) as exc:
        (out / "error.txt").write_text(str(exc) + "\n", encoding="utf-8")
        print(f"APEX_AB_ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
