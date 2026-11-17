#!/usr/bin/env python3
"""Validate and package APEX Godot desktop exports (Linux and Windows x86_64).

A successful Godot command is insufficient: verify executable signatures,
separate PCK packs, ZIP members and SHA256. Never publish a release here.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import stat
import sys
import zipfile

TARGETS = {
    "linux": ("APEX_Motorsport_Manager.x86_64", b"\x7fELF"),
    "windows": ("APEX_Motorsport_Manager.exe", b"MZ"),
}
MIN_EXEC_SIZE = 1_000_000
MIN_PACK_SIZE = 10_000


class PackageError(ValueError):
    pass


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as data:
        for chunk in iter(lambda: data.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def validate_target(folder: Path, platform: str) -> list[Path]:
    executable_name, magic = TARGETS[platform]
    binary = folder / executable_name
    pack = folder / "APEX_Motorsport_Manager.pck"
    if not binary.is_file() or not pack.is_file():
        raise PackageError(f"{platform}: executable or matching .pck missing")
    if binary.stat().st_size <= MIN_EXEC_SIZE:
        raise PackageError(f"{platform}: executable unexpectedly small")
    if pack.stat().st_size <= MIN_PACK_SIZE:
        raise PackageError(f"{platform}: PCK unexpectedly small")
    with binary.open("rb") as stream:
        if stream.read(len(magic)) != magic:
            raise PackageError(f"{platform}: incorrect executable signature")
    if platform == "linux" and not os.access(binary, os.X_OK):
        raise PackageError("Linux executable lacks executable permission")
    return [binary, pack]


def package(root: Path, output: Path, version: str) -> dict:
    if not version or any(c in version for c in "/\\\0"):
        raise PackageError("Unsafe version string")
    output.mkdir(parents=True, exist_ok=True)
    result = {"status": "PASS", "godot_version": version, "platforms": {}}
    for platform in ("linux", "windows"):
        folder = root / platform
        paths = validate_target(folder, platform)
        entries = []
        archive_path = output / f"APEX_Motorsport_Manager_{version}_{platform}_x86_64.zip"
        with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for path in paths:
                archive.write(path, arcname=path.name)
                entries.append({
                    "file": path.name,
                    "bytes": path.stat().st_size,
                    "sha256": sha256(path),
                })
        with zipfile.ZipFile(archive_path) as archive:
            if sorted(archive.namelist()) != sorted(path.name for path in paths):
                raise PackageError(f"{platform}: invalid ZIP members")
            bad = archive.testzip()
            if bad is not None:
                raise PackageError(f"{platform}: ZIP integrity error: {bad}")
        result["platforms"][platform] = {
            "archive": archive_path.name,
            "archive_bytes": archive_path.stat().st_size,
            "archive_sha256": sha256(archive_path),
            "files": entries,
        }
        print(f"APEX_EXPORT_PACKAGED {platform} {archive_path.name} ({archive_path.stat().st_size} bytes)")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--builds", type=Path, default=Path("builds"))
    parser.add_argument("--output", type=Path, default=Path("dist"))
    parser.add_argument("--godot-version", default="4.7.2-stable")
    args = parser.parse_args()
    try:
        result = package(args.builds, args.output, args.godot_version)
        (args.output / "manifest.json").write_text(
            json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
        )
        print("APEX_EXPORT_PACKAGES_PASS Linux/Windows x86_64")
        return 0
    except (OSError, PackageError, zipfile.BadZipFile) as exc:
        args.output.mkdir(parents=True, exist_ok=True)
        (args.output / "error.txt").write_text(str(exc) + "\n", encoding="utf-8")
        print(f"APEX_EXPORT_PACKAGES_FAIL {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
