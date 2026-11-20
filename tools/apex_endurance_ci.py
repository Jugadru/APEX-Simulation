#!/usr/bin/env python3
"""APEX long-running regression checks for Godot 4.7.2.

Reuses existing GDScript scenarios: a long 24-car Monza replay, two
full-distance Grand Prix (dry Monza, wet Silverstone) at 4 simulated seconds per engine step, and the existing
20-season administrative championship/save/reload stress fixture.

Each scenario runs twice in isolated Godot user directories. Differences in
sporting hashes fail CI; duration and memory-growth trends are advisory.
This does not measure rendered GPU/FPS or simulate 400 full Grand Prix.
"""
from __future__ import annotations

import argparse
import json
import math
import os
from pathlib import Path
import re
import re
import shutil
import subprocess
import sys
from tempfile import TemporaryDirectory
import time
from typing import Any

GROWTH = "tests/high_speed_growth_066723_benchmark.gd"
FULL_GP = "tests/ci/apex_full_gp_endurance.gd"
CAREER = "tests/career_0667_20_season_data_stress.gd"
MEMORY_BUDGET_BYTES = 2 * 1024**3
RSS_FIELD = re.compile(r"^VmRSS:\s*(\d+)\s*kB", re.MULTILINE)


class EnduranceError(RuntimeError):
    pass


def marker_json(log: str, marker: str) -> dict[str, Any]:
    matches = [
        line.split(marker, 1)[1].strip()
        for line in log.splitlines()
        if marker in line
    ]
    if len(matches) != 1:
        raise EnduranceError(f"Expected one {marker.strip()} marker, found {len(matches)}")
    try:
        parsed = json.loads(matches[0])
    except (TypeError, json.JSONDecodeError) as exc:
        raise EnduranceError(f"Invalid JSON after {marker.strip()}") from exc
    if not isinstance(parsed, dict):
        raise EnduranceError(f"{marker.strip()} did not contain a JSON object")
    return parsed


def read_linux_rss_bytes(pid: int) -> int | None:
    try:
        status = Path(f"/proc/{pid}/status").read_text(encoding="ascii")
    except (OSError, UnicodeDecodeError):
        return None
    found = RSS_FIELD.search(status)
    return int(found.group(1)) * 1024 if found else None


def resolve_godot_binary(executable: str) -> str:
    """Resolve the real Godot ELF, never passing arguments to a shell."""
    command = shutil.which(executable)
    if not command:
        raise EnduranceError(f"Godot executable not found: {executable}")
    candidate = Path(command).resolve(strict=True)
    if not candidate.is_file():
        raise EnduranceError("Godot executable path is not a file")
    with candidate.open("rb") as stream:
        if stream.read(4) == b"\x7fELF":
            return str(candidate)
    # The pinned Godot Setup action exposes a known wrapper without a shebang.
    for line in candidate.read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(
            r'xvfb-run --auto-servernum (/[A-Za-z0-9_./+-]+) "\$@"',
            line.strip(),
        )
        if match:
            direct = Path(match.group(1)).resolve(strict=True)
            with direct.open("rb") as stream:
                if stream.read(4) == b"\x7fELF":
                    return str(direct)
    raise EnduranceError("Expected Godot ELF or verified Godot Setup wrapper")


def run_godot(
    root: Path, godot: str, script: str, label: str,
    env_vars: dict[str, str], logs: Path, user_root: Path,
    timeout_seconds: int,
) -> dict[str, Any]:
    logs.mkdir(parents=True, exist_ok=True)
    user_root.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(env_vars)
    env["HOME"] = str(user_root)
    for var, name in (
        ("XDG_DATA_HOME", "data"),
        ("XDG_CONFIG_HOME", "config"),
        ("XDG_CACHE_HOME", "cache"),
    ):
        directory = user_root / name
        directory.mkdir(parents=True, exist_ok=True)
        env[var] = str(directory)

    command = [
        resolve_godot_binary(godot), "--headless", "--path", str(root),
        "--script", "res://" + script,
    ]
    log_file = logs / f"{label}.log"
    started = time.monotonic()
    peak_rss: int | None = None
    with log_file.open("w", encoding="utf-8", errors="replace") as stream:
        try:
            with subprocess.Popen(
                command, env=env, stdout=stream, stderr=subprocess.STDOUT,
                text=True,
            ) as process:
                while process.poll() is None:
                    memory = read_linux_rss_bytes(process.pid)
                    if memory is not None:
                        peak_rss = max(peak_rss or 0, memory)
                    if time.monotonic() - started >= timeout_seconds:
                        process.kill()
                        process.wait()
                        raise EnduranceError(f"{label}: timeout after {timeout_seconds}s")
                    time.sleep(0.07)
                code = process.returncode
        except OSError as exc:
            raise EnduranceError(f"{label}: Godot command could not start: {exc}") from exc
    duration = time.monotonic() - started
    if code != 0:
        raise EnduranceError(f"{label}: Godot exited with {code}; check {log_file.name}")
    if peak_rss is not None and peak_rss > MEMORY_BUDGET_BYTES:
        raise EnduranceError(
            f"{label}: observed process RSS {peak_rss} exceeds 2 GiB budget"
        )
    return {
        "log_file": log_file.name,
        "wall_seconds": round(duration, 4),
        "peak_rss_bytes_observed": peak_rss,
        "rss_scope": "best-effort sampled process RSS on Linux, not GPU/VRAM",
    }


