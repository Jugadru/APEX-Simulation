#!/bin/sh
set -eu
PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BIN=${GODOT_BIN:-godot}
QA_DATA=$(mktemp -d)
trap 'rm -rf "$QA_DATA"' EXIT HUP INT TERM
export XDG_DATA_HOME="$QA_DATA"
"$BIN" --headless --path "$PROJECT_DIR" --editor --import --quit
for test in component_inventory_0651_test soul_staff_0650_model_test soul_staff_0650_migration_test strategy_simulator_06499_model_test pitwall_0649_strategy_test race_0646_engineer_3_test lap_strategy_06496_test team_pit_06497_unit_test team_pit_06497_integration_test core_0552_tyre_ai_smoke_test core_0643_dynamic_track_weather_test unified_hud_test management_hud04_test component_inventory_0651_ui soul_staff_0650_season_test component_inventory_0651_tracks; do
    mkdir -p "$QA_DATA/$test"
    XDG_DATA_HOME="$QA_DATA/$test" "$BIN" --headless --path "$PROJECT_DIR" --script "res://tests/$test.gd"
done
