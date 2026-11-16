#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo 'APEX 0.6.2.6 — camera, arquitetura e regressoes da estrategia'
python3 tests/test_0626_cameras_static.py
python3 tests/test_0612_indent_static.py
if command -v godot4 >/dev/null 2>&1; then
 GODOT=godot4
elif command -v godot >/dev/null 2>&1; then
 GODOT=godot
else
 echo 'Godot não encontrado: não é possível confirmar compilação e gráficos.'
 exit 0
fi
"$GODOT" --headless --path . --script res://tests/core_0624_load_smoke_test.gd
"$GODOT" --headless --path . --script res://tests/core_0626_camera_smoke_test.gd
"$GODOT" --headless --path . --script res://tests/core_0625_dry_strategy_smoke_test.gd
if [[ "${1:-}" == '--long' ]]; then
 "$GODOT" --headless --path . --script res://tests/core_0625_china_long_run.gd
fi
echo 'APEX v0.6.2.6 — testes terminados.'
