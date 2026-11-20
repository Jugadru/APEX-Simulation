#!/usr/bin/env python3
"""APEX Scenario Matrix 1.0: deterministic 2012 circuit/strategy test matrix.

'plan' generates immutable scenario identities from season_2012.json.
'validate' only reads real Godot logs; it NEVER manufactures PASS results.
A smoke run rotates weather and strategy across all 20 tracks; a manually
requested full run covers 20 x 3 x 3 = 180 cases. Every case runs twice.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
from typing import Any

TRACKS = (
    "AUS", "MAL", "CHN", "BHR", "ESP", "MON", "CAN", "EUR", "GBR", "GER",
    "HUN", "BEL", "ITA", "SIN", "JPN", "KOR", "IND", "UAE", "USA", "BRA",
)
WEATHERS = ("Seco", "Variável", "Chuva intensa")
MODES = ("Manual", "Assistido", "IA")
REPEATS = 2
MARKER = "APEX_MATRIX_RESULT "
MAX_LOG_BYTES = 4 * 1024 * 1024
INVARIANT_FIELDS = (
    "id", "track", "weather", "mode", "seed", "laps", "steps",
    "finished", "finish_results_validated", "finished_cars",
    "classified_positions", "race_hash", "pits_total", "max_stops",
    "pit_laps_by_player", "disqualified", "wetness_peak",
    "on_track_pass_events",
)


class MatrixError(ValueError):
    """A missing, corrupt, contradictory or nondeterministic result."""


def _season(project: Path) -> dict[str, Any]:
    file = project / "data" / "season_2012.json"
    try:
        obj = json.loads(file.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise MatrixError("Cannot load real season_2012.json") from exc
    if not isinstance(obj, dict) or not isinstance(obj.get("tracks"), list):
        raise MatrixError("Invalid 2012 season structure")
    codes = [x.get("code") for x in obj["tracks"] if isinstance(x, dict)]
    if tuple(codes) != TRACKS or len(codes) != 20:
        raise MatrixError("2012 season must contain precisely the original 20 ordered circuits")
    if not isinstance(obj.get("teams"), list) or len(obj["teams"]) != 12:
        raise MatrixError("Expected 12 teams in 2012 data")
    return obj


def _seed(seed_base: int, code: str, weather: str, mode: str) -> int:
    # Independent but reproducible values; no unrecorded random draw.
    data = f"APEX-MATRIX-1|{seed_base}|{code}|{weather}|{mode}".encode("utf-8")
    return int(hashlib.sha256(data).hexdigest()[:14], 16) % 2_000_000_000 + 1


def plan(project: Path, profile: str, shard: int, shards: int,
         seed_base: int) -> list[dict[str, Any]]:
    _season(project)
    if profile not in ("smoke", "full") or shards < 1 or shards > 20:
        raise MatrixError("Invalid profile/shard count")
    if not 0 <= shard < shards or not 1 <= seed_base <= 2_000_000_000:
        raise MatrixError("Invalid shard or seed base")
    result: list[dict[str, Any]] = []
    for index, code in enumerate(TRACKS):
        if index % shards != shard:
            continue
        combos = (
            [(WEATHERS[index % 3], MODES[(index // 3) % 3])]
            if profile == "smoke"
            else [(weather, mode) for weather in WEATHERS for mode in MODES]
        )
        for weather, mode in combos:
            seed = _seed(seed_base, code, weather, mode)
            case_id = f"{code.lower()}_{WEATHERS.index(weather)}_{MODES.index(mode)}_{seed}"
            result.append({
                "id": case_id, "track": code, "weather": weather,
                "mode": mode, "seed": seed, "laps": 10,
            })
    if not result or len({c["id"] for c in result}) != len(result):
        raise MatrixError("Empty or duplicate scenario plan")
    return result


def _parse_marker(path: Path) -> dict[str, Any]:
    if not path.is_file() or path.stat().st_size > MAX_LOG_BYTES:
        raise MatrixError(f"Missing/oversized real Godot log: {path.name}")
    text = path.read_text(encoding="utf-8", errors="replace")
    matches = [line.split(MARKER, 1)[1].strip()
               for line in text.splitlines() if MARKER in line]
    if len(matches) != 1:
        raise MatrixError(f"{path.name}: expected one APEX_MATRIX_RESULT, got {len(matches)}")
    try:
        obj = json.loads(matches[0])
    except ValueError as exc:
        raise MatrixError(f"{path.name}: invalid marker JSON") from exc
    if not isinstance(obj, dict):
        raise MatrixError(f"{path.name}: marker must contain an object")
    return obj


def _validated(obj: dict[str, Any], scenario: dict[str, Any]) -> dict[str, Any]:
    name = scenario["id"]
    for key in ("id", "track", "weather", "mode", "seed", "laps"):
        if obj.get(key) != scenario[key]:
            raise MatrixError(f"{name}: wrong identity field {key}")
    if obj.get("status") != "PASS" or obj.get("errors") != []:
        raise MatrixError(f"{name}: Godot probe failed: {obj.get('errors')}")
    if obj.get("finished") is not True or obj.get("finish_results_validated") is not True:
        raise MatrixError(f"{name}: ten-lap race did not finish/validate")
    if obj.get("finished_cars") != 24 or obj.get("classified_positions") != list(range(1, 25)):
        raise MatrixError(f"{name}: incoherent 24-car classification")
    if type(obj.get("steps")) is not int or not 10 <= obj["steps"] <= 1500:
        raise MatrixError(f"{name}: invalid step count")
    h = obj.get("race_hash")
    if not isinstance(h, str) or re.fullmatch(r"[a-f0-9]{64}", h) is None:
        raise MatrixError(f"{name}: sporting SHA256 missing or invalid")
    for key in ("pits_total", "max_stops", "disqualified", "on_track_pass_events"):
        val = obj.get(key)
        if type(val) is not int or val < 0:
            raise MatrixError(f"{name}: invalid {key}")
    if obj["max_stops"] > 10 or obj["pits_total"] > 240 or obj["disqualified"] > 24:
        raise MatrixError(f"{name}: impossible stop/disqualification count")
    lap_lists = obj.get("pit_laps_by_player")
    if (not isinstance(lap_lists, list) or len(lap_lists) != 2
            or any(not isinstance(laps, list) for laps in lap_lists)
            or any(type(lap) is not int or not 1 <= lap <= 10
                   for laps in lap_lists for lap in laps)):
        raise MatrixError(f"{name}: invalid player pit history")
    wet = obj.get("wetness_peak")
    if not isinstance(wet, (int, float)) or not 0.0 <= wet <= 1.0:
        raise MatrixError(f"{name}: invalid wetness")
    if obj.get("mode") in ("Manual", "Assistido") and lap_lists != [[6], [7]]:
        raise MatrixError(f"{name}: protected scheduled manual V6/V7 not respected")
    if obj.get("weather") == "Chuva intensa" and wet < 0.15:
        raise MatrixError(f"{name}: heavy-rain fixture never became wet")
    if not isinstance(obj.get("warnings"), list) or any(
        not isinstance(w, str) for w in obj["warnings"]
    ):
        raise MatrixError(f"{name}: malformed warning list")
    return obj


def validate(project: Path, output: Path, profile: str, shard: int,
             shards: int, seed_base: int) -> dict[str, Any]:
    cases = plan(project, profile, shard, shards, seed_base)
    rows: list[dict[str, Any]] = []
    for scenario in cases:
        values = [
            _validated(_parse_marker(output / f"{scenario['id']}_{i}.log"), scenario)
            for i in range(1, REPEATS + 1)
        ]
        for key in INVARIANT_FIELDS:
            if values[0].get(key) != values[1].get(key):
                raise MatrixError(f"NONDETERMINISTIC {scenario['id']}: {key}")
        if values[0]["warnings"] != values[1]["warnings"]:
            raise MatrixError(f"NONDETERMINISTIC {scenario['id']}: warnings")
        rows.append(values[0])
        print(f"APEX_MATRIX_CASE_PASS {scenario['id']} hash={values[0]['race_hash']}", flush=True)

    covered_tracks = sorted({x["track"] for x in rows})
    expected_tracks = sorted(c for i, c in enumerate(TRACKS) if i % shards == shard)
    if covered_tracks != expected_tracks:
        raise MatrixError("Shard missed required circuits")
    warnings = [
        {"scenario": x["id"], "message": message}
        for x in rows for message in x["warnings"]
    ]
    return {
        "status": "PASS" if not warnings else "WARN",
        "profile": profile, "shard": shard, "shards": shards,
        "seed_base": seed_base, "repetitions": REPEATS,
        "cases": len(rows), "runs": len(rows) * REPEATS,
        "tracks": covered_tracks, "weathers": sorted({x["weather"] for x in rows}),
        "strategy_modes": sorted({x["mode"] for x in rows}),
        "warnings": warnings,
        "results": rows,
        "scope": "10-lap headless RaceEngine; full profile covers 20x3x3. "
                 "Assisted mode delegates pace/KERS through TeamAutonomy with "
                 "manual pit authority; no real HUD/staff career integration. "
                 "High pit counts are warnings, not automatic evidence of a bug.",
    }


def _markdown(data: dict[str, Any]) -> str:
    lines = [
        "### APEX Scenario Matrix 1.0 — Godot 4.7.2",
        f"Status: **{data['status']}** · Perfil: {data['profile']} · "
        f"Shard {data['shard'] + 1}/{data['shards']}",
        f"Casos: {data['cases']} · Execuções reais: {data['runs']} "
        f"· Circuitos: {len(data['tracks'])}",
        "",
        "| Pista | Clima | Estratégia | Semente | Hash | Pits | Avisos |",
        "|---|---|---|---:|---|---:|---:|",
    ]
    for item in data["results"]:
        lines.append(
            f"| {item['track']} | {item['weather']} | {item['mode']} | "
            f"{item['seed']} | `{item['race_hash'][:12]}` | "
            f"{item['pits_total']} | {len(item['warnings'])} |"
        )
    lines.extend([
        "", f"Avisos informativos: **{len(data['warnings'])}**.",
    ])
    if data["warnings"]:
        lines.extend(["", "#### Anomalias para revisar (WARN, não FAIL)"])
        for warning in data["warnings"]:
            # Keep the GitHub Actions Markdown summary readable even for bad data.
            name = str(warning["scenario"]).replace("|", "/").replace(chr(10), " ")
            reason = str(warning["message"]).replace("|", "/").replace(chr(10), " ")
            lines.append(f"- **{name}**: {reason}")
    lines.extend([
        "Não há medição de GPU/FPS, corrida de distância oficial ou "
        "validação visual. Este laboratório procura inconsistências "
        "e não comprova realismo de estratégia.",
    ])
    return "\n".join(lines) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("command", choices=("plan", "validate"))
    ap.add_argument("--project", type=Path, default=Path("."))
    ap.add_argument("--output", type=Path, default=Path("ci_artifacts/scenario_matrix"))
    ap.add_argument("--profile", choices=("smoke", "full"), default="smoke")
    ap.add_argument("--shard", type=int, default=0)
    ap.add_argument("--shards", type=int, default=4)
    ap.add_argument("--seed-base", type=int, default=12012)
    ap.add_argument("--format", choices=("tsv", "json"), default="tsv")
    args = ap.parse_args()
    try:
        if args.command == "plan":
            cases = plan(args.project, args.profile, args.shard,
                         args.shards, args.seed_base)
            if args.format == "json":
                print(json.dumps(cases, ensure_ascii=False))
            else:
                for c in cases:
                    print("\t".join(str(c[key]) for key in (
                        "id", "track", "weather", "mode", "seed")))
            return 0
        args.output.mkdir(parents=True, exist_ok=True)
        report = validate(args.project, args.output, args.profile,
                          args.shard, args.shards, args.seed_base)
        (args.output / "report.json").write_text(
            json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        (args.output / "report.md").write_text(_markdown(report), encoding="utf-8")
        print("APEX_MATRIX_SHARD_PASS", json.dumps({
            "profile": report["profile"], "shard": report["shard"],
            "cases": report["cases"], "runs": report["runs"],
            "warnings": len(report["warnings"]),
        }), flush=True)
        return 0
    except (OSError, MatrixError, ValueError) as exc:
        args.output.mkdir(parents=True, exist_ok=True)
        (args.output / "error.txt").write_text(str(exc) + "\n", encoding="utf-8")
        print(f"APEX_MATRIX_FAIL {exc}", file=sys.stderr, flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
