#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tests/test_0612_indent_static.py
python3 tests/test_0620_hud_static.py
if command -v godot >/dev/null 2>&1; then
    godot --headless --path . --script res://tests/core_0620_hud_smoke_test.gd
elif command -v godot4 >/dev/null 2>&1; then
    godot4 --headless --path . --script res://tests/core_0620_hud_smoke_test.gd
else
    echo "ATENÇÃO: Godot 4 não encontrado no PATH; valide no editor (F5)."
fi
