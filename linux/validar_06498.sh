#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
export GODOT_SILENCE_ROOT_WARNING=1
"$GODOT" --headless --editor --path . --quit
"$GODOT" --headless --path . --script res://tests/dynamic_strategy_06498_data_test.gd
"$GODOT" --headless --path . --script res://tests/team_pit_06497_unit_test.gd
"$GODOT" --headless --path . --script res://tests/lap_strategy_06496_auto_gate_test.gd
"$GODOT" --headless --path . --script res://tests/pitwall_0649_strategy_test.gd
"$GODOT" --headless --path . --script res://tests/race_0646_engineer_3_test.gd
"$GODOT" --headless --path . --script res://tests/pre_race_06495_planner_test.gd
printf '%s\n' 'Testes lógicos concluídos. Teste visual requer Xvfb/driver de vídeo:'
printf '%s\n' 'xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --path . --script res://tests/dynamic_strategy_06498_ui_test.gd'
