#!/usr/bin/env bash
set -euo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_BIN:-godot}"
cd "$BASE"
python3 tests/test_0570_ai_strategy_static.py
python3 tests/test_0552_tyre_ai_static.py
python3 tests/test_0561_energy_balance.py
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "Godot nao encontrado. Configure GODOT_BIN=/caminho/Godot.AppImage"
  exit 2
fi
"$GODOT" --headless --path "$BASE" --editor --quit
"$GODOT" --headless --path "$BASE" --script res://tests/core_0570_ai_director_smoke_test.gd
"$GODOT" --headless --path "$BASE" --script res://tests/core_0552_tyre_ai_smoke_test.gd
"$GODOT" --headless --path "$BASE" --script res://tests/core_0561_energy_balance_test.gd
printf '%s\n' 'APEX v0.5.7.0 validacao concluida.'
echo 'Opcional (corrida longa):'
echo '"$GODOT" --headless --path "$BASE" --script res://tests/core_0570_long_strategy_run.gd'
