#!/usr/bin/env python3
"""APEX SaveGuard: cross-revision, real-Godot save/replay compatibility tests.

The BASE version generates real career, garage and replay fixtures with its
existing test scripts. The CANDIDATE version imports those files, exercises
sandbox-only corruption and recovery, and reports unsupported compatibility.
No personal user save is read or copied and no game code is modified.
"""
from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sys
from tempfile import TemporaryDirectory
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


def resolve_godot_binary(executable: str) -> str:
    """Resolve the real Godot ELF, never passing arguments to a shell."""
    command = shutil.which(executable)
    if not command:
        raise SaveGuardError(f"Godot executable not found: {executable}")
    candidate = Path(command).resolve(strict=True)
    if not candidate.is_file():
        raise SaveGuardError("Godot executable path is not a file")
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
    raise SaveGuardError("Expected Godot ELF or verified Godot Setup wrapper")


def run_script(project: Path, godot: str, script: str, label: str,
               output: Path, home: Path, overrides: dict[str, str],
               timeout: int) -> str:
    env = os.environ.copy()
    env.update(overrides)
    home.mkdir(parents=True, exist_ok=True)
    env["HOME"] = str(home)
    for field, folder in (
        ("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"),
        ("XDG_CACHE_HOME", "cache"),
    ):
        directory = home / folder
        directory.mkdir(parents=True, exist_ok=True)
        env[field] = str(directory)
    cmd = [
        resolve_godot_binary(godot), "--headless", "--path", str(project),
        "--script", "res://" + script,
    ]
    async def invoke_verified_godot() -> tuple[int, str, str]:
        # Verified Godot ELF and in-repository scripts from a fixed
        # allowlist, two CI-managed project revisions, no shell.
        process = await asyncio.create_subprocess_exec(  # nosemgrep: python.lang.security.audit.dangerous-asyncio-create-exec-audit, python.lang.security.audit.dangerous-asyncio-create-exec-tainted-env-args
            *cmd, env=env,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        try:
            stdout, stderr = await asyncio.wait_for(
                process.communicate(), timeout=timeout
            )
        except TimeoutError as exc:
            process.kill()
            await process.communicate()
            raise SaveGuardError(f"label: Godot exceeded {timeout} seconds") from exc
        return (
            int(process.returncode),
            stdout.decode("utf-8", errors="replace"),
            stderr.decode("utf-8", errors="replace"),
        )

    try:
        exit_code, stdout, stderr = asyncio.run(invoke_verified_godot())
    except OSError as exc:
        raise SaveGuardError(f"label: Godot did not start: {exc}") from exc
    log = stdout + ("\n" if stdout and stderr else "") + stderr
    (output / f"{label}.log").write_text(log, encoding="utf-8")
    if exit_code != 0:
        raise SaveGuardError(f"{label}: Godot exited {exit_code}; check {label}.log")
    return log


def execute(base: Path, candidate: Path, godot: str, output: Path,
            timeout: int) -> dict[str, Any]:
    output.mkdir(parents=True, exist_ok=True)
    with TemporaryDirectory(prefix="apex-saveguard-") as temp:
        temp_root = Path(temp)
        baseline_home = temp_root / "godot_baseline"
        candidate_home = temp_root / "godot_candidate"

        print("APEX_SAVEGUARD_BASELINE_START career", flush=True)
        career_log = run_script(base, godot, CAREER_SCRIPT, "baseline_career",
                                output, baseline_home, {}, timeout)
        stress = marker_json(career_log, "CAREER_20_SEASON_STRESS ")
        if stress.get("pass") is not True or stress.get("seasons") != 20 or stress.get("races_committed") != 400:
            raise SaveGuardError("Baseline administrative championship fixture failed")
        print("APEX_SAVEGUARD_BASELINE_PASS career", flush=True)

        print("APEX_SAVEGUARD_BASELINE_START garage", flush=True)
        garage_log = run_script(base, godot, GARAGE_SCRIPT, "baseline_garage",
                                output, baseline_home, {}, timeout)
        if "APEX 0642 SAVE MIGRATION PASS" not in garage_log:
            raise SaveGuardError("Baseline garage migration fixture failed")
        print("APEX_SAVEGUARD_BASELINE_PASS garage", flush=True)

        fixtures = {key: find_exact(baseline_home / "data", filename)
                    for key, filename in SOURCES.items()}

        replay_path = temp_root / "baseline_replay.apexreplay"
        print("APEX_SAVEGUARD_BASELINE_START replay", flush=True)
        record_log = run_script(
            base, godot, REPLAY_SCRIPT, "baseline_replay", output,
            baseline_home, {
                "APEX_LEGACY_PATH": str(replay_path),
                "APEX_LEGACY_MODE": "record",
                "APEX_LEGACY_TICKS": str(REPLAY_TICKS),
            }, timeout,
        )
        if "LEGACY_RECORD_PASS" not in record_log or not replay_path.is_file():
            raise SaveGuardError("Baseline replay fixture not recorded")
        fixtures["replay"] = replay_path
        print("APEX_SAVEGUARD_BASELINE_PASS replay", flush=True)

        before = {name: sha256(path) for name, path in fixtures.items()}
        print("APEX_SAVEGUARD_COMPAT_START replay", flush=True)
        replay_log = run_script(
            candidate, godot, REPLAY_SCRIPT, "candidate_replay", output,
            candidate_home, {
                "APEX_LEGACY_PATH": str(replay_path),
                "APEX_LEGACY_MODE": "replay",
                "APEX_LEGACY_TICKS": str(REPLAY_TICKS),
            }, timeout,
        )
        if "LEGACY_REPLAY_PASS" not in replay_log:
            raise SaveGuardError("Candidate did not validate baseline replay")
        print("APEX_SAVEGUARD_COMPAT_PASS replay", flush=True)

        print("APEX_SAVEGUARD_SANDBOX_START", flush=True)
        guard_log = run_script(
            candidate, godot, SAVEGUARD_SCRIPT, "candidate_saveguard",
            output, candidate_home, {
                "APEX_SAVEGUARD_CAREER": str(fixtures["career"]),
                "APEX_SAVEGUARD_GARAGE": str(fixtures["garage"]),
                "APEX_SAVEGUARD_REPLAY": str(fixtures["replay"]),
                "APEX_SAVEGUARD_TICKS": str(REPLAY_TICKS),
            }, timeout,
        )
        report = validate_result(marker_json(guard_log, "APEX_SAVEGUARD_RESULT "))
        after = {name: sha256(path) for name, path in fixtures.items()}
        if before != after:
            raise SaveGuardError("One or more baseline fixtures were modified")
        if before != report["observations"]["source_sha256"]:
            raise SaveGuardError("Godot and Python baseline SHA256 evidence differs")
        report["baseline_files_unchanged"] = True
        report["baseline_source_sha256"] = before
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
    ap.add_argument("--godot", default="godot")
    ap.add_argument("--output", type=Path, default=Path("ci_artifacts/saveguard"))
    ap.add_argument("--timeout", type=int, default=150)
    args = ap.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    try:
        report = execute(args.baseline.resolve(), args.candidate.resolve(),
                         args.godot, output, args.timeout)
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
