#!/usr/bin/env bash
set -euo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_BIN:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "Godot nao encontrado: defina GODOT_BIN=/caminho/do/Godot.AppImage ou instale o Godot no PATH"
  exit 2
fi
cd "$BASE"
python3 tests/test_0552_tyre_ai_static.py
"$GODOT" --headless --path "$BASE" --editor --quit
"$GODOT" --headless --path "$BASE" --script res://tests/core_0552_tyre_ai_smoke_test.gd
if [[ "${1:-}" == "--long" ]]; then
  "$GODOT" --headless --path "$BASE" --script res://tests/core_0552_long_rain_run.gd
fi
echo 'APEX 0.5.5.2: validacao concluida.' 
