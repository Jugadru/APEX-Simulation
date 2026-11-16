#!/usr/bin/env bash
set -euo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_BIN:-godot}"
cd "$BASE"
python3 tests/verify_project.py
python3 tests/test_0543_static.py
python3 tests/test_0561_energy_balance.py
python3 tests/test_0580_static.py
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo 'VALIDAÇÃO PARCIAL: testes Python OK, mas Godot não encontrado.' >&2
  echo 'Configure GODOT_BIN=/caminho/para/godot e execute novamente.' >&2
  exit 2
fi
"$GODOT" --headless --path "$BASE" --editor --quit
"$GODOT" --headless --path "$BASE" --script res://tests/core_0543_combat_smoke_test.gd
"$GODOT" --headless --path "$BASE" --script res://tests/core_0570_ai_director_smoke_test.gd
"$GODOT" --headless --path "$BASE" --script res://tests/core_0580_pit_and_geometry_smoke_test.gd
printf '%s\n' 'APEX 0.5.8.0: testes estáticos e headless concluídos.'
