#!/usr/bin/env python3
"""APEX Race Intelligence Tester v1: real Godot races and targeted rules.

Scenarios are run twice in fresh user profiles; only comparable fixed seeds
must produce identical sporting hashes, pit outcomes and event counts.
Counts such as overtakes, radio and AI pit decisions remain observational.
No edits to game scripts, saves, physics or player configuration.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
from typing import Any

PROBE = "tests/ci/apex_race_intelligence_probe.gd"
SCENARIOS = ("monza_dry_auto", "silverstone_wet_auto", "monza_manual_v7")
SMOKE_TESTS = (
    ("tyres", "tests/core_0552_tyre_ai_smoke_test.gd", "APEX v0.5.5.2 PASS"),
    ("ai_director", "tests/core_0570_ai_director_smoke_test.gd", "APEX 0.5.7.0 PASS"),
    ("lap_strategy", "tests/lap_strategy_06496_auto_gate_test.gd", "AUTO_GATE_06496_PASS"),
    ("same_tick_pit", "tests/pitwall_0667_same_tick_regression.gd", "PITWALL_SAME_TICK_RESULT"),
)
INVARIANT_FIELDS = (
    "scenario", "circuit", "seed", "weather", "control", "lap_count",
    "finished", "classified", "steps", "hash", "pits_total",
    "manual_v7_pits", "on_track_pass_events", "radio_events",
    "ai_plan_samples", "max_stops_per_car",
)


class IntelligenceError(ValueError):
    pass


def parse_marker(log: str, prefix: str) -> dict[str, Any]:
    lines = [line.split(prefix, 1)[1].strip()
             for line in log.splitlines() if prefix in line]
    if len(lines) != 1:
        raise IntelligenceError(f"Expected one {prefix} marker, got {len(lines)}")
    try:
        obj = json.loads(lines[0])
    except (TypeError, json.JSONDecodeError) as exc:
        raise IntelligenceError(f"Invalid JSON for {prefix}") from exc
    if not isinstance(obj, dict):
        raise IntelligenceError(f"{prefix} is not a JSON object")
    return obj


def validate_probe(result: dict[str, Any], expected: str) -> dict[str, Any]:
    if result.get("scenario") != expected or result.get("status") != "PASS":
        raise IntelligenceError(f"{expected}: wrong scenario or failed probe")
    if result.get("lap_count") != 10 or result.get("classified") != 24:
        raise IntelligenceError(f"{expected}: incorrect grid or distance")
    if result.get("finished") is not True or result.get("errors") != []:
        raise IntelligenceError(f"{expected}: incomplete race or errors")
    if not isinstance(result.get("hash"), str) or len(result["hash"]) != 64:
        raise IntelligenceError(f"{expected}: sporting SHA256 missing")
    if not isinstance(result.get("steps"), int) or result["steps"] < 10:
        raise IntelligenceError(f"{expected}: invalid step count")
    if not isinstance(result.get("pits_total"), int) or result["pits_total"] < 0:
        raise IntelligenceError(f"{expected}: invalid pit history count")
    if expected == "monza_manual_v7" and result.get("manual_v7_pits") != [7]:
        raise IntelligenceError("Explicit manual V7 order was not respected")
    if expected == "silverstone_wet_auto" and float(result.get("wetness_peak", 0.0)) <= 0.15:
        raise IntelligenceError("Wet scenario never had wet track")
    for field in ("on_track_pass_events", "radio_events", "ai_plan_samples"):
        value = result.get(field)
        if not isinstance(value, int) or value < 0:
            raise IntelligenceError(f"{expected}: invalid {field}")
    return result


def check_repeated(first: dict[str, Any], second: dict[str, Any]) -> None:
    for field in INVARIANT_FIELDS:
        if first.get(field) != second.get(field):
            raise IntelligenceError(
                f"NONDETERMINISTIC {first.get('scenario')}: {field} differs: "
                f"{first.get(field)!r} != {second.get(field)!r}"
            )


def read_ci_log(output: Path, label: str) -> str:
    """Read CI-generated Godot log; no process execution from report parser."""
    if not re.fullmatch(r"[a-z][a-z0-9_]*", label):
        raise IntelligenceError("Invalid CI run label")
    path = output / (label + ".log")
    if not path.is_file():
        raise IntelligenceError(f"Missing CI-generated Godot log: {path.name}")
    if path.stat().st_size > 16 * 1024 * 1024:
        raise IntelligenceError(f"Oversized Godot log: {path.name}")
    return path.read_text(encoding="utf-8", errors="replace")


def execute(root: Path, output: Path) -> dict[str, Any]:
    if not (root / "project.godot").is_file():
        raise IntelligenceError("APEX project.godot missing")
    observations: dict[str, Any] = {"status": "PASS", "scenarios": {}, "targeted": {}}
    for name, script, marker in SMOKE_TESTS:
        print(f"APEX_RIT_TARGETED_CHECK {name}", flush=True)
        log = read_ci_log(output, "targeted_" + name)
        if marker not in log:
            raise IntelligenceError(f"{name}: missing existing test PASS marker")
        if name == "same_tick_pit":
            evidence = parse_marker(log, marker)
            if evidence.get("pass") is not True or evidence.get("errors") != []:
                raise IntelligenceError(f"{name}: scheduled-pit test failed")
        observations["targeted"][name] = "PASS"
        print(f"APEX_RIT_TARGETED_PASS {name}", flush=True)
    for scenario in SCENARIOS:
        values = []
        for rep in (1, 2):
            label = f"{scenario}_{rep}"
            log = read_ci_log(output, label)
            evidence = validate_probe(parse_marker(log, "APEX_RIT_RESULT "), scenario)
            values.append(evidence)
            print(f"APEX_RIT_SCENARIO_PASS {label} hash={evidence['hash']}", flush=True)
        check_repeated(values[0], values[1])
        observations["scenarios"][scenario] = {
            "runs": 2, "hash": values[0]["hash"],
            "pits_total": values[0]["pits_total"],
            "on_track_pass_events": values[0]["on_track_pass_events"],
            "radio_events": values[0]["radio_events"],
            "ai_plan_samples": values[0]["ai_plan_samples"],
            "manual_v7_pits": values[0]["manual_v7_pits"],
            "wetness_peak": values[0]["wetness_peak"],
            "steps": values[0]["steps"],
        }
    observations["limitations"] = [
        "10-lap headless simulation; not a full race season or proof of strategic quality.",
        "Overtaking, radio and pit frequency are measured, not automatically scored as realism.",
        "No 3D animation, voice audio, GPU/FPS or player interviews evaluated.",
    ]
    return observations


def markdown(report: dict[str, Any]) -> str:
    rows = [
        "### APEX Race Intelligence Tester — Godot 4.7.2",
        "",
        f"**Resultado: {report['status']}**",
        "",
        "| Cenário | 2 execuções | Pits | Ultrapassagens observadas | Rádios |",
        "|---|---|---:|---:|---:|",
    ]
    for name, value in report["scenarios"].items():
        rows.append(
            f"| {name} | PASS, hashes iguais | {value['pits_total']} | "
            f"{value['on_track_pass_events']} | {value['radio_events']} |"
        )
    rows += [
        "",
        "Testes de regras existentes: " + ", ".join(report["targeted"]),
        "",
        "A ordem manual V7 é verificada sem antecipação; IA, chuva e integridade",
        "esportiva são verificadas em cenários de 10 voltas.",
        "Rádios, ultrapassagens e frequência de pits são indicadores observacionais,",
        "**não** provas de realismo ou de inteligência superior.",
        "",
    ]
    return "\n".join(rows)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--project", type=Path, default=Path("."))
    ap.add_argument("--output", type=Path, default=Path("ci_artifacts/race_intelligence"))
    args = ap.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    try:
        result = execute(args.project.resolve(), output)
        (output / "report.json").write_text(
            json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        (output / "report.md").write_text(markdown(result), encoding="utf-8")
        print("APEX_RIT_CI_PASS", json.dumps({
            "scenarios": len(result["scenarios"]), "repetitions": 2,
            "targeted": len(result["targeted"]),
        }), flush=True)
        return 0
    except (OSError, IntelligenceError, ValueError) as exc:
        (output / "error.txt").write_text(str(exc) + "\n", encoding="utf-8")
        print(f"APEX_RIT_CI_FAIL {exc}", file=sys.stderr, flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
