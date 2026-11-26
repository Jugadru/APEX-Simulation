#!/usr/bin/env python3
"""Read-only hosted command bridge; no arbitrary shell, local runner or release."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import urllib.request

REPO = "Jugadru/APEX-Simulation"
OWNER = "Jugadru"
HUB = 141
COMMANDS = ("fast", "audit", "diagnose", "racecraft", "strategy", "replay", "performance", "report")
SHA = re.compile(r"[0-9a-f]{40}\Z")
COMMAND = re.compile(r"/lab (" + "|".join(COMMANDS) + r") ([0-9a-f]{40})\Z")
BAD = re.compile(r"^ERROR:|SCRIPT ERROR:|Parse Error:", re.M)
TESTS = {
    "racecraft": (
        ("race_launch_14_test.gd", "RACE_LAUNCH_14_PASS"),
        ("overtaking_066912_test.gd", "OVERTAKING_066912_PASS"),
        ("racing_line_091710_test.gd", "RACING_LINE_091710_PASS"),
        ("racing_follow_091710_test.gd", "FOLLOW_091710_PASS"),
        ("racing_completion_091710_test.gd", "COMPLETION_091710_PASS"),
        ("racing_independent_091710_test.gd", "INDEPENDENT_091710_PASS"),
        ("aero_wake_091711_test.gd", "AERO_WAKE_091711_PASS"),
        ("tactical_coordination_091712_test.gd", "COORDINATION_091712_PASS"),
        ("corner_battle_0919_test.gd", "CORNER_BATTLE_0919_PASS"),
        ("driver_traffic_0920_test.gd", "DRIVER_TRAFFIC_0920_PASS"),
        ("traffic_mega_09201_test.gd", "TRAFFIC_MEGA_09201_PASS"),
        ("driver_error_0921_test.gd", "DRIVER_ERROR_0921_PASS"),
    ),
    "strategy": (
        ("lap_strategy_06496_auto_gate_test.gd", "AUTO_GATE_06496_PASS"),
        ("wet_strategy_06698_test.gd", "WET_STRATEGY_06698_PASS"),
        ("pit_incidents_double_stack_test.gd", "APEX INCIDENT DOUBLE STACK OK"),
        ("pit_coordination_06697_test.gd", "PIT_COORD_06697_PASS"),
        ("strategy_staff_066910_test.gd", "STRATEGY_STAFF_066910_PASS"),
        ("team_orders_066810_test.gd", "TEAM_ORDERS_066810_PASS"),
        ("radio_0668101_booked_pit_advice_test.gd", "RADIO_0668101_BOOKED_PIT_PASS"),
        ("pitwall_0649_strategy_test.gd", "PITWALL_0649_STRATEGY_PASS"),
    ),
    "replay": (
        ("replay_0660_test.gd", "REPLAY_UNIT_PASS"),
        ("hash_cache_06692_test.gd", "APEX_HASH_CACHE_06692_PASS"),
        ("core_0642_save_migration_test.gd", "APEX 0642 SAVE MIGRATION PASS"),
    ),
    "performance": (
        ("apex_lab_track_smoke.gd", "APEX_LAB_TRACK_PASS"),
        ("apex_lab_performance_probe.gd", "APEX_LAB_PERF_PASS"),
    ),
}

def require(ok, message):
    if not ok:
        raise ValueError(message)

def authorize(event, actor, event_sha, get_pr):
    require(event.get("action") == "created", "Only new comments")
    require(event.get("repository", {}).get("full_name") == REPO, "Wrong repository")
    comment = event.get("comment", {})
    require(actor == OWNER and event.get("sender", {}).get("login") == OWNER
            and comment.get("user", {}).get("login") == OWNER
            and comment.get("author_association") == "OWNER", "Owner only")
    m = COMMAND.fullmatch(comment.get("body", "").strip())
    require(m is not None, "Expected /lab <allowed-command> <full-sha>")
    command, sha = m.groups()
    issue = event["issue"]
    number = issue["number"]
    require(type(number) is int and number > 0, "Invalid issue")
    if "pull_request" in issue:
        pr = get_pr(number)
        require(pr.get("state") == "open" and pr.get("base", {}).get("ref") == "main",
                "Open PR targeting main required")
        for key in ("head", "base"):
            require((pr.get(key, {}).get("repo") or {}).get("full_name") == REPO,
                    "Same-repository PR only; forks rejected")
        require(pr["head"]["sha"] == sha, "PR head changed or SHA mismatch")
        base = pr["base"]["sha"]
        require(SHA.fullmatch(base), "Invalid base SHA")
    else:
        require(number == HUB, "Use Performance Hub or an open same-repo PR")
        require(sha == event_sha, "Use exact main SHA at dispatch")
        base = ""
    return {"command": command, "head": sha, "base": base, "issue": str(number)}

def fetch_pr(number):
    req = urllib.request.Request("https://api.github.com/repos/" + REPO + "/pulls/" + str(number),
        headers={"Authorization": "Bearer " + os.environ["GH_TOKEN"],
                 "Accept": "application/vnd.github+json",
                 "X-GitHub-Api-Version": "2022-11-28"})
    with urllib.request.urlopen(req, timeout=20) as response:
        return json.load(response)

def select_tests(command, base, head, root):
    if command in TESTS:
        rows = list(TESTS[command])
    elif command in ("fast", "diagnose", "report"):
        if not base:
            base = subprocess.check_output(["git", "rev-parse", head + "^"], cwd=root, text=True, timeout=20).strip()
        require(SHA.fullmatch(base), "Invalid base SHA")
        raw = subprocess.check_output([sys.executable, "tools/apex_ci_tiers.py",
            "--base-sha", base, "--head-sha", head, "--project", "."],
            cwd=root, text=True, timeout=45)
        rows = [tuple(line.split("|", 1)) for line in raw.splitlines()]
    else:
        rows = []
    require(len(rows) <= 100, "Test plan exceeds bound")
    for row in rows:
        require(len(row) == 2 and re.fullmatch(r"[A-Za-z0-9_]+\.gd", row[0])
                and re.fullmatch(r"[A-Za-z0-9_ .-]+", row[1]), "Invalid test plan")
        require((root / "tests" / row[0]).is_file(), "Missing test: " + row[0])
    require(command == "audit" or bool(rows), "Empty test plan")
    return rows

def run_case(argv, log, timeout, root, marker=None, check_godot=False):
    with log.open("w", encoding="utf-8") as stream:
        try:
            code = subprocess.run(argv, cwd=root, stdout=stream, stderr=subprocess.STDOUT,
                                  timeout=timeout, check=False).returncode
        except subprocess.TimeoutExpired:
            return {"status": "BLOCKED", "reason": "timeout", "log": log.name}
        except OSError:
            return {"status": "BLOCKED", "reason": "executable unavailable", "log": log.name}
    output = log.read_text(encoding="utf-8", errors="replace")
    if code or (check_godot and BAD.search(output)) or (marker and marker not in output):
        return {"status": "FAIL", "reason": "exit/marker/engine error; inspect log", "exit": code, "log": log.name}
    return {"status": "PASS", "log": log.name}

def execute(command, base, head, root, out):
    require(command in COMMANDS and SHA.fullmatch(head), "Invalid command or SHA")
    require(not base or SHA.fullmatch(base), "Invalid base")
    actual = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True, timeout=20).strip()
    require(actual == head, "Checkout mismatch")
    out.mkdir(parents=True, exist_ok=False)
    report = {"schema": 1, "command": command, "head": head, "base": base,
              "status": "BLOCKED", "cases": [], "limitations": [
                  "Supplementary command, not official FAST or FULL approval",
                  "Hosted runner only; no native GPU or paired performance acceptance",
                  "Static inventory is heuristic; no automatic changes or release"]}
    def save():
        (out / "report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    save()
    try:
        rows = select_tests(command, base, head, root)
        report["plan"] = [{"script": s, "marker": m} for s, m in rows]
        save()
        if command == "report":
            report["status"] = "PASS"
            report["limitations"].append("Plan only; no test executed")
            return 0
        inventory = run_case([sys.executable, "tools/apex_source_inventory.py", "--check", "--output",
                              str(out / "source-inventory.json")], out / "inventory.log", 90, root)
        report["cases"].append({"name": "inventory", **inventory})
        save()
        if inventory["status"] != "PASS":
            report["status"] = inventory["status"]
            return 1
        if command == "audit":
            report["status"] = "PASS"
            return 0
        version = subprocess.check_output(["godot", "--headless", "--version"], cwd=root, text=True, timeout=20).strip()
        require(version == "4.7.2.stable.official.ed1daf0bf", "Wrong Godot version")
        imported = run_case(["godot", "--headless", "--single-threaded-scene", "--path", ".", "--import"],
                            out / "import.log", 240, root, check_godot=True)
        report["cases"].append({"name": "import", **imported})
        save()
        if imported["status"] != "PASS":
            report["status"] = imported["status"]
            return 1
        for script, marker in rows:
            result = run_case(["bash", "tools/apex_ci_isolated_test.sh", script],
                              out / (script + ".log"), 260, root, marker, True)
            report["cases"].append({"name": script, **result})
            save()
            if result["status"] != "PASS":
                report["status"] = result["status"]
                return 1
        if command == "performance":
            result = run_case([sys.executable, "tools/apex_lab_perf_report.py", "--log",
                               str(out / "apex_lab_performance_probe.gd.log"), "--output",
                               str(out / "lab-perf")], out / "perf-report.log", 60, root)
            report["cases"].append({"name": "performance report", **result})
            if result["status"] != "PASS":
                report["status"] = result["status"]
                return 1
        report["status"] = "PASS"
        return 0
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        report["reason"] = str(error)
        return 2
    finally:
        save()
        print("APEX_LAB_COMMAND " + json.dumps({"command": command, "head": head,
              "status": report["status"], "cases": report["cases"]}))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="mode", required=True)
    sub.add_parser("authorize")
    run = sub.add_parser("execute")
    run.add_argument("--command", choices=COMMANDS, required=True)
    run.add_argument("--base", default="")
    run.add_argument("--head", required=True)
    run.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.mode == "authorize":
            event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
            result = authorize(event, os.environ["GITHUB_ACTOR"], os.environ["GITHUB_SHA"], fetch_pr)
            with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as stream:
                for key, value in result.items():
                    stream.write(key + "=" + value + "\n")
            return 0
        return execute(args.command, args.base, args.head, Path.cwd(), args.output.resolve())
    except (ValueError, OSError, KeyError, subprocess.SubprocessError) as error:
        print("APEX_LAB_COMMAND_BLOCKED: " + str(error), file=sys.stderr)
        return 2

if __name__ == "__main__":
    raise SystemExit(main())
