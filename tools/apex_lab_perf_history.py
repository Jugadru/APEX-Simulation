#!/usr/bin/env python3
"""Optional history of existing FAST measurements. Never a performance gate."""
import argparse
import io
import json
import math
import os
from pathlib import Path
import re
import statistics
import subprocess
import zipfile
from apex_lab_perf_report import read_log, WEATHERS

REPO = "Jugadru/APEX-Simulation"
SHA = re.compile(r"[0-9a-f]{40}\Z")
HASH = re.compile(r"[0-9a-f]{64}\Z")
MAX_JSON = 64_000
MAX_ARCHIVE = 1_000_000
METRICS = ("mean_us", "p95_us", "peak_static_bytes", "end_over_start_ratio",
           "simulated_seconds_per_wall_second")


def require(ok, message):
    if not ok:
        raise ValueError(message)


def validate(record):
    require(record.get("schema") == 1 and record.get("repo") == REPO, "Invalid observation schema")
    for key in ("candidate", "checkout", "probe_blob"):
        require(isinstance(record.get(key), str) and SHA.fullmatch(record[key]), "Invalid provenance")
    for key in ("run_id", "attempt"):
        require(type(record.get(key)) is int and record[key] > 0, "Invalid run identity")
    require(record.get("event") in ("push", "pull_request", "workflow_dispatch"), "Invalid event")
    require(record.get("godot") == "4.7.2.stable.official.ed1daf0bf", "Invalid Godot version")
    for key in ("runner_os", "runner_arch", "runner_image"):
        require(isinstance(record.get(key), str) and len(record[key]) <= 120, "Invalid runner metadata")
    require(record.get("workload") == {"track": "LAB", "ticks": 500, "cars": 24, "seed": 991420,
                                      "repetitions": 2}, "Invalid workload")
    rows = record.get("observations")
    require(isinstance(rows, list) and len(rows) == 4, "Incomplete observations")
    identities = set()
    for row in rows:
        require(row.get("weather") in WEATHERS and type(row.get("repeat")) is int
                and row["repeat"] in (1, 2), "Invalid observation identity")
        identities.add((row["weather"], row["repeat"]))
        for key in METRICS:
            value = row.get(key)
            require(type(value) in (int, float) and math.isfinite(value)
                    and (value >= 0 if key == "peak_static_bytes" else value > 0), "Invalid measurement")
            if key == "peak_static_bytes":
                require(type(value) is int, "Invalid static memory")
    require(len(identities) == 4, "Duplicate observations")
    hashes = record.get("weather_hashes")
    require(isinstance(hashes, dict) and set(hashes) == set(WEATHERS)
            and all(isinstance(x, str) and HASH.fullmatch(x) for x in hashes.values()), "Invalid sporting hashes")
    return record


def observation(report, metadata):
    require(report["status"] == "PASS" and report["cases"] == 4 and report["total_ticks"] == 2000,
            "Validated existing report required")
    return validate({"schema": 1, "repo": REPO, **metadata,
                     "workload": {"track": "LAB", "ticks": 500, "cars": 24, "seed": 991420, "repetitions": 2},
                     "observations": report["observations"], "weather_hashes": report["weather_hashes"]})


def summary(record):
    return {"run_id": record["run_id"], "attempt": record["attempt"],
            "candidate": record["candidate"], "checkout": record["checkout"],
            "probe_blob": record["probe_blob"], "runner_image": record["runner_image"],
            "runner_os": record["runner_os"], "runner_arch": record["runner_arch"],
            "godot": record["godot"], "event": record["event"],
            "weather_hashes": record["weather_hashes"],
            "weather": {weather: {key: statistics.median(row[key] for row in record["observations"]
                                  if row["weather"] == weather) for key in METRICS} for weather in WEATHERS}}


def history(current, previous, issues=()):
    records = {}
    for record in [*previous, current]:
        validate(record)
        records[(record["run_id"], record["attempt"])] = record
    ordered = sorted(records.values(), key=lambda r: (r["run_id"], r["attempt"]))[-7:]
    return {"schema": 1, "state": "PARTIAL" if issues else ("OBSERVATIONS" if previous else "CURRENT_ONLY"),
            "comparison": "UNCONTROLLED_HOST_NOT_A_REGRESSION_GATE",
            "records": [summary(record) for record in ordered], "retrieval_issues": list(issues),
            "limitations": [
                "Existing synthetic headless FAST workload only; no new benchmark.",
                "Hosted machines vary; medians are descriptive, not causal estimates or acceptance thresholds.",
                "Probe changes and different sporting hashes can invalidate even workload-level comparison.",
                "Engine static memory is not RSS; no GPU frame timing or native graphics claim.",
                "History is limited to recent successful main push artifacts and retention. No missing record is invented.",
                "PR checkout can be a synthetic merge distinct from candidate SHA. Both are recorded."]}


def api(endpoint, limit):
    # No extraction of archive contents and no candidate-supplied URL.
    result = subprocess.run(["gh", "api", endpoint], stdout=subprocess.PIPE,
                            stderr=subprocess.DEVNULL, timeout=25, check=True)
    require(len(result.stdout) <= limit, "API response exceeds bound")
    return result.stdout


