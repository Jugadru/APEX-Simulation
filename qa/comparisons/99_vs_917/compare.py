#!/usr/bin/env python3
"""Independent evidence collection for APEX 9.9 vs 9.17 on Godot 4.7.2.
The probe is identical for both versions. Never conflate across-revision
sporting-hash changes with nondeterminism or label headless CPU as GPU FPS.
"""
from __future__ import annotations
import argparse
import json
import math
import os
import shlex
from pathlib import Path
import statistics
import subprocess
import sys
import time

MARKERS = {
    "matrix": "APEX_MATRIX_RESULT ",
    "full": "APEX_FULL_GP_DONE ",
    "visual": "VISUAL_STUTTER_06672_BENCHMARK ",
    "bench": "GROWTH_DONE ",
}
TRACKS = ["GBR", "MON", "ITA", "BEL", "SIN"]
CLIMATES = ["Seco", "Variável", "Chuva intensa"]
MODES = ["Manual", "IA"]

def read_json(path: str | Path):
    return json.loads(Path(path).read_text(encoding="utf-8"))

def write(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8")

def marker(text: str, name: str):
    lines = [line.split(name, 1)[1].strip()
             for line in text.splitlines() if name in line]
    # Reject duplicates, incomplete markers or misleading shell echoes.
    if len(lines) != 1:
        raise ValueError(f"Expected one {name!r}; found {len(lines)}")
    return json.loads(lines[0])

def invoke(project: Path, script: str, label: str, out: Path,
           env: dict[str, str] | None = None, timeout: int = 240):
    out.parent.mkdir(parents=True, exist_ok=True)
    variables = os.environ.copy()
    variables.update(env or {})
    # Isolate writable Godot directories between versions/instances.
    variables["HOME"] = str((out.parent / ("home_" + label)).resolve())
    variables["XDG_DATA_HOME"] = variables["HOME"] + "/data"
    variables["XDG_CONFIG_HOME"] = variables["HOME"] + "/config"
    variables["XDG_CACHE_HOME"] = variables["HOME"] + "/cache"
    for path in ("HOME", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
        Path(variables[path]).mkdir(parents=True, exist_ok=True)
    args = ["godot", "--headless", "--single-threaded-scene", "--path",
            str(project.resolve()), "--script", script]
    started = time.monotonic()
    try:
        proc = subprocess.run(["bash", "-c", " ".join(shlex.quote(x) for x in args)],
                              text=True, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, env=variables,
                              timeout=timeout, check=False)
        raw = proc.stdout
        code = proc.returncode
    except subprocess.TimeoutExpired as exc:
        raw = (exc.stdout or b"")
        if isinstance(raw, bytes):
            raw = raw.decode("utf-8", errors="replace")
        raw += "\nAPEX_AB_TIMEOUT\n"
        code = 124
    # Preserve full logs for investigation without flooding GitHub Actions stdout.
    out.write_text(raw, encoding="utf-8")
    return code, raw, round(time.monotonic() - started, 3)

def summarize_starts(directory: Path):
    base = read_json(directory / "start_base.json")
    new = read_json(directory / "start_candidate.json")
    assert base["case_count"] == new["case_count"] == 40
    assert base["repeated_cases"] == new["repeated_cases"] == 8
    checks = []
    issues = []
    pairs = []
    for a, b in zip(base["cases"], new["cases"]):
        assert (a["track"], a["weather"], a["seed"]) == (
            b["track"], b["weather"], b["seed"])
        grid_equal = a["grid"] == b["grid"]
        if not grid_equal:
            issues.append(f"{a['track']}/{a['weather']}: starting grids differ")
        if a["violations"] or b["violations"]:
            issues.append(f"{a['track']}/{a['weather']}: invalid states")
        key = f"{a['track']}|{a['weather']}"
        baseline_progress = {str(x["id"]): x["progress"] for x in a["stages"]["18s"]["cars"]}
        new_progress = {str(x["id"]): x["progress"] for x in b["stages"]["18s"]["cars"]}
        deltas = [new_progress[id] - baseline_progress[id]
                  for id in sorted(baseline_progress)]
        if not all(math.isfinite(x) for x in deltas):
            issues.append(f"{key}: nonfinite progress delta")
        pairs.append({
            "track": a["track"], "weather": a["weather"],
            "same_initial_grid": grid_equal,
            "v99_pass_events": a["events"].get("pass", 0),
            "v917_pass_events": b["events"].get("pass", 0),
            "v99_moved_positions": a["changed_cars"],
            "v917_moved_positions": b["changed_cars"],
            "v99_position_changes": a["abs_position_changes"],
            "v917_position_changes": b["abs_position_changes"],
            "v99_unsafe_tick_samples": a["unsafe_tick_samples"],
            "v917_unsafe_tick_samples": b["unsafe_tick_samples"],
            "v99_stalled_car_ticks": a["no_forward_ticks"],
            "v917_stalled_car_ticks": b["no_forward_ticks"],
            "mean_progress_delta_laps": round(statistics.mean(deltas), 8),
            "mean_absolute_progress_delta_laps": round(statistics.mean(abs(x) for x in deltas), 8),
            "sporting_hashes_equal": a["hash"] == b["hash"]
        })
    if base["status"] != "PASS" or new["status"] != "PASS":
        issues.append("a version failed its own 24-car 18s scenarios")
    if any(not row["same_initial_grid"] for row in pairs):
        issues.append("grid mismatch prevents controlled A/B interpretation")
    totals = {}
    for prefix, origin in (("99", base), ("917", new)):
        totals[prefix] = {
            "pass_events": sum(x["events"].get("pass", 0) for x in origin["cases"]),
            "cars_changed_position": sum(x["changed_cars"] for x in origin["cases"]),
            "unsafe_tick_samples": sum(x["unsafe_tick_samples"] for x in origin["cases"]),
            "stalled_car_ticks": sum(x["no_forward_ticks"] for x in origin["cases"]),
        }
    for row in pairs:
        if row["v917_unsafe_tick_samples"] > row["v99_unsafe_tick_samples"]:
            checks.append(f"REVIEW {row['track']}/{row['weather']}: more schematic overlap observations")
        if row["v917_stalled_car_ticks"] > max(row["v99_stalled_car_ticks"] + 10, 30):
            checks.append(f"REVIEW {row['track']}/{row['weather']}: extra congestion stalls")
    result = {
        "status": "PASS" if not issues else "FAIL",
        "scope": "40 matched scenarios each version: 20 circuits x dry/heavy rain, 18s, 24 cars; 8 replayed cases each",
        "within_revision_determinism": base["repeat_failures"] == new["repeat_failures"] == 0,
        "baseline": totals["99"], "candidate": totals["917"],
        "notices": checks, "issues": issues, "cases": pairs,
        "caveat": "Sporting hashes may differ across 9.9/9.17 by design. Progress deltas are lap fractions, not measured metres or timing gaps."
    }
    write(directory / "start_comparison.json", result)
    md = [
        "# APEX v9.9 × v9.17 — 20 circuitos / 24 carros / Largada",
        "",
        "**" + result["status"] + "** — " + result["scope"],
        "",
        "| Indicador / 40 cenários | 9.9 | 9.17 |",
        "|---|---:|---:|",
    ]
    for key, text in (
        ("pass_events", "Eventos de passagem"),
        ("cars_changed_position", "Carros com mudança de posição"),
        ("unsafe_tick_samples", "Amostras de corredores sobrepostos (observação)"),
        ("stalled_car_ticks", "Carros×ticks parados após 2s")):
        md.append(f"| {text} | {totals['99'][key]} | {totals['917'][key]} |")
    md += ["", "| Pista | Clima | Mudança de posição 9.9 → 9.17 |"
           " Avanço médio 9.17−9.9 (fração de volta) | Sobreposições 9.9→9.17 |",
           "|---|---|---|---:|---|"]
    for row in pairs:
        md.append(f"| {row['track']} | {row['weather']} | "
                  f"{row['v99_position_changes']} → {row['v917_position_changes']} | "
                  f"{row['mean_progress_delta_laps']:+.6f} | "
                  f"{row['v99_unsafe_tick_samples']}→{row['v917_unsafe_tick_samples']} |")
    md += ["", "## Alertas para revisão"]
    md += ["- " + x for x in (checks + issues)] or ["- Nenhum alerta coletado."]
    md += ["", "**Limites:** números esquemáticos do Core 2, sem medição de FPS/GPU; "
           "uma diferença de hash entre revisões esportivas é esperada."]
    (directory / "start_comparison.md").write_text("\n".join(md)+"\n", encoding="utf-8")
    print("APEX_AB_START_COMPARISON", json.dumps({
        "status": result["status"], "totals": totals, "notices": len(checks),
        "issues": issues}, ensure_ascii=False))
    return 0 if not issues else 1

def run_scenarios(directory: Path):
    output = directory / "scenarios"
    outcome = {}
    for version in ("base", "candidate"):
        project = Path(version)
        cases = []
        for ti, track in enumerate(TRACKS):
            for wi, climate in enumerate(CLIMATES):
                for mi, mode in enumerate(MODES):
                    seed = 99661 + ti * 43 + wi * 7 + mi
                    case_id = f"ab_{track.lower()}_{wi}_{mi}_{seed}"
                    env = {"APEX_MATRIX_ID":case_id, "APEX_MATRIX_TRACK":track,
                           "APEX_MATRIX_WEATHER":climate,"APEX_MATRIX_MODE":mode,
                           "APEX_MATRIX_SEED":str(seed)}
                    log = output / f"{version}_{case_id}.log"
                    code, text, elapsed = invoke(project,
                        "res://tests/ci/apex_scenario_matrix_probe.gd",
                        f"{version}_{case_id}", log, env, timeout=180)
                    try:
                        record = marker(text, MARKERS["matrix"])
                    except ValueError as exc:
                        record = {"status":"NO_REPORT","errors":[str(exc)]}
                    entry = {"track":track,"weather":climate,"mode":mode,
                             "seed":seed,"exit":code,"wall_seconds":elapsed,
                             "report":record}
                    cases.append(entry)
                    print("AB_MATRIX_CASE", json.dumps({
                        "version":version, "case":case_id,
                        "exit":code,"result":record.get("status"),
                        "finished":record.get("finished"),
                        "pits":record.get("pits_total"),
                        "passes":record.get("on_track_pass_events"),
                        "errors":record.get("errors",[])}), flush=True)
        outcome[version] = cases
        write(output / f"matrix_{version}.json", cases)
    issues = []
    rows = []
    for a,b in zip(outcome["base"],outcome["candidate"]):
        key = f"{a['track']}/{a['weather']}/{a['mode']}"
        ar, br = a["report"],b["report"]
        if a["exit"] != 0 or b["exit"] != 0 or ar.get("status") != "PASS" or br.get("status") != "PASS":
            issues.append(key+" base="+str(ar.get("errors",[]))+" new="+str(br.get("errors",[])))
        rows.append({"track":a["track"],"weather":a["weather"],"mode":a["mode"],
             "seed":a["seed"],"v99_status":ar.get("status"),
             "v917_status":br.get("status"),
             "v99_pit_count":ar.get("pits_total"),
             "v917_pit_count":br.get("pits_total"),
             "v99_pass_events":ar.get("on_track_pass_events"),
             "v917_pass_events":br.get("on_track_pass_events"),
             "v99_manual_pits":ar.get("pit_laps_by_player"),
             "v917_manual_pits":br.get("pit_laps_by_player"),
             "v99_dq":ar.get("disqualified"),
             "v917_dq":br.get("disqualified"),
             "equal_hash":ar.get("race_hash")==br.get("race_hash"),
             "v99_steps":ar.get("steps"),
             "v917_steps":br.get("steps")})
    result = {"status":"PASS" if not issues else "FAIL",
              "scope":"5 circuits x 3 climates x manual/AI = 30 native 10-lap scenarios PER VERSION (60 GPs)",
              "issues":issues,"rows":rows}
    write(directory / "matrix_comparison.json",result)
    md = ["# APEX 9.9 × 9.17 — testes de 10 voltas",
          "", f"**{result['status']}** — {result['scope']}.",
          "", "| Circuito | Clima | BOX | 9.9 | 9.17 | Paradas 9.9→9.17 | Ultrapassagens 9.9→9.17 |",
          "|---|---|---|---|---|---|---|"]
    for row in rows:
        md.append(f"| {row['track']} | {row['weather']} | {row['mode']} | "
                  f"{row['v99_status']} | {row['v917_status']} | "
                  f"{row['v99_pit_count']}→{row['v917_pit_count']} | "
                  f"{row['v99_pass_events']}→{row['v917_pass_events']} |")
    md += ["", "## Falhas"]
    md += ["- "+ x for x in issues] if issues else ["- Nenhuma." ]
    (directory/"matrix_comparison.md").write_text("\n".join(md)+"\n", encoding="utf-8")
    print("APEX_AB_MATRIX_COMPARISON", json.dumps({"status":result["status"],
          "cases":len(rows),"failures":len(issues)},ensure_ascii=False))
    return 0 if not issues else 1

def run_full(directory: Path):
    output=directory/"full"
    data={}
    for version in ("base","candidate"):
        rows=[]
        for ti,track in enumerate(("GBR","ITA")):
            for wi,climate in enumerate(CLIMATES):
                seed=99700+ti*10+wi
                case=f"{track}_{wi}_{seed}"
                file=output/f"{version}_{case}.json"
                env={"APEX_TRACK":track,"APEX_WEATHER":climate,
                     "APEX_SEED":str(seed),"APEX_BENCH_OUTPUT":str(file.resolve())}
                code,text,elapsed=invoke(Path(version),
                  "res://tests/ci/apex_full_gp_endurance.gd",
                  f"full_{version}_{case}",output/f"{version}_{case}.log",
                  env,timeout=360)
                try:
                    result=read_json(file)
                    log_marker=marker(text,MARKERS["full"])
                    if bool(log_marker.get("finished"))!=bool(result.get("finished")):
                        raise ValueError("JSON/log finish mismatch")
                except (ValueError,OSError,KeyError) as exc:
                    result={"status":"NO_REPORT","error":str(exc)}
                row={"track":track,"weather":climate,"seed":seed,
                     "exit":code,"wall_seconds":elapsed,"report":result}
                rows.append(row)
                print("APEX_AB_FULL_CASE",json.dumps({"version":version,"track":track,
                      "weather":climate,"code":code,
                      "finished":result.get("finished"),"cars":result.get("finished_cars"),
                      "ticks":result.get("ticks"),"pit_history":result.get("pit_history")}),
                      flush=True)
        data[version]=rows
        write(output/f"full_{version}.json",rows)
    issues=[]
    compared=[]
    for a,b in zip(data["base"],data["candidate"]):
        r,s=a["report"],b["report"]
        key=f"{a['track']}/{a['weather']}"
        for record,side in ((a,"9.9"),(b,"9.17")):
            x=record["report"]
            if record["exit"]!=0 or x.get("finished") is not True or x.get("finished_cars")!=24 or x.get("manual_pit_orders")!=2:
                issues.append(key+" "+side+" incomplete full GP: "+str(x))
        compared.append({"track":a["track"],"weather":a["weather"],
            "v99_race_ticks":r.get("ticks"),"v917_race_ticks":s.get("ticks"),
            "v99_pit_history":r.get("pit_history"),"v917_pit_history":s.get("pit_history"),
            "v99_seconds_cpu":a["wall_seconds"],"v917_seconds_cpu":b["wall_seconds"],
            "v99_wet_range":[r.get("min_wetness"),r.get("max_wetness")],
            "v917_wet_range":[s.get("min_wetness"),s.get("max_wetness")],
            "same_sporting_hash":r.get("last_hash")==s.get("last_hash")})
    result={"status":"PASS" if not issues else "FAIL",
           "scope":"Silverstone/Monza 2012 full-distance x dry/variable/heavy rain x 2 versions = 12 full races",
           "issues":issues,"rows":compared,
           "limitation":"One seed per scenario; full GP stepping 4s, not rendered GPU FPS."}
    write(directory/"full_comparison.json",result)
    md=["# APEX 9.9 × 9.17 — Grande Prêmio completo",
        "",f"**{result['status']}** — {result['scope']}.",
        "","| Pista | Clima | Ticks 9.9→9.17 | BOX 9.9→9.17 | Tempo de execução 9.9→9.17 (s) |",
        "|---|---|---|---|---|"]
    for x in compared:
        md.append(f"| {x['track']} | {x['weather']} | {x['v99_race_ticks']}→{x['v917_race_ticks']} | "
                  f"{x['v99_pit_history']}→{x['v917_pit_history']} | "
                  f"{x['v99_seconds_cpu']:.1f}→{x['v917_seconds_cpu']:.1f} |")
    md+=["","## Falhas"]+ (["- "+x for x in issues] if issues else ["- Nenhuma."])
    (directory/"full_comparison.md").write_text("\n".join(md)+"\n",encoding="utf-8")
    print("APEX_AB_FULL_COMPARISON",json.dumps({"status":result["status"],"cases":len(compared),
          "failures":len(issues)},ensure_ascii=False))
    return 0 if not issues else 1

def run_visual(directory: Path):
    output=directory/"visual"
    data={}
    issues=[]
    for version in ("base","candidate"):
        code,text,elapsed=invoke(Path(version),
                  "res://tests/visual_stutter_06672_benchmark.gd",
                  f"visual_{version}",output/f"visual_{version}.log",
                  timeout=300)
        try: record=marker(text,MARKERS["visual"])
        except (ValueError,KeyError) as exc: record={"results":[],"failures":1,"error":str(exc)}
        data[version]={"exit":code,"wall_seconds":elapsed,"report":record}
        if code!=0 or record.get("failures")!=0:
            issues.append(f"{version}: visual stutter safety failed {record.get('failures')}")
    rows=[]
    base={x["code"]:x for x in data["base"]["report"]["results"]}
    new={x["code"]:x for x in data["candidate"]["report"]["results"]}
    for code in ("GBR","MON","BEL","SIN"):
        if code not in base or code not in new:
            issues.append(f"{code}: missing occupancy measurements")
            continue
        a,b=base[code],new[code]
        rows.append({"track":code,"v99":a,"v917":b,
                     "lag_regression":b["lag_count"]>a["lag_count"],
                     "new_collisions":b["collisions"]>a["collisions"],
                     "more_stalled":b["max_stationary"]>a["max_stationary"]})
    result={"status":"PASS" if not issues else "FAIL","issues":issues,"rows":rows,
            "scope":"24 cars, real 3D occupation of four circuits; 125 headless visual ticks per version",
            "limitation":"headless CPU path without GPU frame timing and without screenshot pixel equality"}
    write(directory/"visual_comparison.json",result)
    print("APEX_AB_VISUAL_COMPARISON",json.dumps({"status":result["status"],
          "issues":issues,"tracks":len(rows)},ensure_ascii=False))
    return 0 if not issues else 1

def run_bench(directory: Path):
    output=directory/"bench"
    rows=[]
    for sample in range(4):
        order=("base","candidate") if sample%2==0 else ("candidate","base")
        for version in order:
            code,text,elapsed=invoke(Path(version),
                  "res://tests/high_speed_growth_066723_benchmark.gd",
                  f"growth_{version}_{sample}",
                  output/f"{version}_{sample}.log",
                  {"APEX_TICKS":"1000"},timeout=240)
            try:
                report=marker(text,MARKERS["bench"])
                measurements=report["rows"]
                ms_per_tick=statistics.mean(x["ms_tick"] for x in measurements)
                if report.get("ticks")!=1000:
                    raise ValueError("wrong 1000 tick count")
            except (ValueError,KeyError,TypeError) as exc:
                report={"error":str(exc)}
                ms_per_tick=None
            rows.append({"version":version,"sample":sample,"exit":code,
                         "wall_seconds":elapsed,"average_ms_per_tick":ms_per_tick,
                         "hash":report.get("hash")})
            print("APEX_AB_BENCH_CASE",json.dumps(rows[-1]),flush=True)
    issues=[]
    durations={}
    for version in ("base","candidate"):
        bucket=[x["average_ms_per_tick"] for x in rows
                if x["version"]==version and x["exit"]==0
                and x["average_ms_per_tick"] is not None]
        if len(bucket)!=4:
            issues.append(f"{version}: incomplete benchmark repetitions")
        durations[version]=statistics.median(bucket) if bucket else None
        hashes={x["hash"] for x in rows if x["version"]==version}
        if len(hashes)!=1 or None in hashes:
            issues.append(f"{version}: hash drift across repeated identical seed runs")
    a,b=durations["base"],durations["candidate"]
    delta=round((b/a-1)*100,3) if a is not None and b is not None and a>0 else None
    result={"status":"PASS" if not issues else "FAIL",
           "rows":rows,"median_ms_tick":durations,"delta_pct_candidate_vs_base":delta,
           "issues":issues,
           "scope":"4 alternating repeats/version; Monza same 1000 replay ticks and seed, 1× simulation",
           "limitation":"headless CPU shared runner; changed sporting workload; not measured rendered FPS, 16×/32× UI"}
    write(directory/"benchmark_comparison.json",result)
    print("APEX_AB_BENCH_COMPARISON",json.dumps({"status":result["status"],
          "median_ms_tick":durations,"delta_percent":delta,"issues":issues}))
    return 0 if not issues else 1

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("mode",choices=("starts","scenarios","full","visual","bench"))
    parser.add_argument("--dir",type=Path,default=Path("ab-evidence"))
    args=parser.parse_args()
    args.dir.mkdir(parents=True,exist_ok=True)
    if args.mode=="starts": return summarize_starts(args.dir)
    if args.mode=="scenarios": return run_scenarios(args.dir)
    if args.mode=="full": return run_full(args.dir)
    if args.mode=="visual": return run_visual(args.dir)
    if args.mode=="bench": return run_bench(args.dir)
    return 2

if __name__=="__main__":
    raise SystemExit(main())
