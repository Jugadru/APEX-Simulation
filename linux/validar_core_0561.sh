#!/usr/bin/env bash
set -euo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_BIN:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "Godot nao encontrado. Configure GODOT_BIN=/caminho/Godot.AppImage"
  exit 2
fi
cd "$BASE"
python3 tests/test_0561_energy_balance.py
"$GODOT" --headless --path "$BASE" --editor --quit
"$GODOT" --headless --path "$BASE" --script res://tests/core_0561_energy_balance_test.gd
"$GODOT" --headless --path "$BASE" --script res://tests/core_0560_kers_drs_smoke_test.gd
printf '%s\n' 'APEX v0.5.6.1 validacao concluida.'