def parse_growth(log: str, expected_ticks: int) -> dict[str, Any]:
    done = marker_json(log, "GROWTH_DONE ")
    if done.get("ticks") != expected_ticks or not isinstance(done.get("hash"), str) or not done["hash"]:
        raise EnduranceError("Growth benchmark incomplete or missing sporting hash")
    rows = done.get("rows")
    if not isinstance(rows, list) or len(rows) != expected_ticks // 250:
        raise EnduranceError("Growth benchmark has incomplete 250-tick samples")
    memory = []
    tick_ms = []
    for position, row in enumerate(rows, 1):
        if not isinstance(row, dict) or row.get("tick") != position * 250:
            raise EnduranceError(f"Growth sample {position}: missing or wrong tick")
        try:
            elapsed_ms = float(row["block_ms"])
            bytes_static = int(row["memory_static_bytes"])
        except (KeyError, TypeError, ValueError) as exc:
            raise EnduranceError(f"Growth sample {position}: invalid metrics") from exc
        if not math.isfinite(elapsed_ms) or elapsed_ms <= 0 or bytes_static < 0:
            raise EnduranceError(f"Growth sample {position}: non-finite metrics")
        memory.append(bytes_static)
        tick_ms.append(elapsed_ms / 250.0)
    first, last = memory[0], memory[-1]
    return {
        "scenario": "monza_growth_2012",
        "ticks": expected_ticks,
        "sporting_hash": done["hash"],
        "samples": len(rows),
        "first_static_bytes": first,
        "last_static_bytes": last,
        "max_static_bytes": max(memory),
        "static_growth_bytes": last - first,
        "mean_ms_per_tick": sum(tick_ms) / len(tick_ms),
        "last_to_first_block_cpu_ratio": tick_ms[-1] / tick_ms[0],
        "telemetry_growth_expected": True,
    }


def parse_full_gp(result: dict[str, Any], track: str, weather: str, seed: int) -> dict:
    if not isinstance(result, dict):
        raise EnduranceError("Full GP output must be an object")
    if (result.get("track") != track or result.get("mode") != weather
            or result.get("seed") != seed or result.get("full_distance") is not True):
        raise EnduranceError(f"Full GP scenario does not match {track}/{weather}/{seed}")
    if result.get("finished") is not True:
        raise EnduranceError(f"Full GP did not reach the checkered flag: {track}/{weather} "
                             f"(steps={result.get('ticks')}, clock={result.get('clock')}, "
                             f"last_lap={result.get('samples', [{}])[-1].get('leader_lap') if result.get('samples') else 'N/A'})")
    if not isinstance(result.get("last_hash"), str) or not result["last_hash"]:
        raise EnduranceError(f"Full GP missing final sporting hash: {track}/{weather}")
    if not isinstance(result.get("ticks"), int) or result["ticks"] <= 100:
        raise EnduranceError(f"Full GP yielded insufficient simulated ticks: {track}")
    if not isinstance(result.get("laps"), (int, float)) or result["laps"] < 20:
        raise EnduranceError(f"Full GP was not full-distance: {track}")
    if not isinstance(result.get("samples"), list):
        raise EnduranceError(f"Full GP progress samples missing: {track}")
    if result.get("finished_cars") != 24 or result.get("manual_pit_orders") != 2:
        raise EnduranceError(f"Full GP missing all classified cars or pit orders: {track}")
    if result.get("step_sim_seconds") != 4.0:
        raise EnduranceError(f"Full GP used unexpected step duration: {track}")
    return {
        "scenario": f"full_gp_{track}_{weather.replace(' ', '_')}",
        "track": track, "weather": weather, "seed": seed,
        "ticks": result["ticks"], "laps": int(result["laps"]),
        "finished": True, "sporting_hash": result["last_hash"],
        "finished_cars": result["finished_cars"],
        "manual_pit_orders": result["manual_pit_orders"],
        "pit_history": result.get("pit_history", 0),
        "checkpoints": result.get("checkpoints"),
        "events": result.get("events"),
        "samples": len(result["samples"]),
    }


