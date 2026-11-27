"""Run predeclared bounded 0723 measurements on disposable copies, never the live game."""
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import statistics
import subprocess
import sys
import threading
import time
import tarfile
import psutil

COUNT=100800
MODES=("gdscript","scalar","batch1","batch24","batch48","batch240","pure_cpp")
BASE="2171247db6824331b714dc2588cda15b4b60a496"


def parse_rows(log, prefix):
    return [json.loads(line[len(prefix):]) for line in log.splitlines() if line.startswith(prefix)]


def percentile(values, q):
    ordered=sorted(values)
    return ordered[int((len(ordered)-1)*q)]


def stats(values):
    return {"mean":statistics.mean(values),"median":statistics.median(values),
            "p95":percentile(values,.95),"p99":percentile(values,.99),"max":max(values)}


def rss_bytes(pid):
    # Windows console wrapper spawns the real engine; observe descendants too.
    # Sum RSS/working sets (shared pages may be counted more than once).
    try:
        parent=psutil.Process(pid)
        processes=[parent,*parent.children(recursive=True)]
    except (psutil.NoSuchProcess,psutil.AccessDenied):
        return None
    values=[]
    for process in processes:
        try:
            values.append(process.memory_info().rss)
        except (psutil.NoSuchProcess,psutil.AccessDenied):
            pass
    return sum(values) if values else None


def measured_run(args, cwd, log, marker, timeout=300):
    print("+",*map(str,args),flush=True)
    rss=[]
    started=time.monotonic()
    with log.open("wb") as stream:
        child=subprocess.Popen(args,cwd=cwd,stdout=stream,stderr=subprocess.STDOUT)
        stop=threading.Event()
        def observe():
            while not stop.is_set():
                value=rss_bytes(child.pid)
                if value is not None:
                    rss.append({"elapsed_s":time.monotonic()-started,"bytes":value})
                stop.wait(.1)
        observer=threading.Thread(target=observe,daemon=True)
        observer.start()
        try:
            child.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            child.kill()
            child.wait()
            raise
        finally:
            stop.set()
            observer.join()
            log.with_suffix(".rss.json").write_text(json.dumps(rss),encoding="utf-8")
    text=log.read_text(encoding="utf-8",errors="replace")
    if child.returncode or marker not in text or any(x in text for x in ("SCRIPT ERROR:","Parse Error:","ERROR:","APEX_MICRO_FAIL","APEX_MACRO_FAIL")):
        print(text[-12000:],flush=True)
        raise RuntimeError(f"probe failed {log}: {child.returncode}")
    return text, max((v["bytes"] for v in rss),default=None)


