#!/usr/bin/env python3
"""Non-mutating GDScript Toolkit audit for the APEX first-party source.

Runs gdlint and gdformat --check on tracked scripts/**/*.gd files.
Historical findings are advisory; broken tools or missing reports are errors.
Third-party addons and test fixtures are intentionally excluded.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from typing import Any

DIAGNOSTIC_RE = re.compile(
    r"^([^\r\n:]+\.gd):(\d+):\s*(?:Error|Warning):", re.MULTILINE
)
TOOL_TIMEOUT = 360


class AuditError(Exception):
    """A missing or failed tool, not an ordinary style finding."""


def tracked_scripts(root: Path) -> list[str]:
    command = ["git", "ls-files", "--cached", "--", "scripts"]
    process = subprocess.run(
        command, cwd=root, text=True, capture_output=True, check=False, timeout=30
    )
    if process.returncode:
        raise AuditError("git ls-files failed: " + process.stderr.strip())
    paths = sorted(
        {
            line
            for line in process.stdout.splitlines()
            if line.startswith("scripts/")
            and line.endswith(".gd")
            and (root / line).is_file()
        }
    )
    if not paths:
        raise AuditError("No tracked scripts/**/*.gd files to inspect")
    return paths


def run_tool(name: str, arguments: list[str], root: Path, reports: Path) -> dict[str, Any]:
    try:
        result = subprocess.run(
            [name, *arguments],
            cwd=root,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=TOOL_TIMEOUT,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise AuditError(f"{name} could not run: {exc}") from exc

    log = result.stdout + ("\n" if result.stdout and result.stderr else "") + result.stderr
    (reports / f"{name}.log").write_text(log, encoding="utf-8")
    # Both tools use exit 1 for code/style findings. Unexpected error exits
    # must not be labeled as a successful audit.
    if result.returncode not in (0, 1):
        raise AuditError(f"{name} exited unexpectedly with {result.returncode}; see log")
    return {"exit_code": result.returncode, "log": log}


def lint_findings(log: str) -> Counter[str]:
    return Counter(match.group(1) for match in DIAGNOSTIC_RE.finditer(log))


def summarize(
    files: list[str], lint: dict[str, Any], formatting: dict[str, Any], version: str
) -> dict[str, Any]:
    matches = lint_findings(str(lint["log"]))
    return {
        "status": (
            "CLEAN"
            if lint["exit_code"] == 0 and formatting["exit_code"] == 0
            else "FINDINGS"
        ),
        "mode": "INFORMATIONAL",
        "tool_version": version,
        "scope": "tracked first-party scripts/**/*.gd (no addons or test fixtures)",
        "files_scanned": len(files),
        "gdlint_exit_code": lint["exit_code"],
        "gdlint_diagnostic_lines": sum(matches.values()),
        "gdlint_affected_files_in_parsed_output": len(matches),
        "gdlint_most_reported_files": [
            {"file": file, "diagnostics": count}
            for file, count in matches.most_common(12)
        ],
        "gdformat_check_exit_code": formatting["exit_code"],
        "source_files_modified": False,
        "limitations": [
            "This is advisory and does not block PRs for existing style debt.",
            "Parser limitations may produce false positives for newer Godot syntax.",
            "gdformat --check reports format differences but does not rewrite code.",
            "No gameplay, 3D appearance, performance or determinism is verified here.",
        ],
    }


def to_markdown(info: dict[str, Any]) -> str:
    lines = [
        "### APEX — GDScript Toolkit / análise informativa",
        "",
        f"- Resultado: **{info['status']}** (não bloqueia por dívidas de estilo)",
        f"- Versão: `gdtoolkit {info['tool_version']}`",
        f"- Arquivos próprios examinados: **{info['files_scanned']}**",
        f"- `gdlint`: código {info['gdlint_exit_code']}, "
        f"{info['gdlint_diagnostic_lines']} linhas de diagnóstico reconhecidas",
        f"- `gdformat --check`: código {info['gdformat_check_exit_code']} "
        "(0 = nenhuma alteração sugerida)",
        "- Arquivos modificados automaticamente: **nenhum**",
        "",
        "**Arquivos com mais diagnósticos reconhecidos**",
        "",
        "| Script | Diagnósticos |",
        "|---|---:|",
    ]
    for item in info["gdlint_most_reported_files"]:
        lines.append(f"| `{item['file']}` | {item['diagnostics']} |")
    if not info["gdlint_most_reported_files"]:
        lines.append("| Nenhum diagnóstico no formato reconhecido | 0 |")
    lines += [
        "",
        "Consulte os logs completos e `report.json` nos artefatos da execução.",
        "Os arquivos de terceiros em `addons/` não estão neste escopo.",
        "Problemas históricos são registrados; correções devem ser feitas em PRs próprios",
        "com testes de regressão. O Toolkit não substitui o parser nativo do Godot.",
        "",
    ]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output-dir", type=Path, default=Path("ci_artifacts/gdscript-toolkit")
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    reports = (root / args.output_dir).resolve()
    reports.mkdir(parents=True, exist_ok=True)

    try:
        files = tracked_scripts(root)
        ver = run_tool("gdlint", ["--version"], root, reports)
        if ver["exit_code"] != 0:
            raise AuditError("Cannot retrieve gdlint version")
        version = ver["log"].strip()
        lint = run_tool("gdlint", files, root, reports)
        formatting = run_tool("gdformat", ["--check", *files], root, reports)

        info = summarize(files, lint, formatting, version)
        (reports / "report.json").write_text(
            json.dumps(info, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        (reports / "report.md").write_text(to_markdown(info), encoding="utf-8")
        print(
            "APEX_GDSCRIPT_TOOLKIT_AUDIT",
            json.dumps(
                {
                    "status": info["status"],
                    "files": info["files_scanned"],
                    "gdlint_diagnostic_lines": info["gdlint_diagnostic_lines"],
                    "gdlint_exit_code": info["gdlint_exit_code"],
                    "gdformat_exit_code": info["gdformat_check_exit_code"],
                    "mode": info["mode"],
                }
            ),
        )
        return 0
    except AuditError as exc:
        (reports / "error.txt").write_text(str(exc) + "\n", encoding="utf-8")
        print(f"APEX_GDSCRIPT_TOOLKIT_ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