def parse_career(log: str) -> dict[str, Any]:
    result = marker_json(log, "CAREER_20_SEASON_STRESS ")
    if (result.get("pass") is not True or result.get("seasons") != 20
            or result.get("races_committed") != 400
            or result.get("errors") != []):
        raise EnduranceError("Administrative career stress did not pass 20x20 results")
    if not isinstance(result.get("checks"), int) or result["checks"] < 400:
        raise EnduranceError("Administrative career did not complete its assertions")
    if not isinstance(result.get("last_save_bytes"), int) or result["last_save_bytes"] < 1000:
        raise EnduranceError("Administrative career produced an invalid save")
    return {
        "scenario": "20_administrative_seasons",
        "seasons": 20,
        "administrative_rounds": 400,
        "checks": result["checks"],
        "last_save_bytes": result["last_save_bytes"],
        "save_reload_tested_by_fixture": True,
        "not_covered": "No 400 simulated GPs or multi-year career UI",
    }


def check_repetitions(name: str, first: dict, second: dict, keys: tuple[str, ...]) -> None:
    for key in keys:
        if first.get(key) != second.get(key):
            raise EnduranceError(
                f"NONDETERMINISTIC {name}: {key} differed: {first.get(key)} vs {second.get(key)}"
            )


def write_report(report: dict[str, Any], output: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)
    (output / "report.json").write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    lines = [
        "### APEX — Testes de longa duracao (Godot 4.7.2)",
        "",
        f"**Status: {report['status']}**",
        "",
        "| Cenario | Repeticoes | Resultado |",
        "|---|---:|---|",
    ]
    for name, runs in report["scenarios"].items():
        lines.append(f"| {name} | {len(runs)} | PASS (hash/estado estavel) |")
    lines.extend([
        "",
        f"- Ticks de Monza por repeticao: {report['growth_ticks']}",
        f"- Corridas completas distintas: {report['full_gp_scenarios']}",
        "- Carreira: 20 temporadas administrativas com 400 registros e reloads (nao 400 GPs simulados).",
        f"- Limite de memoria RSS observavel por processo: {MEMORY_BUDGET_BYTES / 1024**3:.0f} GiB.",
        "- Tendencias de memoria estatica e custo por tick sao informativas; o aumento de",
        "  historico de telemetria/checkpoints e esperado e nao implica vazamento.",
        "- Sem execucao de HUD 3D, GPU, FPS, hardware do jogador ou varios anos fisicamente simulados.",
        "",
    ])
    for note in report["warnings"]:
        lines.append(f"- Aviso: {note}")
    (output / "report.md").write_text("\n".join(lines), encoding="utf-8")


