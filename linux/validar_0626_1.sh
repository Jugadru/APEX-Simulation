#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo 'APEX 0.6.2.6.1 — free camera input hotfix'
python3 tests/test_0626_1_freecam_static.py
python3 tests/test_0612_indent_static.py
if command -v godot4 >/dev/null 2>&1; then
 GODOT=godot4
elif command -v godot >/dev/null 2>&1; then
 GODOT=godot
else
 echo 'Godot não encontrado: sem compilação/execução de câmera neste ambiente.'
 exit 0
fi
"$GODOT" --headless --path . --script res://tests/core_0626_1_freecam_smoke_test.gd
"$GODOT" --headless --path . --script res://tests/core_0626_camera_smoke_test.gd
"$GODOT" --headless --path . --script res://tests/core_0625_dry_strategy_smoke_test.gd
echo 'APEX 0.6.2.6.1 — smoke tests executados.'
