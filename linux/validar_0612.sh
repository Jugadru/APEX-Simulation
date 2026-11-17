#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tests/test_0612_indent_static.py
GODOT_BIN="${GODOT_BIN:-$(command -v godot || command -v godot4 || true)}"
if [ -z "$GODOT_BIN" ]; then
  echo 'Godot não encontrado no PATH: rode os testes nativos com o executável instalado.'
  exit 2
fi
"$GODOT_BIN" --headless --path . --script res://tests/core_0612_load_smoke_test.gd