def execute(root: Path, output: Path, godot: str, growth_ticks: int, timeout: int) -> dict:
    if growth_ticks < 1000 or growth_ticks % 250:
        raise EnduranceError("Growth ticks must be a multiple of 250 and >= 1000")
    output.mkdir(parents=True, exist_ok=True)
    scenarios: dict[str, list[dict]] = {}
    warnings = []
    with TemporaryDirectory(prefix="apex-endurance-") as isolated:
        temp = Path(isolated)
        for rep in (1, 2):
            label = f"growth_monza_{rep}"
            print(f"APEX_ENDURANCE_START {label}", flush=True)
            run = run_godot(
                root, godot, GROWTH, label, {"APEX_TICKS": str(growth_ticks)},
                output, temp / label, timeout,
            )
            log = (output / run["log_file"]).read_text(encoding="utf-8", errors="replace")
            record = {**parse_growth(log, growth_ticks), **run}
            scenarios.setdefault("growth_monza", []).append(record)
            print(f"APEX_ENDURANCE_RUN_DONE {label} hash={record['sporting_hash']}", flush=True)
            if record["static_growth_bytes"] > 256 * 1024**2:
                warnings.append(f"{label}: static memory grew >256 MiB; inspect telemetry and replay retention")
            if record["last_to_first_block_cpu_ratio"] > 3.0:
                warnings.append(f"{label}: last 250-tick block >3x the first block; inspect profiler")

        check_repetitions(
            "growth_monza", *scenarios["growth_monza"],
            ("ticks", "sporting_hash", "samples"),
        )

        for circuit, weather, seed in (
            ("ITA", "Seco", 660),
            ("GBR", "Chuva intensa", 661),
        ):
            name = f"full_gp_{circuit}"
            for rep in (1, 2):
                label = f"{name}_{rep}"
                file = output / f"{label}.json"
                env = {
                    "APEX_TRACK": circuit,
                    "APEX_SEED": str(seed),
                    "APEX_WEATHER": weather,
                    "APEX_BENCH_OUTPUT": str(file),
                }
                print(f"APEX_ENDURANCE_START {label}", flush=True)
                run = run_godot(
                    root, godot, FULL_GP, label, env, output, temp / label, timeout
                )
                log = (output / run["log_file"]).read_text(encoding="utf-8", errors="replace")
                marker = marker_json(log, "APEX_FULL_GP_DONE ")
                if not file.is_file():
                    raise EnduranceError(f"{label}: missing exported GP JSON")
                try:
                    gp = json.loads(file.read_text(encoding="utf-8"))
                except (OSError, json.JSONDecodeError) as exc:
                    raise EnduranceError(f"{label}: GP JSON was not readable") from exc
                record = {**parse_full_gp(gp, circuit, weather, seed), **run}
                if (marker.get("hash") != record["sporting_hash"]
                        or marker.get("finished") is not True):
                    raise EnduranceError(f"{label}: stdout/JSON GP result mismatch")
                scenarios.setdefault(name, []).append(record)
                print(f"APEX_ENDURANCE_RUN_DONE {label} hash={record['sporting_hash']}", flush=True)
            check_repetitions(
                name, *scenarios[name],
                ("track", "weather", "seed", "ticks", "laps", "sporting_hash", "finished_cars", "manual_pit_orders", "pit_history"),
            )

        for rep in (1, 2):
            label = f"career_admin_{rep}"
            print(f"APEX_ENDURANCE_START {label}", flush=True)
            run = run_godot(root, godot, CAREER, label, {}, output, temp / label, timeout)
            log = (output / run["log_file"]).read_text(encoding="utf-8", errors="replace")
            record = {**parse_career(log), **run}
            scenarios.setdefault("career_admin", []).append(record)
            print(f"APEX_ENDURANCE_RUN_DONE {label} rounds={record['administrative_rounds']}", flush=True)
        check_repetitions(
            "career_admin", *scenarios["career_admin"],
            ("seasons", "administrative_rounds", "checks", "last_save_bytes"),
        )

    return {
        "status": "PASS",
        "godot": "4.7.2-stable",
        "growth_ticks": growth_ticks,
        "full_gp_scenarios": 2,
        "race_sporting_hashes_consistent": True,
        "career_saves_and_reloads_passed": True,
        "limits": {"process_rss_hard_bytes": MEMORY_BUDGET_BYTES},
        "warnings": warnings,
        "scenarios": scenarios,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path("."))
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--output", type=Path, default=Path("ci_artifacts/endurance"))
    parser.add_argument("--growth-ticks", type=int, default=6000)
    parser.add_argument("--per-run-timeout", type=int, default=450)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    try:
        report = execute(args.project.resolve(), output, args.godot,
                         args.growth_ticks, args.per_run_timeout)
        write_report(report, output)
        print("APEX_ENDURANCE_PASS", json.dumps({
            "growth_ticks": args.growth_ticks,
            "full_gp_scenarios": report["full_gp_scenarios"],
            "career_admin_rounds": 400,
            "warnings": len(report["warnings"]),
        }))
        return 0
    except (OSError, EnduranceError, ValueError) as exc:
        (output / "error.txt").write_text(str(exc) + "\n", encoding="utf-8")
        print(f"APEX_ENDURANCE_FAIL {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
