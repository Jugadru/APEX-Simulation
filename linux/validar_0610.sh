#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tests/run_all_static.py
python3 tests/test_0610_static.py
if command -v godot >/dev/null 2>&1; then
  godot --headless --path . --script res://tests/core_0610_weather_and_speed_test.gd
elif command -v godot4 >/dev/null 2>&1; then
  godot4 --headless --path . --script res://tests/core_0610_weather_and_speed_test.gd
else
  echo 'AVISO: Godot nao encontrado; teste GDScript nao executado.'
fi
