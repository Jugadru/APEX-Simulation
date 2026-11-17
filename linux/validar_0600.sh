#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
python3 tests/run_all_static.py
if command -v godot >/dev/null 2>&1; then
    GODOT=godot
elif command -v godot4 >/dev/null 2>&1; then
    GODOT=godot4
elif [ -n "${GODOT_BIN:-}" ] && [ -x "${GODOT_BIN}" ]; then
    GODOT=${GODOT_BIN}
else
    echo 'Godot ausente: testes GDScript não executados. Configure GODOT_BIN=/caminho/para/Godot'
    exit 2
fi
"$GODOT" --headless --path . --editor --quit
"$GODOT" --headless --path . --script res://tests/core_0600_championship_smoke_test.gd
