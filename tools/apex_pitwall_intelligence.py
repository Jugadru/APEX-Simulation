#!/usr/bin/env python3
"""APEX Pit Wall Intelligence Analyzer 1.0 — explain evidence, never coach production AI.

Four 10-lap, 24-car races are run twice in isolated Godot 4.7.2 processes.
Only broken evidence/determinism/sporting invariants are FAIL. Tactical flags
are REVIEW (not verified bugs), manual choices are contextual observations.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import json
import math
from pathlib import Path
import re
import sys
from typing import Any

MARKER = "APEX_PITWALL_ANALYZER_RESULT "
SCENARIOS: dict[str, tuple[str, str, int, str]] = {
    "ita_dry_auto": ("ITA", "Seco", 13660, "IA"),
    "gbr_wet_auto": ("GBR", "Chuva intensa", 13661, "IA"),
    "bra_variable_auto": ("BRA", "Variável", 13662, "IA"),
    "ita_manual_v7": ("ITA", "Seco", 13663, "Manual"),
}
COMPULSORY = ("scenario", "track", "weather", "control", "seed",
              "lap_count", "finished", "classified", "steps", "race_hash",
              "manual_v7_laps", "player_ids", "decisions", "pits", "radio",
              "event_counts", "errors", "status")
SLICK = frozenset(("Supermacio", "Macio", "Médio", "Duro"))
MAX_LOG_BYTES = 5 * 1024 * 1024


class PitWallAnalyzerError(ValueError):
    pass


def load_nominations(project: Path) -> dict[str, set[str]]:
    try:
        source = json.loads((project / "data" / "tyres_2012.json").read_text(encoding="utf-8"))
        season = json.loads((project / "data" / "season_2012.json").read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise PitWallAnalyzerError("Missing/invalid real 2012 tyre and season data") from exc
    circuits = [t.get("code") for t in season.get("tracks", [])]
    if len(circuits) != 20 or len(set(circuits)) != 20 or len(season.get("teams", [])) != 12:
        raise PitWallAnalyzerError("Real 2012 20-circuit/12-team contract broken")
    result = {}
    for code in circuits:
        dry = source.get("tracks", {}).get(code, {}).get("dry", [])
        if not isinstance(dry, list) or len(dry) != 2:
            raise PitWallAnalyzerError(f"{code}: invalid two-compound nomination")
        result[code] = set(dry) | {"Intermediário", "Chuva"}
    return result


def parse_log(path: Path) -> dict[str, Any]:
    if not path.is_file() or path.stat().st_size > MAX_LOG_BYTES:
        raise PitWallAnalyzerError(f"{path.name}: missing/oversized real Godot log")
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    found = [line.split(MARKER, 1)[1].strip() for line in lines if MARKER in line]
    if len(found) != 1:
        raise PitWallAnalyzerError(f"{path.name}: expected exactly one Godot result marker")
    try:
        result = json.loads(found[0])
    except ValueError as exc:
        raise PitWallAnalyzerError(f"{path.name}: invalid JSON result") from exc
    if not isinstance(result, dict):
        raise PitWallAnalyzerError(f"{path.name}: result must be JSON object")
    return result


def number(value: Any, lower: float, upper: float) -> bool:
    return type(value) in (float, int) and math.isfinite(value) and lower <= value <= upper


def validate_result(data: dict[str, Any], name: str,
                    nominations: dict[str, set[str]]) -> dict[str, Any]:
    if name not in SCENARIOS or any(key not in data for key in COMPULSORY):
        raise PitWallAnalyzerError(f"{name}: missing required scenario fields")
    track, weather, seed, control = SCENARIOS[name]
    if (data["scenario"], data["track"], data["weather"], data["seed"], data["control"]) != (
            name, track, weather, seed, control):
        raise PitWallAnalyzerError(f"{name}: run identity does not match fixture")
    if data["status"] != "PASS" or data["errors"] != []:
        raise PitWallAnalyzerError(f"{name}: real fixture failed: {data['errors']}")
    if (data["finished"] is not True or data["classified"] != 24
            or data["lap_count"] != 10 or type(data["steps"]) is not int
            or not 10 <= data["steps"] <= 1200):
        raise PitWallAnalyzerError(f"{name}: invalid 24-car 10-lap finish")
    if not isinstance(data["race_hash"], str) or re.fullmatch(r"[a-f0-9]{64}", data["race_hash"]) is None:
        raise PitWallAnalyzerError(f"{name}: sporting hash missing")
    ids = data["player_ids"]
    if (not isinstance(ids, list) or len(ids) != 2 or
            any(type(v) is not int or v < 0 for v in ids) or len(set(ids)) != 2):
        raise PitWallAnalyzerError(f"{name}: invalid player identities")
    manual = data["manual_v7_laps"]
    if manual != ([7] if control == "Manual" else []):
        raise PitWallAnalyzerError(f"{name}: manual V7 violated")
    decisions = data["decisions"]
    if not isinstance(decisions, list) or not 5 <= len(decisions) <= 120:
        raise PitWallAnalyzerError(f"{name}: no bounded decision samples")
    for item in decisions:
        if not isinstance(item, dict):
            raise PitWallAnalyzerError(f"{name}: malformed decision record")
        for key in ("step", "lap", "car_id", "position", "stops", "pit_scheduled_lap", "ai_plan_lap"):
            if type(item.get(key)) is not int:
                raise PitWallAnalyzerError(f"{name}: invalid decision integer {key}")
        if not 0 <= item["lap"] <= 10 or not 0 <= item["step"] <= data["steps"]:
            raise PitWallAnalyzerError(f"{name}: impossible lap/step observation")
        if not number(item.get("clock"), 0, 50_000) or not number(item.get("wetness"), 0, 1):
            raise PitWallAnalyzerError(f"{name}: invalid decision time/wetness")
        if not number(item.get("wear"), 0, 100.01) or not number(item.get("pit_left"), 0, 10000):
            raise PitWallAnalyzerError(f"{name}: invalid tyre wear/pit time")
        if item.get("tire") not in nominations[track]:
            raise PitWallAnalyzerError(f"{name}: non-nominated tyre in decision trace")
        if item.get("control") not in ("Manual", "IA"):
            raise PitWallAnalyzerError(f"{name}: invalid pit authority")
        if type(item.get("ai_has_plan")) is not bool or type(item.get("ai_pit_now")) is not bool:
            raise PitWallAnalyzerError(f"{name}: invalid AI plan flags")
        if type(item.get("pit_request")) is not bool:
            raise PitWallAnalyzerError(f"{name}: invalid pit request flag")
        if item["car_id"] in ids and item["control"] != control:
            raise PitWallAnalyzerError(f"{name}: player control mismatch")
        if not item["ai_has_plan"] and item["ai_pit_now"]:
            raise PitWallAnalyzerError(f"{name}: AI plan cannot be urgent if absent")

    pits = data["pits"]
    if not isinstance(pits, list) or len(pits) > 240:
        raise PitWallAnalyzerError(f"{name}: impossible pit count")
    stops_per_car: Counter[int] = Counter()
    for item in pits:
        if not isinstance(item, dict):
            raise PitWallAnalyzerError(f"{name}: invalid pit row")
        if type(item.get("car_id")) is not int or type(item.get("lap")) is not int or not 1 <= item["lap"] <= 10:
            raise PitWallAnalyzerError(f"{name}: pit on impossible lap")
        if item.get("new_tire") not in nominations[track] or item.get("old_tire") not in nominations[track]:
            raise PitWallAnalyzerError(f"{name}: 2012 pit tyre nomination violation")
        if not number(item.get("wait"), 0, 5000) or not number(item.get("incident_delay"), 0, 5000):
            raise PitWallAnalyzerError(f"{name}: invalid pit waiting/incident metrics")
        if not isinstance(item.get("order_origin"), str):
            raise PitWallAnalyzerError(f"{name}: invalid source of pit decision")
        stops_per_car[item["car_id"]] += 1
    if any(count > 10 for count in stops_per_car.values()):
        raise PitWallAnalyzerError(f"{name}: more stops than racing laps")
    if not isinstance(data["radio"], list) or len(data["radio"]) > 2000:
        raise PitWallAnalyzerError(f"{name}: invalid radio event list")
    allowed_events = ("driver_radio", "engineer_reply", "radio",
                      "strategy", "team_coordination", "double_stack")
    for item in data["radio"]:
        if not isinstance(item, dict) or item.get("type") not in allowed_events:
            raise PitWallAnalyzerError(f"{name}: invalid radio provenance")
        if type(item.get("car_id")) is not int or not number(item.get("time"), 0, 50_000):
            raise PitWallAnalyzerError(f"{name}: invalid event location/time")
        if not isinstance(item.get("message"), str) or len(item["message"]) > 3000:
            raise PitWallAnalyzerError(f"{name}: invalid radio message")
    if not isinstance(data["event_counts"], dict) or any(
        not isinstance(k, str) or type(v) is not int or v < 0
        for k, v in data["event_counts"].items()
    ):
        raise PitWallAnalyzerError(f"{name}: invalid event counts")
    if any(
        sum(1 for ev in data["radio"] if ev["type"] == event) !=
        data["event_counts"].get(event, 0)
        for event in allowed_events
    ):
        raise PitWallAnalyzerError(f"{name}: radio event summary mismatch")
    return data


def same_run(first: dict[str, Any], second: dict[str, Any]) -> None:
    for field in COMPULSORY:
        if first[field] != second[field]:
            raise PitWallAnalyzerError(
                f"NONDETERMINISTIC {first['scenario']}: {field} differs"
            )


def analyze_case(result: dict[str, Any]) -> dict[str, Any]:
    """All labels are hypotheses requiring review; no subjective AI score."""
    by_driver: dict[int, list[dict[str, Any]]] = defaultdict(list)
    for obs in result["decisions"]:
        by_driver[obs["car_id"]].append(obs)
    stop_count = Counter(p["car_id"] for p in result["pits"])
    findings: list[dict[str, Any]] = []

    def finding(code: str, level: str, row: dict[str, Any], reason: str,
                evidence: dict[str, Any]) -> None:
        findings.append({
            "code": code, "level": level,
            "scenario": result["scenario"], "track": result["track"],
            "weather": result["weather"], "seed": result["seed"],
            "car_id": row["car_id"], "driver": row.get("driver", ""),
            "lap": row.get("lap"), "reason": reason, "evidence": evidence,
        })

    for driver_id, rows in by_driver.items():
        rows.sort(key=lambda x: x["step"])
        # One observation at the start can predate meaningful AI planning.
        # Require two DIFFERENT racing laps before reviewing sustained mismatch.
        for code, test, reason in (
            ("WET_TRACK_SLICK", lambda x: x["wetness"] >= 0.45 and x["tire"] in SLICK,
             "Pneus de seco observados em pista muito molhada por mais de uma volta"),
            ("DRY_TRACK_FULL_WET", lambda x: x["wetness"] <= 0.12 and x["tire"] == "Chuva",
             "Pneus de chuva extrema persistem após a pista ficar seca"),
        ):
            streak: list[dict[str, Any]] = []
            for row in rows:
                if row["lap"] <= 0 or row["lap"] >= result["lap_count"]:
                    continue
                if test(row) and not row["pit_request"] and row["pit_left"] <= 0:
                    if not streak or row["lap"] > streak[-1]["lap"]:
                        streak.append(row)
                    if len(streak) >= 2:
                        level = "OBSERVATION" if row["control"] == "Manual" else "REVIEW"
                        finding(code, level, row, reason, {
                            "wetness": row["wetness"], "tyre": row["tire"],
                            "laps_observed": [x["lap"] for x in streak[-2:]],
                            "pit_control": row["control"],
                            "plan_reason": row.get("ai_plan_reason", ""),
                            "manual_booking": row.get("pit_scheduled_lap", 0),
                        })
                        break
                else:
                    streak.clear()

        if stop_count[driver_id] >= 3:
            finding("PIT_FREQUENCY", "REVIEW", rows[-1],
                    "Três ou mais paradas em 10 voltas: avaliar clima, desgaste e incidentes",
                    {"stops": stop_count[driver_id], "race_laps": result["lap_count"]})

    for stop in result["pits"]:
        if stop["wait"] >= 3.0:
            finding("PIT_QUEUE", "REVIEW", {
                "car_id": stop["car_id"], "driver": stop["driver"], "lap": stop["lap"]},
                "Tempo relevante de espera no box; verificar tráfego de garagem/double stack",
                {"wait_s": stop["wait"], "incident_s": stop["incident_delay"],
                 "origin": stop["order_origin"]})
    for event in result["radio"]:
        if event["type"] == "team_coordination":
            # Presence of coordination proves communication, not an error.
            continue

    categories = Counter(f["level"] for f in findings)
    return {
        "scenario": result["scenario"], "track": result["track"],
        "weather": result["weather"], "control": result["control"],
        "seed": result["seed"], "laps": result["lap_count"],
        "sporting_hash": result["race_hash"], "steps": result["steps"],
        "pits": len(result["pits"]), "radio": len(result["radio"]),
        "decision_samples": len(result["decisions"]),
        "review_flags": categories["REVIEW"],
        "manual_contexts": categories["OBSERVATION"],
        "findings": findings,
        "evidence": {
            "observations": result["decisions"], "pit_history": result["pits"],
            "radio_events": result["radio"], "event_counts": result["event_counts"],
        },
    }


def run(project: Path, output: Path) -> dict[str, Any]:
    if not (project / "project.godot").is_file():
        raise PitWallAnalyzerError("Missing Godot project")
    tyres = load_nominations(project)
    cases = []
    for name in SCENARIOS:
        first, second = (
            validate_result(parse_log(output / f"{name}_{rep}.log"), name, tyres)
            for rep in (1, 2)
        )
        same_run(first, second)
        row = analyze_case(first)
        cases.append(row)
        print(
            f"APEX_PITWALL_CASE_PASS {name} hash={row['sporting_hash']} "
            f"review={row['review_flags']}", flush=True
        )
    return {
        "status": "PASS_WITH_REVIEW" if any(c["review_flags"] for c in cases) else "PASS",
        "cases": len(cases), "runs": len(cases) * 2,
        "tracks": sorted({c["track"] for c in cases}),
        "scope": "10 laps; read-only observations from real Core 2. "
                 "Does NOT add bad decisions or measure staff talent, strategy "
                 "optimality, causal lost time, full GP, radio voice or graphics.",
        "review_flags": sum(c["review_flags"] for c in cases),
        "manual_contexts": sum(c["manual_contexts"] for c in cases),
        "scenarios": cases,
    }


def markdown(report: dict[str, Any]) -> str:
    lines = ["### APEX Pit Wall Intelligence Analyzer 1.0", "",
             f"**Status de integridade: {report['status']}**",
             f"Cenários: {report['cases']} · Execuções reais: {report['runs']}",
             f"Hipóteses a investigar: **{report['review_flags']}** · "
             f"Contextos manuais: **{report['manual_contexts']}**", "",
             "| Cenário | Pista/clima | Pits | Amostras | Rádio | Revisões |",
             "|---|---|---:|---:|---:|---:|"]
    for case in report["scenarios"]:
        lines.append(f"| {case['scenario']} | {case['track']} / {case['weather']} | "
                     f"{case['pits']} | {case['decision_samples']} | "
                     f"{case['radio']} | {case['review_flags']} |")
    lines.extend(["", "#### Sinais com evidências"])
    displayed = 0
    for case in report["scenarios"]:
        for f in case["findings"]:
            displayed += 1
            if displayed <= 40:
                lines.append(f"- **{f['level']} / {f['code']}** — {f['track']} "
                             f"V{f['lap']}: {f['reason']}. "
                             f"Piloto {f['driver']} (#{f['car_id']}). "
                             f"Contexto {json.dumps(f['evidence'], ensure_ascii=False)}")
    if displayed > 40:
        lines.append(f"- Mais {displayed - 40} sinais nos JSON de evidências.")
    lines.extend(["", "**Limites:** sinais não provam decisões ruins, erros humanos "
                  "nem causalidade; incidentes, ordens manuais e previsão incerta "
                  "podem explicar uma estratégia. Nenhuma IA foi modificada."])
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path("."))
    parser.add_argument("--output", type=Path, default=Path("ci_artifacts/pitwall_intelligence"))
    args = parser.parse_args()
    output = args.output.resolve()
    try:
        report = run(args.project.resolve(), output)
        output.mkdir(parents=True, exist_ok=True)
        (output / "report.json").write_text(
            json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        (output / "report.md").write_text(markdown(report), encoding="utf-8")
        # Log bounded original review findings for actionable CI diagnostics.
        # The evidence is observational, not proof of a defective strategy.
        for case in report["scenarios"]:
            for finding in case["findings"][:25]:
                print("APEX_PITWALL_REVIEW", json.dumps(
                    finding, ensure_ascii=False
                ), flush=True)
        print("APEX_PITWALL_ANALYZER_PASS", json.dumps({
            "scenarios": report["cases"], "runs": report["runs"],
            "review_flags": report["review_flags"],
            "manual_contexts": report["manual_contexts"],
        }), flush=True)
        return 0
    except (OSError, PitWallAnalyzerError, TypeError, KeyError) as exc:
        output.mkdir(parents=True, exist_ok=True)
        (output / "error.txt").write_text(str(exc) + "\n", encoding="utf-8")
        print(f"APEX_PITWALL_ANALYZER_FAIL {exc}", file=sys.stderr, flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