def archive_record(data):
    require(len(data) <= MAX_ARCHIVE, "Archive exceeds bound")
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        entries = z.infolist()
        require(len(entries) == 1 and entries[0].filename == "observation.json"
                and entries[0].file_size <= MAX_JSON, "Unexpected observation archive")
        return validate(json.loads(z.read(entries[0])))


def collect(current):
    records, issues = [], []
    try:
        runs = json.loads(api("repos/" + REPO +
            "/actions/workflows/godot-setup.yml/runs?branch=main&event=push&status=success&per_page=10",
            2_000_000))["workflow_runs"]
    except (ValueError, OSError, KeyError, subprocess.SubprocessError) as exc:
        return [], ["run_listing:" + type(exc).__name__]
    for run in runs:
        if len(records) >= 6:
            break
        rid = run.get("id")
        attempt = run.get("run_attempt")
        if (type(rid) is not int or rid >= current["run_id"] or type(attempt) is not int
                or run.get("head_branch") != "main" or run.get("event") != "push"
                or run.get("conclusion") != "success"):
            continue
        try:
            name = "apex-lab-observation-" + str(attempt)
            artifacts = json.loads(api("repos/" + REPO + "/actions/runs/" + str(rid) +
                                       "/artifacts?name=" + name + "&per_page=10", 200_000))["artifacts"]
            found = [a for a in artifacts if a.get("name") == name and not a.get("expired")]
            if not found:
                continue
            require(len(found) == 1 and type(found[0].get("id")) is int
                    and found[0].get("size_in_bytes", MAX_ARCHIVE + 1) <= MAX_ARCHIVE, "Invalid artifact")
            record = archive_record(api("repos/" + REPO + "/actions/artifacts/" +
                                        str(found[0]["id"]) + "/zip", MAX_ARCHIVE))
            require(record["run_id"] == rid and record["attempt"] == attempt
                    and record["candidate"] == record["checkout"] == run["head_sha"]
                    and record["event"] == "push", "Historical provenance mismatch")
            records.append(record)
        except (ValueError, OSError, KeyError, TypeError, zipfile.BadZipFile, subprocess.SubprocessError) as exc:
            issues.append(str(rid) + ":" + type(exc).__name__)
    return records, issues


def verify_existing(run_id, out):
    """Check cross-run retrieval without starting any simulation."""
    records, issues = collect({"run_id": run_id})
    distinct = len({record["checkout"] for record in records})
    status = "PASS" if distinct >= 2 and not issues else "INCONCLUSIVE"
    result = {"schema": 1, "status": status, "source": "successful_main_push_artifacts",
              "distinct_commits": distinct, "records": [summary(r) for r in records],
              "retrieval_issues": issues,
              "limitations": ["No simulation executed by this check.",
                              "PASS proves artifact retrieval and provenance checks, not performance improvement.",
                              "Hosted observations are uncontrolled; no GPU or regression acceptance."]}
    out.mkdir(parents=True, exist_ok=True)
    (out / "verification.json").write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n",
                                           encoding="utf-8")
    print("APEX_LAB_HISTORY_VERIFICATION " + json.dumps(result, ensure_ascii=False))
    return 0 if status == "PASS" else 2


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--log", type=Path)
    p.add_argument("--verify-existing", action="store_true")
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--history", action="store_true")
    args = p.parse_args()
    if args.verify_existing:
        if args.log or args.history:
            p.error("--verify-existing is a standalone artifact check")
        return verify_existing(int(os.environ["GITHUB_RUN_ID"]), args.out)
    if args.log is None:
        p.error("--log is required for current observations")
    def git(*argv):
        return subprocess.check_output(["git", *argv], text=True, timeout=15).strip()
    try:
        metadata = {"candidate": os.environ["APEX_HEAD_SHA"], "checkout": git("rev-parse", "HEAD"),
                    "probe_blob": git("rev-parse", "HEAD:tests/apex_lab_performance_probe.gd"),
                    "run_id": int(os.environ["GITHUB_RUN_ID"]), "attempt": int(os.environ["GITHUB_RUN_ATTEMPT"]),
                    "event": os.environ["GITHUB_EVENT_NAME"],
                    "godot": subprocess.check_output(["godot", "--headless", "--version"], text=True, timeout=15).strip(),
                    "runner_os": os.environ.get("RUNNER_OS", "unknown"),
                    "runner_arch": os.environ.get("RUNNER_ARCH", "unknown"),
                    "runner_image": os.environ.get("ImageVersion", "unknown")}
        current = observation(read_log(args.log.read_text(encoding="utf-8")), metadata)
        args.out.mkdir(parents=True, exist_ok=True)
        (args.out / "observation.json").write_text(json.dumps(current, indent=2, ensure_ascii=False) + "\n")
        previous, issues = collect(current) if args.history else ([], [])
        result = history(current, previous, issues)
        (args.out / "history.json").write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n")
        print("APEX_LAB_PERF_HISTORY " + json.dumps(result, ensure_ascii=False))
        return 0
    except (ValueError, OSError, KeyError, TypeError, subprocess.SubprocessError) as exc:
        print("APEX_LAB_PERF_HISTORY_BLOCKED " + type(exc).__name__)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
