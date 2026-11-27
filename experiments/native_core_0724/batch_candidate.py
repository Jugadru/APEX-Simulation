
"""Build the 0724 candidate only in a disposable 0723 benchmark project."""
import shutil
import hashlib
from pathlib import Path

VEHICLE="scripts/core/race_vehicle_dynamics_072.gd"
SPACE="scripts/core/race_space_0655.gd"
VEHICLE_PIN="696c81e0d16da2ff47e58c08754f4b8c802ddf5d"
SPACE_PIN="d1427138fda7c610a31970d38e806f1dc471df6f"
HERE=Path(__file__).resolve().parent


def blob(data):
    return hashlib.sha1(b"blob "+str(len(data)).encode("ascii")+b"\0"+data).hexdigest()


def replace_once(text, before, after):
    if text.count(before)!=1:
        raise RuntimeError("0724 anchor missing or ambiguous: "+before[:120])
    return text.replace(before,after,1)


def patch_space(text):
    text=replace_once(text,"\t# Hold lateral occupancy through overlap, including a recently passed car.","\tvar batch_jobs: Array = []\n\t# Hold lateral occupancy through overlap, including a recently passed car.")
    text=replace_once(text,"\t\t\t\tphysical=Vehicle072.propose(c,curve,float(a.pace),lap_km*1000.0,float(a.driving_dt),weather)","\t\t\t\tbatch_jobs.append({\"id\":id,\"car\":c,\"curve\":curve,\"pace\":float(a.pace),\"dt\":float(a.driving_dt),\"progress\":own_progress})\n\t\t\t\tcontinue")
    return replace_once(text,"\t# Before entering a single corridor, the trailing side yields gradually.","\tif not batch_jobs.is_empty():\n\t\tvar proposals: Array = Vehicle072.propose_batch(batch_jobs,lap_km*1000.0,weather)\n\t\tassert(proposals.size()==batch_jobs.size(),\"0724 incomplete physical batch\")\n\t\tfor index in range(batch_jobs.size()):\n\t\t\tvar job: Dictionary = batch_jobs[index]\n\t\t\tvar intent: Dictionary = intents[int(job.id)]\n\t\t\tvar proposal: Dictionary = proposals[index]\n\t\t\tintent.next=float(job.progress)+float(proposal.distance_m)/(lap_km*1000.0)\n\t\t\tintent[Longitudinal069.KEY]=proposal\n\t# Before entering a single corridor, the trailing side yields gradually.")


def patch_macro(text):
    text=replace_once(text,'(mode == "scalar")','(mode == "batch")')
    text=replace_once(text,'    for spec in CASES:\n','    for spec in CASES:\n        V.batch_reset()\n')
    text=replace_once(text,'        var seek_ok: bool = true\n',"""        var batch: Dictionary = V.batch_stats()
        if spec[3]=="045":
            if int(batch.groups)<=0 or int(batch.calls)!=2*int(batch.groups) or int(batch.max_group)<=1 or int(batch.max_group)>24 or int(batch.cars)<=int(batch.groups):
                fail("native batch coverage")
                return
        elif int(batch.groups)!=0 or int(batch.calls)!=0 or int(batch.cars)!=0:
            fail("legacy revision called batch")
            return
        var seek_ok: bool = true
""")
    return replace_once(text,'"seek_ok":seek_ok}', '"seek_ok":seek_ok,"batch_stats":batch}')


def prepare(baseline, native_project, work, evidence):
    target=work/"macro-batch"
    shutil.copytree(baseline,target)
    for rel,pin in ((VEHICLE,VEHICLE_PIN),(SPACE,SPACE_PIN)):
        data=(target/rel).read_bytes()
        if blob(data)!=pin:
            raise RuntimeError(f"0724 source pin mismatch {rel}: {blob(data)} != {pin}")
    vehicle=target/VEHICLE
    original=vehicle.read_bytes()
    extra=(HERE/"vehicle_batch.gd.in").read_bytes()
    vehicle.write_bytes(original+b"\n"+extra)
    space=target/SPACE
    space.write_bytes(patch_space(space.read_bytes().decode("utf-8")).encode("utf-8"))
    macro=target/"macro.gd"
    macro.write_bytes(patch_macro(macro.read_text(encoding="utf-8")).encode("utf-8"))
    cfg=target/"project.godot"
    cfg.write_bytes(replace_once(cfg.read_text(encoding="utf-8"),"APEX_0723_DISPOSABLE_BENCH","APEX_0724_DISPOSABLE_BATCH").encode("utf-8"))
    shutil.copytree(native_project/"bin",target/"bin")
    shutil.copyfile(native_project/"phase.gdextension",target/"phase.gdextension")
    for rel,name in ((VEHICLE,"batch-vehicle.gd.txt"),(SPACE,"batch-space.gd.txt"),("macro.gd","batch-macro.gd.txt")):
        shutil.copyfile(target/rel,evidence/name)
    return target
