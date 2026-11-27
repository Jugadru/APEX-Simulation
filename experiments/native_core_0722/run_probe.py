"""Build/run the isolated prototype on a disposable hosted runner or local dev machine."""
import argparse
import hashlib
import json
import os
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


def run(args, cwd, log=None, timeout=1800, allow_import_crash=False):
    print("+", *map(str, args), flush=True)
    if log is None:
        subprocess.run(args, cwd=cwd, check=True, timeout=timeout)
        return ""
    result = subprocess.run(args, cwd=cwd, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=timeout)
    log.write_bytes(result.stdout)
    output = result.stdout.decode("utf-8", errors="replace")
    print(output, flush=True)
    if allow_import_crash and result.returncode in (-6, -11, 134, 139) and not any(s in output for s in ("SCRIPT ERROR:", "Parse Error:", "ERROR:")):
        return None  # bounded editor-only retry; runtime crashes always fail
    if result.returncode or any(s in output for s in ("SCRIPT ERROR:", "Parse Error:", "ERROR:")):
        raise RuntimeError(f"Godot probe failed: {log} (exit={result.returncode})")
    return output


def capture_editor_backtrace(command, project, work, evidence, label):
    # Diagnostic only. Never use a successful debugger run to override a failed gate.
    gdb = shutil.which("gdb")
    if not gdb:
        print("GDB unavailable; no backtrace collected", flush=True)
        return
    cache = project / ".godot"
    if cache.exists():
        shutil.rmtree(cache)
    # Reproduce the actual failing cold import with the same flags. Official
    # Godot may lack symbols; retain addresses and loaded libraries anyway.
    args = [gdb, "--batch", "-ex", "set pagination off",
            "-ex", "set debuginfod enabled off", "-ex", "run",
            "-ex", "thread apply all bt", "-ex", "info sharedlibrary",
            "--args", *command, "--disable-crash-handler"]
    path = evidence / (label + "-gdb.log")
    try:
        result = subprocess.run(args, cwd=work, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=150)
        path.write_bytes(result.stdout)
    except subprocess.TimeoutExpired as exc:
        path.write_bytes((exc.stdout or b"") + b"\nGDB diagnostic timed out\n")
    except OSError as exc:
        path.write_text(str(exc), encoding="utf-8")


