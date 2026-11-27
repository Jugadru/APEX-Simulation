#!/usr/bin/env python3
"""Opt-in Core 2 metadata exporter; reads two Git blobs, never a player save."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from decimal import Decimal

ROOT = Path(__file__).resolve().parents[1]
PATHS = ("data/season_2012.json", "data/teams.json")
MAX_BYTES = 4 * 1024 * 1024
SHA = re.compile(r"[0-9a-f]{40}\Z")
CODE = re.compile(r"[A-Z]{3}\Z")
CONTRACT = "core2-metadata.v1"

def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True,
                      separators=(",", ":"), allow_nan=False).encode("utf-8")

def digest(value):
    return hashlib.sha256(canonical(value)).hexdigest()

def pairs(rows):
    result = {}
    for key, value in rows:
        if key in result:
            raise ValueError("duplicate JSON key")
        result[key] = value
    return result

def bad_constant(value):
    raise ValueError("non-finite JSON constant")

def parse(raw):
    if not 0 < len(raw) <= MAX_BYTES:
        raise ValueError("invalid source size")
    return json.loads(raw.decode("utf-8"), object_pairs_hook=pairs,
                      parse_constant=bad_constant, parse_float=Decimal)

def label(value):
    if not isinstance(value, str) or not 1 <= len(value) <= 160 or value != value.strip():
        raise ValueError("invalid metadata label")
    if any(ord(c) < 32 or 127 <= ord(c) <= 159 for c in value):
        raise ValueError("control characters in label")
    return value

def integer(value, low, high):
    if type(value) is not int or not low <= value <= high:
        raise ValueError("invalid metadata integer")
    return value

def build(season, teams):
    if not isinstance(season, dict) or type(season.get("season")) is not int or season["season"] != 2012:
        raise ValueError("expected 2012 source")
    native = season["teams"]
    tracks = season["tracks"]
    if not isinstance(native, list) or len(native) != 12 or not isinstance(teams, list) or teams != native:
        raise ValueError("team sources diverge or unexpected team count")
    if not isinstance(tracks, list) or len(tracks) != 20:
        raise ValueError("unexpected circuit count")
    team_rows, driver_rows, track_rows = [], [], []
    team_names, driver_names, track_codes = set(), set(), set()
    for index, team in enumerate(native):
        name = label(team["name"])
        if name in team_names or not isinstance(team["drivers"], list) or len(team["drivers"]) != 2:
            raise ValueError("duplicate team or invalid driver count")
        team_names.add(name)
        team_rows.append({"index": index, "name": name})
        for slot, driver in enumerate(team["drivers"]):
            name = label(driver["name"])
            if name in driver_names:
                raise ValueError("duplicate driver")
            driver_names.add(name)
            driver_rows.append({"team_index": index, "slot": slot, "name": name})
    for index, track in enumerate(tracks):
        code = track["code"]
        if not isinstance(code, str) or not CODE.fullmatch(code) or code in track_codes:
            raise ValueError("invalid or duplicate circuit code")
        track_codes.add(code)
        track_rows.append({"index": index, "code": code, "name": label(track["name"]),
                           "country": label(track["country"]), "laps": integer(track["laps"], 1, 200)})
    return {"season": 2012, "teams": team_rows, "drivers": driver_rows, "circuits": track_rows}

def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], timeout=20)

def export(root=ROOT):
    # HEAD is the actual checked-out commit (synthetic merge on PR CI).
    revision = git(root, "rev-parse", "--verify", "HEAD^{commit}").decode("ascii").strip()
    if not SHA.fullmatch(revision):
        raise ValueError("expected exact SHA-1 commit")
    sources, values = [], []
    for path in PATHS:
        blob = git(root, "rev-parse", "--verify", revision + ":" + path).decode("ascii").strip()
        if not SHA.fullmatch(blob):
            raise ValueError("invalid Git blob identity")
        size = int(git(root, "cat-file", "-s", blob))
        if not 0 < size <= MAX_BYTES:
            raise ValueError("source exceeds size bound")
        raw = git(root, "cat-file", "blob", blob)
        actual = hashlib.sha1(b"blob " + str(len(raw)).encode("ascii") + b"\0" + raw).hexdigest()
        if len(raw) != size or actual != blob:
            raise ValueError("Git blob integrity mismatch")
        # Require the actual native checkout file to match committed data.
        local = root / path
        if any(x.is_symlink() for x in (local, local.parent)) or not local.is_file() or local.stat().st_size != size:
            raise ValueError("checkout source identity mismatch")
        if local.read_bytes() != raw:
            raise ValueError("checkout data differs from exact revision")
        sources.append({"path": path, "git_blob": blob, "sha256": hashlib.sha256(raw).hexdigest(),
                        "size_bytes": size})
        values.append(parse(raw))
    body = {"contract": CONTRACT, "repository": "Jugadru/APEX-Simulation",
            "revision": revision, "scope": "CORE2_METADATA_READ_ONLY",
            "authority": "core2", "identity_scope": "EXACT_REVISION_ONLY",
            "sources": sources, "catalog": build(*values),
            "runtime_applied": False, "execution_authorized": False}
    return {"body": body, "body_sha256": digest(body)}

def main():
    if len(sys.argv) != 1:
        print("No arguments accepted; export fixed data from exact HEAD to stdout", file=sys.stderr)
        return 2
    try:
        print(json.dumps(export(), ensure_ascii=False, sort_keys=True, indent=2, allow_nan=False))
        return 0
    except (ValueError, TypeError, KeyError, OSError, UnicodeError, subprocess.SubprocessError, RecursionError) as exc:
        print("APEX_METADATA_FAIL: " + str(exc)[:300], file=sys.stderr)
        return 2

if __name__ == "__main__":
    raise SystemExit(main())
