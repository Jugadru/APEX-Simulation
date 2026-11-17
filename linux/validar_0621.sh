#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
echo '== APEX 0.6.2.1 | verificações Python =='
python3 tests/test_0621_module_hud_static.py
python3 tests/test_0612_indent_static.py
echo '== APEX 0.6.2.1 | verificações Godot =='
if command -v godot >/dev/null 2>&1; then
  GODOT=godot
elif command -v godot4 >/dev/null 2>&1; then
  GODOT=godot4
elif [[ -n "${GODOT_BIN:-}" && -x "${GODOT_BIN}" ]]; then
  GODOT="${GODOT_BIN}"
else
  echo 'ERRO: Godot 4 não encontrado. Defina GODOT_BIN=/caminho/para/Godot ou rode pelo editor.' >&2
  exit 2
fi
"$GODOT" --headless --path . --editor --quit
"$GODOT" --headless --path . --script res://tests/core_0621_hud_modular_smoke_test.gd
