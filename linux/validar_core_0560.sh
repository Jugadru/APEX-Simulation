#!/usr/bin/env bash
set -euo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_BIN:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "Godot nao encontrado. Defina GODOT_BIN=/caminho/para/Godot.AppImage ou instale-o no PATH."
  exit 2
fi
cd "$BASE"
python3 tests/test_0560_kers_drs_static.py
"$GODOT" --headless --path "$BASE" --editor --quit
"$GODOT" --headless --path "$BASE" --script res://tests/core_0560_kers_drs_smoke_test.gd
if [[ "${1:-}" == "--long" ]]; then
  "$GODOT" --headless --path "$BASE" --script res://tests/core_0552_long_rain_run.gd
fi
echo "APEX v0.5.6.0: validacao concluida"
