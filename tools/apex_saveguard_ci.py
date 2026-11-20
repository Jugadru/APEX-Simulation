#!/usr/bin/env python3
"""APEX SaveGuard: cross-revision, real-Godot save/replay compatibility tests.

The BASE version generates real career, garage and replay fixtures with its
existing test scripts. The CANDIDATE version imports those files, exercises
sandbox-only corruption and recovery, and reports unsupported compatibility.
No personal user save is read or copied and no game code is modified.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
from typing import Any

CAREER_SCRIPT = "tests/career_0667_20_season_data_stress.gd"
GARAGE_SCRIPT = "tests/core_0642_save_migration_test.gd"
REPLAY_SCRIPT = "tests/replay_0663_legacy_fixture.gd"
SAVEGUARD_SCRIPT = "tests/ci/apex_saveguard_cross_revision.gd"
REPLAY_TICKS = 350
SOURCES = {
    "career": "apex_0667_20_season_stress.json",
    "garage": "apex_garage_050.json",
}


class SaveGuardError(ValueError):
    pass


def sha256(file: Path) -> str:
    h = hashlib.sha256()
    with file.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def marker_json(log: str, marker: str) -> dict[str, Any]:
    rows = [line.split(marker, 1)[1].strip()
            for line in log.splitlines() if marker in line]
    if len(rows) != 1:
        raise SaveGuardError(f"Expected exactly one {marker.strip()} marker; got {len(rows)}")
    try:
        parsed = json.loads(rows[0])
    except (TypeError, json.JSONDecodeError) as exc:
        raise SaveGuardError(f"{marker.strip()}: invalid JSON") from exc
    if not isinstance(parsed, dict):
        raise SaveGuardError(f"{marker.strip()}: expected JSON object")
    return parsed


def validate_result(report: dict[str, Any]) -> dict[str, Any]:
    if report.get("status") != "PASS" or report.get("test") != "apex_saveguard_cross_revision":
        raise SaveGuardError("SaveGuard did not finish with PASS status")
    if report.get("errors") != [] or not isinstance(report.get("checks"), int) or report["checks"] < 30:
        raise SaveGuardError("SaveGuard missing required checks or encountered errors")
    observations = report.get("observations")
    if not isinstance(observations, dict):
        raise SaveGuardError("SaveGuard observations missing")
    if not all(k in observations for k in ("career", "garage", "replay", "source_sha256")):
        raise SaveGuardError("SaveGuard missing career, garage, replay or SHA256 evidence")
    if observations["career"].get("final_round") != 20:
        raise SaveGuardError("Career progress not verified")
    if observations["garage"].get("historic_budget") != 6500000:
        raise SaveGuardError("Garage budget not verified")
    if observations["replay"].get("ticks") != REPLAY_TICKS:
        raise SaveGuardError("Replay did not verify target ticks")
    for name in ("career", "garage", "replay"):
        if not isinstance(observations["source_sha256"].get(name), str):
            raise SaveGuardError(f"Missing SHA256 for {name}")
    return report


def find_exact(home_data: Path, name: str) -> Path:
    matches = sorted(home_data.rglob(name))
    if len(matches) != 1:
        raise SaveGuardError(
            f"Expected one {name} in isolated Godot data; found {len(matches)}"
        )
    if not matches[0].is_file() or matches[0].stat().st_size < 100:
        raise SaveGuardError(f"Generated baseline file missing or too small: {name}")
    return matches[0]


def read_ci_log(output: Path, label: str) -> str:
    """Read a fixed-name CI result; no processes launched by the parser."""
    if not re.fullmatch(r"[a-z][a-z0-9_]*", label):
        raise SaveGuardError("Invalid CI log label")
    path = output / (label + ".log")
    if not path.is_file() or path.stat().st_size > 20 * 1024 * 1024:
        raise SaveGuardError("Missing or oversized CI log: " + path.name)
    return path.read_text(encoding="utf-8", errors="replace")


def read_snapshot_hash(output: Path, name: str) -> str:
    if name not in ("career", "garage", "replay"):
        raise SaveGuardError("Invalid fixture snapshot identity")
    path = output / (name + ".sha")
    if not path.is_file():
        raise SaveGuardError("Missing baseline snapshot: " + path.name)
    value = path.read_text(encoding="utf-8").strip()
    if not re.fullmatch(r"[0-9a-f]{64}", value):
        raise SaveGuardError("Invalid baseline SHA256 snapshot: " + name)
    return value


def execute(base: Path, candidate: Path, output: Path,
            baseline_home: Path, replay_path: Path) -> dict[str, Any]:
    for root in (base, candidate):
        if not (root / "project.godot").is_file():
            raise SaveGuardError("One of the selected APEX project revisions is missing")
    career_log = read_ci_log(output, "baseline_career")
    stress = marker_json(career_log, "CAREER_20_SEASON_STRESS ")
    if stress.get("pass") is not True or stress.get("seasons") != 20 or stress.get("races_committed") != 400:
        raise SaveGuardError("Baseline administrative championship fixture failed")
    print("APEX_SAVEGUARD_BASELINE_PASS career", flush=True)

    garage_log = read_ci_log(output, "baseline_garage")
    if "APEX 0642 SAVE MIGRATION PASS" not in garage_log:
        raise SaveGuardError("Baseline garage migration fixture failed")
    print("APEX_SAVEGUARD_BASELINE_PASS garage", flush=True)

    fixtures = {
        key: find_exact(baseline_home / "data", filename)
        for key, filename in SOURCES.items()
    }
    record_log = read_ci_log(output, "baseline_replay")
    if "LEGACY_RECORD_PASS" not in record_log or not replay_path.is_file():
        raise SaveGuardError("Baseline replay fixture not recorded")
    fixtures["replay"] = replay_path
    print("APEX_SAVEGUARD_BASELINE_PASS replay", flush=True)

    expected = {name: read_snapshot_hash(output, name) for name in fixtures}
    print("APEX_SAVEGUARD_COMPAT_START replay", flush=True)
    replay_log = read_ci_log(output, "candidate_replay")
    if "LEGACY_REPLAY_PASS" not in replay_log:
        raise SaveGuardError("Candidate did not validate baseline replay")
    print("APEX_SAVEGUARD_COMPAT_PASS replay", flush=True)

    print("APEX_SAVEGUARD_SANDBOX_CHECK", flush=True)
    guard_log = read_ci_log(output, "candidate_saveguard")
    report = validate_result(marker_json(guard_log, "APEX_SAVEGUARD_RESULT "))
    after = {name: sha256(path) for name, path in fixtures.items()}
    if expected != after:
        raise SaveGuardError("Baseline fixtures differ from pre-candidate SHA256 snapshots")
    if expected != report["observations"]["source_sha256"]:
        raise SaveGuardError("Godot and Python baseline SHA256 evidence differs")
    report["baseline_files_unchanged"] = True
    report["baseline_source_sha256"] = expected
    report["replay_cross_version_verified"] = True
    report["baseline_administrative_records"] = 400
    return report


def markdown(report: dict[str, Any]) -> str:
    checks = report["checks"]
    return "\n".join([
        "### APEX SaveGuard — Compatibilidade de saves e replays",
        "",
        f"**Status: {report['status']}** — {checks} verificações no Godot.",
        "",
        "| Teste | Resultado |",
        "|---|---|",
        "| Campeonato de 20 temporadas administrativas | Base → candidato PASS |",
        "| Garagem (orçamento, upgrades, staff, inventário) | Base → candidato PASS |",
        "| Replay binário de 350 ticks, checksum e hash esportivo | PASS |",
        "| JSON malformado, schema incompatível, round_index inválido | Rejeitados |",
        "| Replay alterado e revisão física divergente | Rejeitados |",
        "| Recuperação dos saves | Apenas por cópias manuais na sandbox |",
        "| Arquivos originais da versão base | SHA256 inalterados |",
        "",
        "**Limitações:** o SaveGuard não instala recuperação automática no jogo.",
        "A garagem atual faz backup `.bak`, mas não o restaura sozinha.",
        "A compatibilidade verificada é entre os commits escolhidos; o replay",
        "é recusado corretamente quando a revisão física não coincide.",
        "Os 400 resultados representam dados administrativos, não 400 GPs simulados.",
        "",
    ])


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--baseline", type=Path, required=True)
    ap.add_argument("--candidate", type=Path, required=True)
    ap.add_argument("--baseline-home", type=Path, required=True)
    ap.add_argument("--replay-path", type=Path, required=True)
    ap.add_argument("--output", type=Path, default=Path("ci_artifacts/saveguard"))
    args = ap.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    try:
        report = execute(
            args.baseline.resolve(), args.candidate.resolve(), output,
            args.baseline_home.resolve(), args.replay_path.resolve()
        )
        (output / "report.json").write_text(
            json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
        )
        (output / "report.md").write_text(markdown(report), encoding="utf-8")
        print("APEX_SAVEGUARD_PASS", json.dumps({
            "checks": report["checks"], "baseline_unchanged": True,
            "cross_revision_replay": True, "administrative_records": 400,
        }), flush=True)
        return 0
    except (SaveGuardError, OSError, TypeError, ValueError) as exc:
        (output / "error.txt").write_text(str(exc) + "\n", encoding="utf-8")
        print(f"APEX_SAVEGUARD_FAIL {exc}", file=sys.stderr, flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
