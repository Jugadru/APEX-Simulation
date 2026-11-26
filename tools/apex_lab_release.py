#!/usr/bin/env python3
"""Bounded Linux test export. Never publishes a release or tag."""
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import tarfile
import tempfile

ENGINE = "4.7.2.stable.official.ed1daf0bf"
NAME = "APEX_Motorsport_Manager.x86_64"
PRESET = "APEX Linux x86_64"
MAX_BYTES = 2 * 1024 * 1024 * 1024
BAD = re.compile(r"^ERROR:|SCRIPT ERROR:|Parse Error:", re.M)

def require(ok, message):
    if not ok:
        raise ValueError(message)

def sha256(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()

def inspect_file(path, kind):
    require(path.resolve() == path and path.is_file(), "Missing/nonregular " + kind)
    size = path.stat().st_size
    require(64 <= size <= MAX_BYTES, "Invalid size for " + kind)
    with path.open("rb") as stream:
        header = stream.read(64)
    if kind == "ELF":
        require(header[:6] == b"\x7fELF\x02\x01" and struct.unpack_from("<H", header, 18)[0] == 62,
                "Expected little-endian ELF64 x86_64")
        require(os.access(path, os.X_OK), "Executable permission missing")
    elif kind == "PCK":
        require(header[:4] == b"GDPC", "Expected Godot PCK magic")
    else:
        raise ValueError("Unknown kind")
    return {"file": path.name, "bytes": size, "sha256": sha256(path), "kind": kind}

def run(argv, cwd, log, timeout, env=None):
    with log.open("w", encoding="utf-8") as stream:
        code = subprocess.run(argv, cwd=cwd, env=env, stdout=stream,
                              stderr=subprocess.STDOUT, timeout=timeout, check=False).returncode
    with log.open(encoding="utf-8", errors="replace") as stream:
        require(code == 0 and not any(BAD.search(line) for line in stream),
                "Process failed: " + log.name)

def verify_archive(path, expected):
    with tarfile.open(path, "r:gz") as archive:
        members = archive.getmembers()
        require(len(members) == len(expected) and {m.name for m in members} == set(expected),
                "Unexpected archive contents")
        for member in members:
            row = expected[member.name]
            require(member.isfile() and member.size == row["bytes"], "Archive member mismatch")
            if row["kind"] == "ELF":
                require(bool(member.mode & 0o111), "Archive executable permission missing")
            stream = archive.extractfile(member)
            require(stream is not None, "Missing archive member")
            h = hashlib.sha256()
            with stream:
                for block in iter(lambda: stream.read(1024 * 1024), b""):
                    h.update(block)
            require(h.hexdigest() == row["sha256"], "Archive member hash mismatch")

def build(root, out, head):
    root, out = root.resolve(), out.resolve()
    require(re.fullmatch(r"[0-9a-f]{40}", head), "Exact SHA required")
    require(subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True,
                                    timeout=20).strip() == head, "Checkout mismatch")
    version = subprocess.check_output(["godot", "--headless", "--version"], cwd=root,
                                      text=True, timeout=20).strip()
    require(version == ENGINE, "Wrong editor version")
    config = (root / "project.godot").read_text(encoding="utf-8")
    match = re.search(r'^config/version="([0-9.]+)"$', config, re.M)
    require(match is not None, "Missing game version")
    report = {"schema": 1, "status": "BLOCKED", "head": head, "version": match[1],
              "engine": version, "preset": PRESET, "publication": "NOT_AUTHORIZED",
              "native_graphics": "NOT_RUN", "steps": []}
    out.mkdir(parents=True, exist_ok=True)
    def save():
        (out / "release-test.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    save()
    # Binaries are intentionally temporary, not public Actions artifacts.
    # The evidence directory alone is uploaded by the bridge.
    with tempfile.TemporaryDirectory(prefix="apex-export-", dir=os.environ.get("RUNNER_TEMP")) as tmp:
        work = Path(tmp).resolve()
        package = work / "package"
        package.mkdir()
        exe = package / NAME
        pck = package / "APEX_Motorsport_Manager.pck"
        try:
            run(["godot", "--headless", "--path", str(root), "--export-release", PRESET, str(exe)],
                root, out / "export.log", 300)
            report["steps"].append("export")
            rows = [inspect_file(exe, "ELF"), inspect_file(pck, "PCK")]
            report["files"] = rows
            report["steps"].append("elf_pck")
            home = work / "home"
            home.mkdir()
            env = dict(os.environ)
            env.update({"HOME": str(home), "XDG_DATA_HOME": str(home / "data"),
                        "XDG_CONFIG_HOME": str(home / "config"), "XDG_CACHE_HOME": str(home / "cache"),
                        "XDG_STATE_HOME": str(home / "state")})
            runtime = subprocess.check_output([str(exe), "--headless", "--version"], cwd=package,
                                              env=env, text=True, timeout=20).strip()
            require(runtime == ENGINE, "Wrong exported runtime version")
            run([str(exe), "--headless", "--rendering-method", "gl_compatibility",
                 "--main-pack", str(pck), "--quit-after", "120"],
                package, out / "startup.log", 90, env)
            report["steps"].append("isolated_headless_startup")
            archive = work / ("APEX-" + match[1] + "-" + head[:12] + "-linux-test.tar.gz")
            with tarfile.open(archive, "w:gz") as tar:
                for path in (exe, pck):
                    tar.add(path, arcname=path.name, recursive=False)
            verify_archive(archive, {row["file"]: row for row in rows})
            report["archive"] = {"file": archive.name, "bytes": archive.stat().st_size,
                                 "sha256": sha256(archive), "retention": "RUNNER_TEMP_ONLY"}
            report["steps"].append("archive_roundtrip")
            (out / "SHA256SUMS").write_text("".join(row["sha256"] + "  " + row["file"] + "\n" for row in rows)
                                             + report["archive"]["sha256"] + "  " + archive.name + "\n",
                                             encoding="utf-8")
            (out / "BUILD_NOTES.md").write_text(
                "# APEX Linux test export\n\nVersion: " + match[1] + "\n\nCommit: " + head +
                "\n\nExisting changelog: CHANGELOG.md at the exact commit.\n\n"
                "Test-only, isolated headless startup and archive roundtrip. "
                "No native GPU, full race, distribution rights or release approval inferred.\n", encoding="utf-8")
            report["status"] = "PASS"
        except (ValueError, OSError, subprocess.SubprocessError, tarfile.TarError) as error:
            report["reason"] = str(error)
            raise ValueError("Linux test export blocked: " + type(error).__name__) from error
        finally:
            save()
            print("APEX_LAB_RELEASE " + json.dumps(report))
    return report
