#!/usr/bin/env bash
# Offline fallback for the 13th APEX QA improvement.
# Run from any directory: bash tools/run_pitwall_local.sh
# Does not modify the sporting engine, player saves, or GitHub metadata.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
if [[ ! -f project.godot || ! -f data/season_2012.json ]]; then
  echo "APEX_PITWALL_LOCAL_FAIL: execute from a full APEX repository checkout" >&2
  exit 2
fi

godot_bin="${GODOT_BIN:-godot}"
if ! command -v "$godot_bin" >/dev/null 2>&1 && [[ ! -x "$godot_bin" ]]; then
  echo "APEX_PITWALL_LOCAL_FAIL: Godot not found. Set GODOT_BIN=/absolute/path/to/Godot" >&2
  exit 2
fi
version="$("$godot_bin" --version)"
if [[ "$version" != *"4.7.2"* ]]; then
  echo "APEX_PITWALL_LOCAL_FAIL: requires Godot 4.7.2; found '$version'" >&2
  exit 2
fi
command -v python3 >/dev/null || { echo "Python 3 unavailable" >&2; exit 2; }
command -v timeout >/dev/null || { echo "GNU timeout unavailable" >&2; exit 2; }

out="${APEX_PITWALL_OUTPUT:-ci_artifacts/pitwall_intelligence_local}"
mkdir -p -- "$out"
out="$(cd -- "$out" && pwd)"
session="$(mktemp -d "${TMPDIR:-/tmp}/apex-pitwall-v13.XXXXXXXX")"
trap 'rm -rf -- "$session"' EXIT

echo "APEX_PITWALL_LOCAL_SETUP version=$version"
python3 -m unittest discover -s tools/tests -p test_apex_pitwall_intelligence.py -v

if ! timeout 240s "$godot_bin" --headless --path . --import > "$out/import.log" 2>&1; then
  cat "$out/import.log" >&2
  echo "APEX_PITWALL_LOCAL_FAIL: real Godot project import did not complete" >&2
  exit 1
fi
if grep -Eiq '(^ERROR:|SCRIPT ERROR:|Parse Error:)' "$out/import.log"; then
  cat "$out/import.log" >&2
  echo "APEX_PITWALL_LOCAL_FAIL: script/import error" >&2
  exit 1
fi

for scenario in ita_dry_auto gbr_wet_auto bra_variable_auto ita_manual_v7; do
  for repetition in 1 2; do
    label="${scenario}_${repetition}"
    home="$session/$label"
    mkdir -p -- "$home/data" "$home/config" "$home/cache"
    echo "APEX_PITWALL_LOCAL_START $label"
    if ! env HOME="$home" XDG_DATA_HOME="$home/data" \
      XDG_CONFIG_HOME="$home/config" XDG_CACHE_HOME="$home/cache" \
      APEX_PITWALL_SCENARIO="$scenario" \
      timeout 180s "$godot_bin" --headless --path . \
        --script res://tests/ci/apex_pitwall_intelligence_probe.gd \
        > "$out/$label.log" 2>&1; then
      tail -n 80 "$out/$label.log" >&2
      echo "APEX_PITWALL_LOCAL_FAIL: $label did not complete" >&2
      exit 1
    fi
  done
done

python3 tools/apex_pitwall_intelligence.py --project . --output "$out"
echo "APEX_PITWALL_LOCAL_PASS eight runs, with verifiable logs in $out"
