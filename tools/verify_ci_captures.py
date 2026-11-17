#!/usr/bin/env python3
"""Validate actual Godot CI PNG captures and their machine-readable manifest.

Only checks completeness and integrity. Visual pixel regression is a later step.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys

PNG_SIGNATURE = bytes.fromhex("89504e470d0a1a0a")
EXPECTED = {
    "silverstone_2d_broadcast": ("2D", 0),
    "silverstone_2d_compact": ("2D", 1),
    "silverstone_3d_compact": ("3D", 1),
}


def verify_capture_folder(folder: Path) -> list[str]:
    errors = []
    manifest_path = folder / "manifest.json"
    try:
        info = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        return [f"Missing or invalid capture manifest: {exc}"]

    if (info.get("status") != "PASS" or info.get("circuit") != "GBR"
            or info.get("seed") != 660 or info.get("cars") != 24
            or info.get("sporting_cars_unchanged") is not True):
        errors.append("Capture metadata or sporting-state check did not pass")

    captures = info.get("captures")
    if not isinstance(captures, list) or len(captures) != len(EXPECTED):
        return errors + ["Expected exactly three capture records"]

    found = set()
    for record in captures:
        if not isinstance(record, dict):
            errors.append("Invalid capture record")
            continue
        name = record.get("name")
        if name not in EXPECTED or name in found:
            errors.append(f"Unexpected or repeated capture name: {name}")
            continue
        found.add(name)
        expected_view, expected_hud = EXPECTED[name]
        if record.get("render_mode") != expected_view or record.get("hud_mode") != expected_hud:
            errors.append(f"Wrong visual/HUD mode for {name}")
        if record.get("file") != name + ".png":
            errors.append(f"Unexpected output filename for {name}")
            continue

        screenshot = folder / (name + ".png")
        try:
            raw = screenshot.read_bytes()
        except OSError as exc:
            errors.append(f"Cannot read {name}: {exc}")
            continue
        if len(raw) < 4096 or not raw.startswith(PNG_SIGNATURE) or raw[12:16] != b"IHDR":
            errors.append(f"PNG missing, malformed or too small: {name}")
            continue
        width, height = struct.unpack(">II", raw[16:24])
        if abs(width - 1600) > 1 or height != 900:
            errors.append(f"Unexpected PNG resolution: {name} {width}x{height}")
        if record.get("width") != width or record.get("height") != height:
            errors.append(f"Manifest resolution does not match PNG: {name}")
        if record.get("bytes") != len(raw):
            errors.append(f"Manifest byte count does not match PNG: {name}")
        if record.get("sha256") != hashlib.sha256(raw).hexdigest():
            errors.append(f"PNG SHA256 does not match manifest: {name}")

    if found != set(EXPECTED):
        errors.append(f"Missing captures: {sorted(set(EXPECTED) - found)}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", nargs="?", type=Path,
                        default=Path("ci_artifacts/screenshots"))
    args = parser.parse_args()
    errors = verify_capture_folder(args.folder)
    if errors:
        for error in errors:
            print("APEX_CAPTURE_VERIFY_FAIL", error, file=sys.stderr)
        return 1
    print("APEX_CAPTURE_VERIFY_PASS 3 real PNGs, metadata and SHA256 verified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
