#!/usr/bin/env python3
"""Static resource inventory: report duplicates, never automatically delete."""
import argparse, collections, hashlib, json, re, subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
EXCLUDED={"docs","qa","tests","tools","experimental","linux","APEX_06499_STRATEGY_SIMULATOR"}
RUNTIME={"scripts","scenes","assets","data"}
CODE={".gd",".tscn",".tres",".godot",".gdshader"}
REF=re.compile(r'res://([^"\'\s)\],;]+)')
CLASS=re.compile(r'(?m)^\s*class_name\s+(\w+)')
FUNC=re.compile(r'(?m)^(?:static\s+)?func\s+(\w+)\s*\(')

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check",action="store_true")
    ap.add_argument("--output",type=Path,default=Path("ci-results/source-inventory.json"))
    args=ap.parse_args()
    paths=[p.decode() for p in subprocess.check_output(["git","-C",str(ROOT),"ls-files","-z"]).split(b"\0") if p]
    hashes=collections.defaultdict(list); sizes={}; groups=collections.defaultdict(lambda:{"bytes":0,"files":0})
    refs={}; classes=collections.defaultdict(list); funcs=collections.defaultdict(list)
    for name in paths:
        path=ROOT/name
        if not path.is_file(): continue
        raw=path.read_bytes(); sizes[name]=len(raw)
        group=groups[name.split("/")[0]]
        group["bytes"]+=len(raw);group["files"]+=1
        if len(raw)>200: hashes[hashlib.sha256(raw).hexdigest()].append(name)
        if path.suffix not in CODE: continue
        source="\n".join(l for l in raw.decode("utf-8",errors="replace").splitlines() if not l.lstrip().startswith("#"))
        refs[name]=sorted(set(REF.findall(source)))
        if path.suffix==".gd" and name.startswith("scripts/"):
            for cls in CLASS.findall(source): classes[cls].append(name)
            matches=list(FUNC.finditer(source))
            for i,m in enumerate(matches):
                end=matches[i+1].start() if i+1<len(matches) else len(source)
                lines=[l.strip() for l in source[m.start():end].splitlines() if l.strip()]
                if len(lines)>=9:
                    funcs[(m.group(1),hashlib.sha256("\n".join(lines).encode()).hexdigest())].append(name)
    seen=set(); queue=["project.godot","scenes/main.tscn"]
    while queue:
        src=queue.pop()
        if src in seen: continue
        seen.add(src);queue.extend(p for p in refs.get(src,[]) if p in sizes and p not in seen)
    bad=[]; missing=[]
    for src,targets in refs.items():
        if src.split("/")[0] not in RUNTIME and src!="project.godot": continue
        for p in targets:
            if p.split("/")[0] in EXCLUDED: bad.append({"source":src,"target":p})
            if p not in sizes and Path(p).suffix and "%" not in p:
                missing.append({"source":src,"target":p})
    duplicates=[{"paths":p,"bytes_each":sizes[p[0]]} for p in hashes.values() if len(p)>1]
    duplicates.sort(key=lambda x:-x["bytes_each"]*(len(x["paths"])-1))
    repeated=[{"function":k[0],"files":sorted(set(p))} for k,p in funcs.items() if len(set(p))>1]
    duplicate_classes={k:v for k,v in classes.items() if len(v)>1}
    sidecars=[p for p in sizes if p.endswith(".translation") or p.endswith(".csv.import")]
    report={"file_count":len(sizes),"groups":dict(groups),"duplicate_groups":duplicates,
        "duplicate_bytes":sum((len(x["paths"])-1)*x["bytes_each"] for x in duplicates),
        "duplicate_runtime_classes":duplicate_classes,"identical_runtime_function_blocks":repeated,
        "report_translation_sidecars":sidecars,"excluded_runtime_references":bad,"unresolved_literal_references":missing,
        "runtime_scripts_not_reached_by_literal_graph":sorted(p for p in sizes if p.startswith("scripts/") and p.endswith(".gd") and p not in seen),
        "limitations":["Static literal graph only; dynamic paths, signals and semantically equivalent functions require manual review.","Duplicate fixtures may be intentional. No deletion."]}
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print("APEX_SOURCE_INVENTORY",json.dumps({"files":len(sizes),"duplicate_groups":len(duplicates),"duplicate_bytes":report["duplicate_bytes"],"report_sidecars":len(sidecars),"identical_function_blocks":len(repeated),"excluded_runtime_refs":bad,"duplicate_classes":duplicate_classes}))
    print("APEX_SOURCE_DETAILS",json.dumps({"identical_runtime_function_blocks":repeated,"unresolved_literal_references":missing,"runtime_scripts_not_reached_by_literal_graph":report["runtime_scripts_not_reached_by_literal_graph"]}))
    return 1 if args.check and (bad or duplicate_classes) else 0

if __name__=="__main__": raise SystemExit(main())
