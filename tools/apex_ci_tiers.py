#!/usr/bin/env python3
"""Select the smallest safe, deterministic Godot test set for a PR diff."""
from __future__ import annotations
import argparse
from pathlib import Path
import re
import subprocess
import sys
from apex_quality_manifest import load_suites, fast_tests_for

SHA = re.compile(r"[0-9a-fA-F]{40}\Z")
ALWAYS = (
    ("race_launch_14_test.gd", "RACE_LAUNCH_14_PASS"),
    ("replay_0660_test.gd", "REPLAY_UNIT_PASS"),
    ("pit_incidents_double_stack_test.gd", "APEX INCIDENT DOUBLE STACK OK"),
)
CASES = {
    "ai": ("lap_strategy_06496_auto_gate_test.gd", "AUTO_GATE_06496_PASS"),
    "driver": ("driver_soul_06694_test.gd", "DRIVER_SOUL_06694_PASS"),
    "hud": ("hud_metric_refactor_test.gd", "HUD_METRIC_REFACTOR_PASS"),
    "orders": ("team_orders_066810_test.gd", "TEAM_ORDERS_066810_PASS"),
    "pit": ("pit_coordination_06697_test.gd", "PIT_COORD_06697_PASS"),
    "prediction": ("pitwall_prediction_06696_test.gd", "PITWALL_LEDGER_06696_PASS"),
    "radio": ("race_radio_06695_test.gd", "RACE_RADIO_06695_PASS"),
    "save": ("core_0642_save_migration_test.gd", "APEX 0642 SAVE MIGRATION PASS"),
    "staff": ("strategy_staff_066910_test.gd", "STRATEGY_STAFF_066910_PASS"),
    "start": ("race_start_066911_test.gd", "RACE_START_066911_PASS"),
    "overtake": ("overtaking_066912_test.gd", "OVERTAKING_066912_PASS"),
    "engineer": ("engineer_intelligence_066913_test.gd", "ENGINEER_066913_PASS"),
    "setup": ("setup_track_066914_test.gd", "SETUP_TRACK_066914_PASS"),
    "wet": ("wet_strategy_06698_test.gd", "WET_STRATEGY_06698_PASS"),
}
CORE = frozenset(("ai", "pit", "wet", "orders", "staff", "start", "overtake", "engineer", "setup"))
EXACT = {
    "scripts/race_engine.gd": CORE,
    "scripts/core/race_replay_0660.gd": frozenset(("wet", "staff", "prediction", "save", "start", "overtake")),
    "scripts/core/race_space_0655.gd": frozenset(("overtake", "driver", "start")),
    "scripts/core/race_state_codec_0660.gd": frozenset(("save", "staff", "prediction", "start", "overtake")),
    "scripts/core/race_performance.gd": frozenset(("start", "wet", "driver")),
    "scripts/apex_race_session_controller.gd": frozenset(("ai", "staff", "wet")),
    "scripts/apex_race_hud_0622.gd": frozenset(("hud", "staff", "engineer", "setup")),
    "data/season_2012.json": frozenset(("ai", "pit", "wet")),
    "data/tyres_2012.json": frozenset(("ai", "pit", "wet")),
}

def changed_files(root: Path, base_sha: str, head_sha: str) -> list[str]:
    if not SHA.fullmatch(base_sha) or not SHA.fullmatch(head_sha):
        raise ValueError("Two exact Git SHAs are required")
    raw = subprocess.check_output(
        ["git", "-C", str(root), "diff", "--name-only", "-z",
         f"{base_sha}...{head_sha}", "--"], timeout=30)
    return sorted({p.decode("utf-8") for p in raw.split(b"\0") if p})

def categories_for(paths: list[str]) -> set[str]:
    categories: set[str] = set()
    for path in paths:
        local = set(EXACT.get(path, ()))
        name = path.lower()
        if path.startswith("scripts/core/"):
            if "staff" in name or "strateg" in name: local.update(("staff", "ai"))
            if "race_start" in name or "race_launch" in name: local.add("start")
            if "overtaking" in name or "race_space" in name: local.add("overtake")
            if "weather" in name or "wet" in name or "tyre" in name: local.add("wet")
            if "pit" in name: local.update(("pit", "prediction"))
            if "radio" in name: local.add("radio")
            if "engineer" in name: local.add("engineer")
            if "setup_track" in name: local.add("setup")
            if "save" in name or "career" in name or "checkpoint" in name: local.add("save")
            if "driver" in name or "soul" in name: local.add("driver")
            if "replay" in name or "codec" in name: local.update(("wet", "staff", "prediction"))
            # Unknown Core module gets more tests, not fewer.
            if not local and path.endswith(".gd"): local.update(CASES)
        if path.startswith("scripts/") and ("hud" in name or "panel" in name):
            local.add("hud")
        if path.startswith("tests/") and path.endswith(".gd"):
            for category, (script, _) in CASES.items():
                if path == "tests/" + script: local.add(category)
        # Unknown modules outside Core are also high-risk until registered.
        if not local and path.startswith("scripts/") and path.endswith(".gd"):
            local.update(CASES)
        if not local and path.startswith("data/") and path.endswith((".json", ".csv", ".tres")):
            local.update(CASES)
        categories.update(local)
    return categories

def select(paths: list[str], root: Path) -> list[tuple[str, str]]:
    chosen = list(ALWAYS)
    for category in sorted(categories_for(paths)):
        script, marker = CASES[category]
        if (root / "tests" / script).is_file() and (script, marker) not in chosen:
            chosen.append((script, marker))
    for script, marker in fast_tests_for(paths, load_suites(root)):
        if not (root / 'tests' / script).is_file():
            raise ValueError('Missing mandatory FAST test: tests/' + script)
        if (script, marker) not in chosen:
            chosen.append((script, marker))
    return chosen

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-sha", required=True)
    parser.add_argument("--head-sha", required=True)
    parser.add_argument("--project", type=Path, default=Path("."))
    args = parser.parse_args()
    try:
        changed = changed_files(args.project, args.base_sha, args.head_sha)
        if not changed: raise ValueError("Empty PR diff; no bypass")
        planned = select(changed, args.project)
        for script, marker in planned:
            print(script + "|" + marker)
        print("APEX_CI_FAST_PLAN files=%d tests=%d domains=%s" % (
            len(changed), len(planned), ",".join(sorted(categories_for(changed)))),
            file=sys.stderr)
        return 0
    except (ValueError, OSError, subprocess.CalledProcessError,
            subprocess.TimeoutExpired) as error:
        print("APEX_CI_FAST_PLAN_FAIL: " + str(error), file=sys.stderr)
        return 2

if __name__ == "__main__":
    raise SystemExit(main())