def import_editor(godot, project, work, evidence, label):
    # Godot upstream #111048 / #111645: cold import may quit while deferred
    # extension documentation generation is still queued. Give the editor
    # thread time to finish, without changing runtime timing or its tests.
    command = [godot, "--headless", "--single-threaded-scene", "--verbose",
               "--path", str(project), "--import"]
    if label == "native":
        command += ["--frame-delay", "800"]
    try:
        result = run(command, work, evidence / (label + "-import-attempt1.log"), 240,
                     allow_import_crash=True)
        if result is None:
            print("Native editor abort; retrying once with a clean editor cache", flush=True)
            cache = project / ".godot"
            if cache.exists():
                shutil.rmtree(cache)
            run(command, work, evidence / (label + "-import-attempt2.log"), 240)
    except RuntimeError:
        # A repeat abort is a real failure. Collect a backtrace rather than
        # endlessly retrying or accepting a different result under the debugger.
        if sys.platform.startswith("linux") and label == "native":
            capture_editor_backtrace(command, project, work, evidence, label)
        raise
    if label == "native":
        listing = project / ".godot" / "extension_list.cfg"
        if not listing.is_file() or "res://phase.gdextension" not in listing.read_text(encoding="utf-8").splitlines():
            raise RuntimeError("editor did not discover the native extension")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--platform", choices=("linux", "windows"), required=True)
    p.add_argument("--godot", type=Path, help="Explicit Godot executable (console exe on Windows)")
    p.add_argument("--benchmark", action="store_true", help="Run 0723 bounded benchmark after 0722 gates")
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
    # setup-godot on Windows installs an extensionless symlink, which
    # CreateProcess cannot resolve by a bare executable name. Use the real
    # console executable from the official archive, including its .exe suffix.
    if args.godot:
        executable = args.godot.resolve()
    elif args.platform == "windows":
        installed = Path(os.environ["USERPROFILE"]) / "godot" / "Godot_v4.7.2-stable_win64_console.exe"
        configured = os.environ.get("GODOT")
        resolved = Path(configured).resolve() if configured else installed
        executable = installed if installed.is_file() else resolved
    else:
        configured = os.environ.get("GODOT") or shutil.which("godot")
        if not configured:
            raise FileNotFoundError("Godot executable not found; pass --godot")
        installed = Path.home() / "godot" / "Godot_v4.7.2-stable_linux.x86_64"
        executable = installed if installed.is_file() else Path(configured).resolve()
    if not executable.is_file() or (args.platform == "windows" and executable.suffix.lower() != ".exe"):
        raise FileNotFoundError(f"Godot executable not found: {executable}; pass --godot")
    godot = str(executable)
    print("Godot executable:", godot, flush=True)
    (evidence / "executable.txt").write_text(godot + "\n", encoding="utf-8")
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
    for name in ("phase.hpp", "extension.cpp", "SConstruct"):
        shutil.copyfile(here / name, work / name)
    if args.benchmark:
        shutil.copyfile(here.parent / "native_core_0723" / "pure.cpp", work / "pure.cpp")
    shutil.copyfile(here / "phase_probe.gd.in", project / "phase_probe.gd")
    (project / "project.godot").write_text(
        '[application]\nconfig/name="APEX Native 0722 isolated"\n'
        '[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding="utf-8")
    version = subprocess.check_output([godot, "--version"], cwd=work, text=True).strip()
    print("Godot:", version)
    if not version.startswith("4.7.2.stable") or "double" in version.lower():
        raise RuntimeError("expected standard Godot 4.7.2 stable")
    run([godot, "--headless", "--dump-extension-api"], work, evidence / "api.log", 120)
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
         "custom_api_file=" + (work / "extension_api.json").as_posix()], work,
        evidence / "build.log", 1800)
    filename = "libapex_phase.so" if args.platform == "linux" else "apex_phase.dll"
    if not (project / "bin" / filename).is_file():
        raise RuntimeError(f"missing expected binary {filename}")
    descriptor = project / "phase.gdextension"
    descriptor.write_text('[configuration]\nentry_symbol = "apex_phase_0722_init"\n'
        'compatibility_minimum = "4.7"\n\n[libraries]\n'
        f'{args.platform}.debug.x86_64 = "res://bin/{filename}"\n', encoding="utf-8")
    # Godot 4.7.2 GDExtensionManager::load_extensions reads this file at
    # startup. This isolated project has no imported assets. Exercise real
    # runtime loading and numerical oracles before the separate editor scan.
    cache = project / ".godot"
    cache.mkdir()
    (cache / "extension_list.cfg").write_text("res://phase.gdextension\n", encoding="utf-8")
    result = run([godot, "--headless", "--single-threaded-scene", "--path", str(project),
                  "--script", "res://phase_probe.gd"],
                 work, evidence / "native-probe.log", 180)
    if "APEX_NATIVE_0722_PASS" not in result:
        raise RuntimeError("native PASS marker missing")
    shutil.copyfile(project / "phase-fixtures.json", evidence / "phase-fixtures.json")
    saved_descriptor = descriptor.read_bytes()
    saved_bin = work / "native-bin-backup"
    shutil.copytree(project / "bin", saved_bin)
    descriptor.unlink()
    shutil.rmtree(project / "bin")
    shutil.rmtree(project / ".godot")
    result = run([godot, "--headless", "--single-threaded-scene", "--path", str(project), "--script",
                  "res://phase_probe.gd", "--", "--fallback-only"],
                 work, evidence / "fallback-probe.log", 180)
    if "APEX_NATIVE_0722_FALLBACK_PASS" not in result:
        raise RuntimeError("fallback PASS marker missing")
    # Keep both editor imports mandatory, even if the runtime probes pass.
    import_editor(godot, project, work, evidence, "fallback")
    if (project / ".godot").exists():
        shutil.rmtree(project / ".godot")
    shutil.copytree(saved_bin, project / "bin")
    descriptor.write_bytes(saved_descriptor)
    import_editor(godot, project, work, evidence, "native")
    # Prove the editor-generated extension list is usable, not just the
    # manually seeded runtime control. Require a second real numerical pass.
    result = run([godot, "--headless", "--single-threaded-scene", "--path", str(project),
                  "--script", "res://phase_probe.gd"],
                 work, evidence / "post-editor-native-probe.log", 180)
    if "APEX_NATIVE_0722_PASS" not in result:
        raise RuntimeError("post-editor native PASS marker missing")
    print("APEX_NATIVE_0722_HOSTED_PASS", flush=True)
    if args.benchmark:
        sys.path.insert(0, str(here.parent / "native_core_0723"))
        from benchmark import run as run_benchmark
        run_benchmark(godot, work, evidence, repo, args.platform)


if __name__ == "__main__":
    main()
