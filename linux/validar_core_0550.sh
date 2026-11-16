#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-godot}"
if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "Godot não encontrado. Exemplo: GODOT_BIN=/caminho/Godot_v4.7.2-stable_linux.x86_64 bash linux/validar_core_0550.sh" >&2
  exit 1
fi
"$GODOT_BIN" --headless --path . --import --quit
"$GODOT_BIN" --headless --path . --script res://tests/core_0550_weather_smoke_test.gd
