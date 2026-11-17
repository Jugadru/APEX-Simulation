#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/.."
python3 tests/test_0622_hud_layout.py
if command -v godot >/dev/null 2>&1; then G=godot
elif command -v godot4 >/dev/null 2>&1; then G=godot4
else
  echo 'Godot não encontrado neste computador. Execute o projeto manualmente no Godot 4.x.'
  exit 2
fi
"$G" --headless --path . --script res://tests/core_0622_corner_hud_smoke_test.gd
