#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash linux/validar_0590_python.sh
GODOT_BIN="${GODOT_BIN:-godot}"
if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  printf '%s\n' 'Godot nao encontrado: verificacoes Python feitas; teste de runtime pendente.'
  exit 2
fi
"$GODOT_BIN" --headless --path . --editor --quit
"$GODOT_BIN" --headless --path . --script res://tests/core_0580_pit_and_geometry_smoke_test.gd
"$GODOT_BIN" --headless --path . --script res://tests/core_0590_team_control_smoke_test.gd
