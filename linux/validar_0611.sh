#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tests/test_0611_static.py
if command -v godot >/dev/null 2>&1; then
 godot --headless --path . --script res://tests/core_0611_map_weather_smoke_test.gd
elif command -v godot4 >/dev/null 2>&1; then
 godot4 --headless --path . --script res://tests/core_0611_map_weather_smoke_test.gd
else
 echo 'Godot nao disponivel: smoke GDScript pendente.'
fi
