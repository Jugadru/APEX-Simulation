#!/usr/bin/env python3
"""Race Quality 9.9: independently validate 12 real full-distance Godot GPs.

Two circuits (Monza/Silverstone), three climates, two deterministic
repetitions each. Reads original logs/JSON only; never synthesizes PASS
or modifies sporting results.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import re
import sys

from apex_endurance_ci import marker_json, parse_full_gp

CIRCUITS = ("GBR", "ITA")
WEATHERS = ("Seco", "Variável", "Chuva intensa")
REPEATS = (1, 2)
SHA256 = re.compile(r"[0-9a-f]{64}\Z")


class GPQualityError(ValueError):
    pass


def scenarios() -> list[tuple[str, str, str, int]]:
    return [
        (f"{circuit}_{i}", circuit, weather, 99700 + CIRCUITS.index(circuit) * 10 + i)
        for circuit in CIRCUITS
        for i, weather in enumerate(WEATHERS)
    ]


def load_track_laps(project: Path) -> dict[str, int]:
    try:
        season = json.loads(
            (project / "data/season_2012.json").read_text(encoding="utf-8")
        )
    except (OSError, ValueError) as exc:
        raise GPQualityError("Missing/invalid season_2012.json") from exc
    tracks = season.get("tracks", [])
    laps = {str(t.get("code")): t.get("laps") for t in tracks}
    if len(tracks) != 20 or any(
        type(laps.get(code)) is not int or laps[code] < 40
        for code in CIRCUITS
    ):
        raise GPQualityError("2012 Monza/Silverstone full lap counts not available")
    return laps


def checked_run(out: Path, scenario: str, circuit: str, weather: str,
                seed: int, repeat: int, laps: int) -> dict:
    label = f"{scenario}_{repeat}"
    log = out / f"{label}.log"
    datafile = out / f"{label}.json"
    if not log.is_file() or not datafile.is_file():
        raise GPQualityError(f"{label}: missing native Godot log or JSON")
    if log.stat().st_size > 10 * 1024 * 1024 or datafile.stat().st_size > 4 * 1024 * 1024:
        raise GPQualityError(f"{label}: oversized evidence")
    try:
        source = json.loads(datafile.read_text(encoding="utf-8"))
        marker = marker_json(log.read_text(encoding="utf-8", errors="replace"),
                             "APEX_FULL_GP_DONE ")
        report = parse_full_gp(source, circuit, weather, seed)
    except (OSError, ValueError, KeyError, TypeError, RuntimeError) as exc:
        raise GPQualityError(f"{label}: invalid complete GP evidence: {exc}") from exc
    if source.get("laps") != laps:
        raise GPQualityError(f"{label}: full distance wrong ({source.get('laps')} != {laps})")
    if not isinstance(source.get("ticks"), int) or source["ticks"] > 5000:
        raise GPQualityError(f"{label}: unrealistic step count")
    if not SHA256.fullmatch(report["sporting_hash"]):
        raise GPQualityError(f"{label}: invalid hash format")
    for field in ("min_wetness", "max_wetness"):
        val = source.get(field)
        if type(val) not in (int, float) or not math.isfinite(val) or not 0 <= val <= 1:
            raise GPQualityError(f"{label}: missing/invalid {field} observation")
    if source["min_wetness"] > source["max_wetness"]:
        raise GPQualityError(f"{label}: inverted wetness extrema")
    if (marker.get("track"), marker.get("weather"), marker.get("seed"),
        marker.get("ticks"), marker.get("hash")) != (
            circuit, weather, seed, source["ticks"], source["last_hash"]
        ):
        raise GPQualityError(f"{label}: Godot stdout and JSON disagree")
    if marker.get("finished") is not True or marker.get("finished_cars") != 24:
        raise GPQualityError(f"{label}: missing finish in native log")
    if weather == "Chuva intensa" and source["max_wetness"] < .15:
        raise GPQualityError(f"{label}: heavy rain never wetted the track")
    return {
        **report,
        "min_wetness": source["min_wetness"],
        "max_wetness": source["max_wetness"],
        "weather_change_observed": (
            source["max_wetness"] - source["min_wetness"] >= .05
        ),
    }


def validate(project: Path, output: Path) -> dict:
    laps = load_track_laps(project)
    rows = []
    warnings = []
    for ident, circuit, weather, seed in scenarios():
        a, b = (
            checked_run(output, ident, circuit, weather, seed, repeat, laps[circuit])
            for repeat in REPEATS
        )
        for key in ("ticks", "sporting_hash", "pit_history",
                    "manual_pit_orders", "min_wetness", "max_wetness"):
            if a[key] != b[key]:
                raise GPQualityError(f"NONDETERMINISTIC {ident}: {key}")
        if weather == "Variável" and not a["weather_change_observed"]:
            warnings.append(f"{ident}: variable fixture did not observe >=0.05 wetness change")
        rows.append(a)
        print(f"APEX_QUALITY_FULL_GP_PASS {ident} laps={a['laps']} "
              f"hash={a['sporting_hash']} wet_range={a['min_wetness']:.3f}:"
              f"{a['max_wetness']:.3f}", flush=True)
    return {
        "status": "PASS" if not warnings else "INCONCLUSIVE",
        "cases": len(rows), "runs": len(rows) * 2,
        "full_distance": True, "warnings": warnings, "scenarios": rows,
        "scope": "2 circuits x 3 climates x 2 repeats; 4-second engine steps, "
                 "not native rendered FPS or the 0.2-second replay fixture.",
    }


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--project", type=Path, default=Path("."))
    p.add_argument("--output", type=Path, default=Path("ci_artifacts/race_quality_full_gp"))
    args = p.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    try:
        report = validate(args.project, args.output)
        (args.output / "report.json").write_text(
            json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
        )
        summary = [
            "# Race Quality 9.9 — Silverstone e Monza em distancia oficial",
            "", f"**{report['status']}**: {report['cases']} cenarios / {report['runs']} execucoes.",
            "", "| Pista | Clima | Voltas | Hash | Agua min–max |",
            "|---|---|---:|---|---|",
        ]
        for r in report["scenarios"]:
            summary.append(
                f"| {r['track']} | {r['weather']} | {r['laps']} | "
                f"`{r['sporting_hash'][:12]}` | "
                f"{r['min_wetness']:.3f}–{r['max_wetness']:.3f} |"
            )
        summary += ["", "Limites: passo de simulação 4 s; não valida FPS 3D ou velocidade efetiva de 32×."]
        summary += ["- " + x for x in report["warnings"]]
        (args.output / "report.md").write_text("\n".join(summary) + "\n", encoding="utf-8")
        print("APEX_QUALITY_FULL_GP_" + report["status"], json.dumps({
            "cases": report["cases"], "runs": report["runs"],
            "warnings": report["warnings"],
        }), flush=True)
        return 0 if report["status"] == "PASS" else 1
    except (GPQualityError, OSError, ValueError, TypeError) as exc:
        (args.output / "error.txt").write_text(str(exc) + "\n", encoding="utf-8")
        print("APEX_QUALITY_FULL_GP_FAIL " + str(exc), file=sys.stderr, flush=True)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
