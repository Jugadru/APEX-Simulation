#!/bin/sh
# Native Godot tests; isolated save data per process. Eight GPs use production step(0.20).
set -eu
PROJECT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BIN=${GODOT_BIN:-godot}
OUT=${APEX_QA_DIR:-"$PROJECT/qa/revalidation_0645"}
mkdir -p "$OUT"
RUNTIME=$(mktemp -d)
trap 'rm -rf "$RUNTIME"' EXIT HUP INT TERM
cd "$PROJECT"
"$BIN" --version
"$BIN" --headless --path "$PROJECT" --editor --import --quit > "$OUT/import.log" 2>&1
for test in race_0645_intelligence_test track_0644_unit_test track_0644_native_tick_smoke_test track_0644_hud_integration_test core_0638_1_timing_rootcause_test core_0643_dynamic_track_weather_test core_0642_rival_workshop_weather_test core_0642_save_migration_test core_0639_race_engineer_test core_0640_pitwall_intelligence_test core_0637_reactive_radio_smoke_test core_0636_soul_personality_smoke_test core_0634_radio_memory_smoke_test core_0590_team_control_smoke_test race_0645_eight_gp_test; do
 mkdir -p "$RUNTIME/$test"
 XDG_DATA_HOME="$RUNTIME/$test" timeout 14400 "$BIN" --headless --path "$PROJECT" --script "tests/$test.gd" > "$OUT/$test.log" 2>&1
 if grep -Eq 'SCRIPT ERROR|FAIL|ERROR:' "$OUT/$test.log"; then
  cat "$OUT/$test.log"
  exit 1
 fi
 echo "PASS $test"
done

# Also validate eight dependent career rounds with process restarts and saves.
GODOT_BIN="$BIN" APEX_CAREER_QA_DIR="$OUT/career_native_020" sh "$PROJECT/linux/validar_carreira_0645.sh"
