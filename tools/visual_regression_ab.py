#!/usr/bin/env python3
"""APEX visual A/B regression gate using REAL Godot 4.7.2 screenshots.

Compares a base revision and candidate revision rendered on the same CI host,
with fixed Silverstone seed and identical capture scripts. No mock screenshots
are treated as acceptance evidence. Differing fixtures are INCOMPARABLE.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys

from PIL import Image, ImageChops, ImageStat

CAPTURES = (
    "silverstone_2d_broadcast",
    "silverstone_2d_compact",
    "silverstone_3d_compact",
)
CAPTURE_SCRIPT = Path("tests/ci/apex_capture_screenshots.gd")
# Heuristic thresholds for llvmpipe; strict tests for visual regressions are
# supplemented by manual review of the PNG diffs.
THRESHOLD_PER_CHANNEL = 24
LIMITS = {
    "silverstone_2d_broadcast": (0.010, 1.50),
    "silverstone_2d_compact": (0.010, 1.50),
    "silverstone_3d_compact": (0.025, 3.00),
}


class VisualError(ValueError):
    pass


def sha256(file: Path) -> str:
    return hashlib.sha256(file.read_bytes()).hexdigest()


def load_manifest(directory: Path) -> dict:
    try:
        data = json.loads((directory / "manifest.json").read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise VisualError(f"Invalid or missing manifest at {directory}: {exc}") from exc
    if not isinstance(data, dict) or data.get("status") != "PASS":
        raise VisualError(f"Missing PASS capture status in {directory}")
    if data.get("circuit") != "GBR" or data.get("seed") != 660 or data.get("cars") != 24:
        raise VisualError(f"Unexpected sporting fixture at {directory}")
    if data.get("sporting_cars_unchanged") is not True:
        raise VisualError(f"Sporting state was modified in {directory}")
    if not isinstance(data.get("captures"), list):
        raise VisualError(f"Manifest capture list missing in {directory}")
    captures = {item.get("name"): item for item in data["captures"] if isinstance(item, dict)}
    if set(captures) != set(CAPTURES) or len(data["captures"]) != len(CAPTURES):
        raise VisualError(f"Capture names or count differ from expected in {directory}")
    return data


def validate_sources(base_project: Path, candidate_project: Path) -> str:
    fixture1, fixture2 = base_project / CAPTURE_SCRIPT, candidate_project / CAPTURE_SCRIPT
    if not fixture1.is_file() or not fixture2.is_file():
        raise VisualError("Both revisions require the same screenshot fixture (improvement 3/8)")
    base_hash, candidate_hash = sha256(fixture1), sha256(fixture2)
    if base_hash != candidate_hash:
        raise VisualError("INCOMPARABLE: screenshot fixture changed between revisions")
    return base_hash


def compare_one(
    baseline: Path, candidate: Path, difference_file: Path, name: str
) -> dict:
    max_changed, max_mae = LIMITS[name]
    try:
        with Image.open(baseline) as original, Image.open(candidate) as current:
            original.load()
            current.load()
            if original.size != current.size:
                raise VisualError(f"{name}: image size changed {original.size} -> {current.size}")
            if original.size[0] < 1599 or original.size[1] != 900:
                raise VisualError(f"{name}: unexpected screenshot dimensions: {original.size}")
            left = original.convert("RGB")
            right = current.convert("RGB")
    except (OSError, ValueError) as exc:
        raise VisualError(f"{name}: cannot load both PNGs: {exc}") from exc

    diff = ImageChops.difference(left, right)
    mean = ImageStat.Stat(diff).mean
    mae = sum(mean) / 3.0
    red, green, blue = diff.split()
    max_channels = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    mask = max_channels.point(lambda x: 255 if x > THRESHOLD_PER_CHANNEL else 0)
    changed_pixels = mask.histogram()[255]
    ratio = changed_pixels / (left.width * left.height)

    # Bright red on the changed regions for manual inspection; background
    # remains the original image, not a misleading AI-rendered mock.
    tinted = Image.new("RGB", left.size, (250, 45, 75))
    preview = Image.composite(tinted, left, mask)
    difference_file.parent.mkdir(parents=True, exist_ok=True)
    preview.save(difference_file)
    status = "PASS" if ratio <= max_changed and mae <= max_mae else "FAIL"
    return {
        "name": name,
        "status": status,
        "resolution": list(left.size),
        "mae_rgb": round(mae, 6),
        "changed_pixels": changed_pixels,
        "changed_fraction": round(ratio, 8),
        "allowed_changed_fraction": max_changed,
        "allowed_mae_rgb": max_mae,
        "threshold_per_channel": THRESHOLD_PER_CHANNEL,
        "baseline_sha256": sha256(baseline),
        "candidate_sha256": sha256(candidate),
        "diff_file": difference_file.name,
    }


def compare(
    baseline_dir: Path,
    candidate_dir: Path,
    baseline_project: Path,
    candidate_project: Path,
    output: Path,
) -> dict:
    fixture_hash = validate_sources(baseline_project, candidate_project)
    original = load_manifest(baseline_dir)
    current = load_manifest(candidate_dir)
    if original.get("godot") != current.get("godot"):
        raise VisualError("INCOMPARABLE: Godot versions do not match")
    output.mkdir(parents=True, exist_ok=True)
    result = []
    for name in CAPTURES:
        base_png = baseline_dir / f"{name}.png"
        candidate_png = candidate_dir / f"{name}.png"
        result.append(
            compare_one(base_png, candidate_png, output / (name + "_diff.png"), name)
        )
    verdict = "PASS" if all(item["status"] == "PASS" for item in result) else "FAIL"
    return {
        "status": verdict,
        "comparison": "base_ref_vs_candidate_ref",
        "fixture_sha256": fixture_hash,
        "godot": original["godot"],
        "circuit": "GBR",
        "seed": 660,
        "capture_count": len(result),
        "results": result,
        "limitations": [
            "CI uses llvmpipe software renderer, not the player's GPU.",
            "Thresholds are heuristics; visual changes under tolerance require human review.",
            "This compares fixed screenshots, not FPS, animations, or full GP behavior.",
        ],
    }


def markdown_report(report: dict) -> str:
    lines = [
        "### APEX — Regressao visual A/B (Godot 4.7.2)",
        "",
        f"**Resultado: {report['status']}**",
        "",
        "| Captura | Status | Pixels diferentes | MAE RGB |",
        "|---|---|---:|---:|",
    ]
    for item in report["results"]:
        lines.append(
            f"| {item['name']} | {item['status']} | "
            f"{item['changed_fraction'] * 100:.3f}% | {item['mae_rgb']:.3f} |"
        )
    lines.extend([
        "",
        f"Fixture SHA256: `{report['fixture_sha256']}`",
        "",
        "Mudancas acima dos limites exigem revisao. Diff PNG: regioes alteradas em vermelho.",
        "As capturas foram feitas em ambiente virtual com llvmpipe; nao equivalem a FPS real.",
        "Este teste nao compara performance, saves, replay ou circuito completo.",
        "",
    ])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--baseline-project", type=Path, required=True)
    parser.add_argument("--candidate-project", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("visual-regression"))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    try:
        report = compare(
            args.baseline, args.candidate,
            args.baseline_project, args.candidate_project, args.output
        )
        (args.output / "report.json").write_text(
            json.dumps(report, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        (args.output / "report.md").write_text(
            markdown_report(report), encoding="utf-8"
        )
        print(
            "APEX_VISUAL_AB_DONE",
            json.dumps({"status": report["status"], "captures": report["capture_count"]}),
        )
        return 0 if report["status"] == "PASS" else 1
    except (VisualError, OSError) as exc:
        (args.output / "error.txt").write_text(str(exc) + "\n", encoding="utf-8")
        print(f"APEX_VISUAL_AB_ERROR {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