def run(godot, work, evidence, repo, platform_name):
    here=Path(__file__).resolve().parent
    project=work/"project"
    bench=work/"pure_benchmark"
    if platform_name=="windows":
        bench=bench.with_suffix(".exe")
    if not bench.is_file():
        raise RuntimeError("missing standalone C++ benchmark")
    (project/"micro.gd").write_bytes((here/"micro.gd.in").read_bytes())
    fixture=json.loads((project/"phase-fixtures.json").read_text(encoding="utf-8"))
    inputs=work/"phase-input.txt"
    inputs.write_text("".join(" ".join(repr(float(v)) for v in row)+"\n" for row in fixture),encoding="utf-8")
    micro,micro_rss=measured_run([godot,"--headless","--single-threaded-scene","--path",str(project),"--script","res://micro.gd"],work,evidence/"micro.log","APEX_MICRO_PASS",600)
    pure,pure_rss=measured_run([str(bench),str(inputs)],work,evidence/"pure.log","APEX_PURE_PASS")
    rows=parse_rows(micro,"APEX_MICRO_ROW ")+parse_rows(pure,"APEX_MICRO_ROW ")
    expected={(m,rep) for m in MODES for rep in range(10)}
    if len(rows)!=70 or {(r["mode"],r["rep"]) for r in rows}!=expected or any(r["phases"]!=COUNT or r["elapsed_us"]<=0 for r in rows):
        raise RuntimeError("micro incomplete")
    if len({r["checksum"] for r in rows})!=1:
        raise RuntimeError("micro checksum mismatch across interfaces")
    micro_stats={m:stats([r["elapsed_us"]/COUNT for r in rows if r["mode"]==m]) for m in MODES}
    for m in MODES:
        micro_stats[m]["speedup_vs_gdscript"]=micro_stats["gdscript"]["median"]/micro_stats[m]["median"]
    # Use exact base source, not an instrumented baseline or the checkout's
    # editor cache. Extract only runtime resources to two disposable projects.
    archive=work/"runtime.tar"
    with archive.open("wb") as stream:
        subprocess.run(["git","archive",BASE,"project.godot","scripts","data","assets","scenes","addons","tests/fixtures"],cwd=repo,stdout=stream,check=True)
    baseline=work/"macro-baseline"
    candidate=work/"macro-candidate"
    baseline.mkdir()
    with tarfile.open(archive) as tf:
        tf.extractall(baseline,filter="data")
    # Keep user:// isolated from the official project even on local runs.
    cfg=baseline/"project.godot"
    text=cfg.read_text(encoding="utf-8")
    cfg.write_text(text.replace('config/custom_user_dir_name="APEX_0650_SOUL_STAFF"','config/custom_user_dir_name="APEX_0723_DISPOSABLE_BENCH"'),encoding="utf-8")
    shutil.copyfile(here/"macro.gd.in",baseline/"macro.gd")
    shutil.copytree(baseline,candidate)
    ccfg=candidate/"project.godot"
    ccfg.write_text(ccfg.read_text(encoding="utf-8").replace("APEX_0723_DISPOSABLE_BENCH","APEX_0723_DISPOSABLE_CANDIDATE"),encoding="utf-8")
    shutil.copytree(project/"bin",candidate/"bin")
    shutil.copyfile(project/"phase.gdextension",candidate/"phase.gdextension")
    # Exact one-function experimental substitution, only inside scratch tree.
    vehicle=candidate/"scripts/core/race_vehicle_dynamics_072.gd"
    original=vehicle.read_text(encoding="utf-8")
    if hashlib.sha1(b"blob "+str(len(vehicle.read_bytes())).encode()+b"\0"+vehicle.read_bytes()).hexdigest()!="696c81e0d16da2ff47e58c08754f4b8c802ddf5d":
        raise RuntimeError("unexpected baseline phase blob")
    start=original.index("static func phase(")
    end=original.index("\n## Shared 044",start)
    signature=original[start:original.index("\n",start)]
    patched=original[:start]+"static var _bench_backend: Object\n"+signature+"""
\tif _bench_backend == null:
\t\t_bench_backend = ClassDB.instantiate("ApexNativePhase0722")
\tvar result: Dictionary = _bench_backend.call("phase",start_mps,target_mps,dt_s,mass_kg,road_n,max_drive_n,max_brake_n)\n\tassert(result.size()==8,"native phase rejected in benchmark")\n\treturn result
"""+original[end:]
    vehicle.write_text(patched,encoding="utf-8")
    (evidence/"candidate-phase.gd.txt").write_text(patched,encoding="utf-8")
    # Real editor import outside measured sections: reuse the proven 0722
    # mitigation and verify the discovered extension before macro timing.
    from run_probe import import_editor
    macro_evidence=evidence/"macro-imports"
    macro_evidence.mkdir()
    import_editor(godot,baseline,work,macro_evidence,"macro-baseline")
    import_editor(godot,candidate,work,macro_evidence,"native")
    pairs=[]
    for rep in range(5):
        order=[("gdscript",baseline),("scalar",candidate)]
        if rep%2:
            order.reverse()
        results={}
        for mode,path in order:
            result,rss=measured_run([godot,"--headless","--single-threaded-scene","--path",str(path),"--script","res://macro.gd","--",mode,str(rep)],work,evidence/f"macro-{rep}-{mode}.log","APEX_MACRO_PASS",600)
            runs=parse_rows(result,"APEX_MACRO_ROW ")
            if len(runs)!=7 or any(len(r["samples_us"])!=500 or len(r["trace"])!=600 for r in runs):
                raise RuntimeError("macro incomplete")
            results[mode]=(runs,rss)
        aa,ar=results["gdscript"];bb,br=results["scalar"]
        for a,b in zip(aa,bb):
            if a["scenario"]!=b["scenario"] or a["revision"]!=b["revision"] or a["vehicle_samples"]!=b["vehicle_samples"]:
                raise RuntimeError("different workload")
            for tick,(x,y) in enumerate(zip(a["trace"],b["trace"]),1):
                if x!=y:
                    (evidence/"first-divergence.json").write_text(json.dumps({"scenario":a["scenario"],"rep":rep,"tick":tick,"baseline":x,"candidate":y}),encoding="utf-8")
                    raise RuntimeError("sporting divergence")
            pairs.append({"scenario":a["scenario"],"rep":rep,"baseline":stats(a["samples_us"]),
                "candidate":stats(b["samples_us"]),"baseline_total_us":sum(a["samples_us"]),
                "candidate_total_us":sum(b["samples_us"]),"baseline_static":a["peak_static_bytes"],
                "candidate_static":b["peak_static_bytes"],"baseline_process_peak_rss":ar,
                "candidate_process_peak_rss":br,"trace_equal":True})
    scenarios=[]
    for scenario in [p["scenario"] for p in pairs if p["rep"]==0]:
        group=[p for p in pairs if p["scenario"]==scenario]
        baseline_us=statistics.median(p["baseline_total_us"] for p in group)
        candidate_us=statistics.median(p["candidate_total_us"] for p in group)
        scenarios.append({"scenario":scenario,"baseline_total_median_us":baseline_us,
            "candidate_total_median_us":candidate_us,"reduction":1-candidate_us/baseline_us,
            "p99_ratio":statistics.median(p["candidate"]["p99"]/p["baseline"]["p99"] for p in group)})
    summary={"schema":1,"status":"MEASURED_BOUNDED","base":BASE,"candidate_checkout":subprocess.check_output(["git","rev-parse","HEAD"],cwd=repo,text=True).strip(),
        "platform":platform.platform(),"cpu":platform.processor(),"cpu_count":os.cpu_count(),
        "micro_rows":rows,"micro_us_per_phase":micro_stats,"micro_process_peak_rss":micro_rss,
        "pure_process_peak_rss":pure_rss,"macro_pairs":pairs,"macro_scenarios":scenarios,
        "limitations":"Hosted debug build, bounded 7 scenarios; RSS sampled per process (not per scenario), no GPU/FPS; no batch engine adapter, no full GP/save cross-load; no integration approval."}
    (evidence/"benchmark-summary.json").write_text(json.dumps(summary,indent=2),encoding="utf-8")
    print("APEX_BENCHMARK_0723_RESULT",json.dumps({"micro":micro_stats,"macro":scenarios}),flush=True)
    print("APEX_BENCHMARK_0723_PASS",flush=True)
