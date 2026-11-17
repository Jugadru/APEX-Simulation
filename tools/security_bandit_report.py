#!/usr/bin/env python3
"""APEX: summarize an existing Bandit JSON scan without changing source files.

Security findings are advisory in this first integration. A missing,
malformed or incomplete scan is a CI failure, never an "all clear".
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import sys


class ReportError(ValueError):
    pass


def summarize(data: object) -> dict:
    if not isinstance(data, dict):
        raise ReportError("Bandit JSON root must be an object")
    if not isinstance(data.get("results"), list):
        raise ReportError("Bandit JSON is missing a results list")
    if not isinstance(data.get("errors"), list):
        raise ReportError("Bandit JSON is missing an errors list")
    if data["errors"]:
        raise ReportError("Bandit reported files that it could not analyze: "
                          + str(len(data["errors"])))
    if not isinstance(data.get("metrics"), dict):
        raise ReportError("Bandit JSON is missing scan metrics")

    results = data["results"]
    severity = Counter({"HIGH": 0, "MEDIUM": 0, "LOW": 0, "UNDEFINED": 0})
    confidence = Counter()
    rules = Counter()
    for index, finding in enumerate(results):
        if not isinstance(finding, dict):
            raise ReportError(f"Invalid Bandit finding at index {index}")
        level = str(finding.get("issue_severity", "UNDEFINED")).upper()
        severity[level] += 1
        confidence[str(finding.get("issue_confidence", "UNDEFINED")).upper()] += 1
        rules[str(finding.get("test_id", "UNKNOWN"))] += 1

    return {
        "status": "CLEAN" if not results else "FINDINGS",
        "mode": "INFORMATIONAL",
        "analyzer": "Bandit (Python only; not CodeQL)",
        "finding_count": len(results),
        "by_severity": dict(severity),
        "by_confidence": dict(confidence),
        "top_rules": [
            {"rule": rule, "count": count}
            for rule, count in rules.most_common(10)
        ],
        "metrics": data["metrics"].get("_totals", {}),
        "limitations": [
            "Bandit does not analyze GDScript or run Godot.",
            "Findings are possible vulnerabilities, not verified exploits.",
            "Clean status does not guarantee an absence of vulnerabilities.",
            "CodeQL requires separate GitHub Code Security eligibility on private repos.",
        ],
    }


def markdown(report: dict) -> str:
    levels = report["by_severity"]
    lines = [
        "### APEX — Segurança estática de Python (Bandit)",
        "",
        f"- Resultado: **{report['status']}**, modo informativo.",
        f"- Achados: **{report['finding_count']}** "
        f"(alta: {levels.get('HIGH', 0)}, média: {levels.get('MEDIUM', 0)}, "
        f"baixa: {levels.get('LOW', 0)}).",
        "- Escopo: ferramentas Python em tools/ e .github/scripts/ (exclui tools/tests/).",
        "- O relatório não modifica arquivos, nem cobre GDScript.",
        "",
        "| Regra Bandit | Ocorrências |",
        "|---|---:|",
    ]
    for item in report["top_rules"]:
        lines.append(f"| `{item['rule']}` | {item['count']} |")
    if not report["top_rules"]:
        lines.append("| Nenhum achado | 0 |")
    lines += [
        "",
        "Os arquivos bandit.json e report.json ficam nos artefatos.",
        "CodeQL é uma etapa separada e só é habilitado mediante disponibilidade",
        "do GitHub Code Security no repositório privado.",
        "",
    ]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bandit_json", type=Path)
    parser.add_argument("--output-dir", type=Path,
                        default=Path("ci_artifacts/security"))
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    try:
        raw = json.loads(args.bandit_json.read_text(encoding="utf-8"))
        report = summarize(raw)
        (args.output_dir / "report.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        (args.output_dir / "report.md").write_text(
            markdown(report), encoding="utf-8"
        )
        print("APEX_BANDIT_AUDIT", json.dumps({
            "status": report["status"],
            "findings": report["finding_count"],
            "high": report["by_severity"].get("HIGH", 0),
            "medium": report["by_severity"].get("MEDIUM", 0),
            "low": report["by_severity"].get("LOW", 0),
        }))
        return 0
    except (OSError, ValueError, TypeError) as exc:
        (args.output_dir / "error.txt").write_text(
            str(exc) + "\n", encoding="utf-8"
        )
        print(f"APEX_BANDIT_AUDIT_ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
