#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
GODOT_BIN=${GODOT_BIN:-godot}
for test in lap_strategy_06496_test lap_strategy_06496_auto_gate_test race_0645_intelligence_test pre_race_06495_planner_test pitwall_06494_confidence_test staff_0648_contracts_test race_0647_soul2_test core_0622_corner_hud_smoke_test double_stack_06492_entry_test; do
  "$GODOT_BIN" --headless --path "$ROOT" --script "res://tests/$test.gd"
done
echo "APEX 06496 TESTES CURTOS: PASS"
