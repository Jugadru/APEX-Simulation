#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-}"
if [ -z "$GODOT_BIN" ]; then
  if command -v godot >/dev/null 2>&1; then GODOT_BIN=godot
  elif command -v godot4 >/dev/null 2>&1; then GODOT_BIN=godot4
  else echo 'Godot 4 não encontrado. Defina GODOT_BIN=/caminho/para/o/executavel.' >&2; exit 2
  fi
fi
printf '%s\n' '1/3 Testes estáticos de modularização'
python3 tests/test_0623_modularization_static.py
printf '%s\n' '2/3 Parser e carregamento real no Godot'
"$GODOT_BIN" --headless --path . --script res://tests/core_0623_load_smoke_test.gd
printf '%s\n' '3/3 Abrindo cena principal em modo headless por 8 quadros'
"$GODOT_BIN" --headless --path . --quit-after 8
printf '%s\n' 'APEX 0.6.2.3: verificações de inicialização concluídas.'
