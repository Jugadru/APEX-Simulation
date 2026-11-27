"""Build/run the isolated prototype on a disposable hosted runner or local dev machine."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

PIN = "507ed9d840c01a3c5b2a39af8bb4000bfac30bf5"
REFERENCE = {
    "race_kers_2012.gd": "9222edc18a68186f630405a5816ddd576a1c55af",
    "race_tyre_thermal.gd": "6ccb1a1d3611d87bc16c0528f8ff22bc67ccc484",
    "race_fuel_mass_0701.gd": "775a7624536088a45b9c6e63d0f63e5de2973042",
    "race_tyre_grip_071.gd": "f46be7e85d8f63090e20e7feeb4c6533ba3e3ac8",
    "race_longitudinal_069.gd": "b6bd3d89a9b83e964774bd44de38162c37bbeeb5",
    "race_powertrain_070.gd": "9a8ee5ae836390b070a9259119c98a52e565171f",
    "race_vehicle_dynamics_072.gd": "696c81e0d16da2ff47e58c08754f4b8c802ddf5d",
}


def run(args, cwd, log=None, timeout=1800):
    print("+", *map(str, args), flush=True)
    if log is None:
        subprocess.run(args, cwd=cwd, check=True, timeout=timeout)
        return ""
    result = subprocess.run(args, cwd=cwd, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=timeout)
    log.write_bytes(result.stdout)
    output = result.stdout.decode("utf-8", errors="replace")
    print(output, flush=True)
    if result.returncode or any(s in output for s in ("SCRIPT ERROR:", "Parse Error:", "ERROR:")):
        raise RuntimeError(f"Godot probe failed: {log} (exit={result.returncode})")
    return output


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--platform", choices=("linux", "windows"), required=True)
    p.add_argument("--work", type=Path, required=True)
    p.add_argument("--evidence", type=Path, required=True)
    args = p.parse_args()
    here = Path(__file__).resolve().parent
    repo = here.parents[1]
    work, evidence = args.work.resolve(), args.evidence.resolve()
    if work == repo or repo in work.parents:
        raise ValueError("build directory must be outside the official project")
    work.mkdir(parents=True, exist_ok=False)
    evidence.mkdir(parents=True, exist_ok=True)
    project = work / "project"
    core = project / "scripts" / "core"
    core.mkdir(parents=True)
    (project / "bin").mkdir()
    for name, expected in REFERENCE.items():
        # git reads original blob bytes (Windows checkout may use CRLF).
        data = subprocess.check_output(["git", "show", "HEAD:scripts/core/" + name], cwd=repo)
        sha = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
        if sha != expected:
            raise ValueError(f"reference changed: {name} {sha}, re-audit required")
        (core / name).write_bytes(data)
    for name in ("phase.hpp", "extension.cpp", "SConstruct", "build_profile.json"):
        shutil.copyfile(here / name, work / name)
    shutil.copyfile(here / "phase_probe.gd.in", project / "phase_probe.gd")
    (project / "project.godot").write_text(
        '[application]\nconfig/name="APEX Native 0722 isolated"\n'
        '[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding="utf-8")
    version = subprocess.check_output(["godot", "--version"], cwd=work, text=True).strip()
    print("Godot:", version)
    if not version.startswith("4.7.2.stable") or "double" in version.lower():
        raise RuntimeError("expected standard Godot 4.7.2 stable")
    run(["godot", "--headless", "--dump-extension-api"], work, evidence / "api.log", 120)
    api = json.loads((work / "extension_api.json").read_text(encoding="utf-8"))
    header = api["header"]
    if (header["version_major"], header["version_minor"], header["version_patch"]) != (4, 7, 2):
        raise RuntimeError(f"wrong dumped API: {header}")
    (evidence / "identity.json").write_text(json.dumps({"godot": version, "api": header,
        "godot_cpp": PIN, "reference": REFERENCE, "platform": args.platform,
        "precision": "single", "target": "template_debug"}, indent=2), encoding="utf-8")
    dep = work / "godot-cpp"
    run(["git", "init", str(dep)], work)
    run(["git", "fetch", "--depth=1", "https://github.com/godotengine/godot-cpp.git", PIN], dep)
    run(["git", "checkout", "--detach", "FETCH_HEAD"], dep)
    if subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=dep, text=True).strip() != PIN:
        raise RuntimeError("godot-cpp SHA mismatch")
    run([sys.executable, "-m", "SCons", "-j4", "platform=" + args.platform,
         "arch=x86_64", "target=template_debug", "precision=single",
         "custom_api_file=" + (work / "extension_api.json").as_posix(),
         "build_profile=" + (work / "build_profile.json").as_posix()], work)
    filename = "libapex_phase.so" if args.platform == "linux" else "apex_phase.dll"
    if not (project / "bin" / filename).is_file():
        raise RuntimeError(f"missing expected binary {filename}")
    descriptor = project / "phase.gdextension"
    descriptor.write_text('[configuration]\nentry_symbol = "apex_phase_0722_init"\n'
        'compatibility_minimum = "4.7"\n\n[libraries]\n'
        f'{args.platform}.debug.x86_64 = "res://bin/{filename}"\n', encoding="utf-8")
    run(["godot", "--headless", "--path", str(project), "--import"], work,
        evidence / "native-import.log", 180)
    result = run(["godot", "--headless", "--path", str(project), "--script", "res://phase_probe.gd"],
                 work, evidence / "native-probe.log", 180)
    if "APEX_NATIVE_0722_PASS" not in result:
        raise RuntimeError("native PASS marker missing")
    shutil.copyfile(project / "phase-fixtures.json", evidence / "phase-fixtures.json")
    descriptor.unlink()
    shutil.rmtree(project / "bin")
    shutil.rmtree(project / ".godot")
    run(["godot", "--headless", "--path", str(project), "--import"], work,
        evidence / "fallback-import.log", 180)
    result = run(["godot", "--headless", "--path", str(project), "--script",
                  "res://phase_probe.gd", "--", "--fallback-only"],
                 work, evidence / "fallback-probe.log", 180)
    if "APEX_NATIVE_0722_FALLBACK_PASS" not in result:
        raise RuntimeError("fallback PASS marker missing")
    print("APEX_NATIVE_0722_HOSTED_PASS")


if __name__ == "__main__":
    main()
