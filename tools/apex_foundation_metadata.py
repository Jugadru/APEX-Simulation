#!/usr/bin/env python3
"""Opt-in Core 2 metadata exporter; reads two Git blobs, never a player save."""
from __future__ import annotations

import hashlib
import json
import os
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
    # Resolve the actual committed tree, never replacement refs or inherited Git redirects.
    env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    env.update(GIT_ALLOW_PROTOCOL="", GIT_NO_LAZY_FETCH="1", GIT_OPTIONAL_LOCKS="0",
               GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull, GIT_TERMINAL_PROMPT="0")
    return subprocess.check_output(["git", "--no-replace-objects", "-C", str(root), *args],
                                   env=env, timeout=20)

def committed_blob(root, revision, path):
    raw = git(root, "ls-tree", "-z", revision, "--", path)
    match = re.fullmatch(rb"100(?:644|755) blob ([0-9a-f]{40})\t" +
                         re.escape(path.encode("ascii")) + rb"\x00", raw)
    if not match:
        raise ValueError("expected committed regular source blob")
    return match.group(1).decode("ascii")

def export(root=ROOT):
    root = Path(root).resolve(strict=True)
    top = Path(git(root, "rev-parse", "--show-toplevel").decode("utf-8").strip()).resolve()
    if top != root:
        raise ValueError("expected exact checkout root")
    # HEAD is the actual checked-out commit (synthetic merge on PR CI).
    revision = git(root, "rev-parse", "--verify", "HEAD^{commit}").decode("ascii").strip()
    if not SHA.fullmatch(revision):
        raise ValueError("expected exact SHA-1 commit")
    sources, values = [], []
    for path in PATHS:
        blob = committed_blob(root, revision, path)
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
        with local.open("rb") as handle:
            checkout_raw = handle.read(MAX_BYTES + 1)
        if checkout_raw != raw:
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
