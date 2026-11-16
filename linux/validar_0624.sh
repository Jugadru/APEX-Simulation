#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

printf '\nAPEX 0.6.2.4 — testes estáticos da refatoração\n'
python3 tests/test_0624_refactor_static.py
python3 tests/test_0612_indent_static.py

GODOT_EXE="${GODOT_BIN:-}"
if [[ -z "$GODOT_EXE" ]]; then
  GODOT_EXE="$(command -v godot || command -v godot4 || true)"
fi
if [[ -z "$GODOT_EXE" ]]; then
  printf '\nGodot não encontrado: executar manualmente pelo editor 4.7.2.\n'
  exit 0
fi
printf '\nAPEX: validação GDScript com %s\n' "$GODOT_EXE"
"$GODOT_EXE" --headless --path . --editor --import --quit
"$GODOT_EXE" --headless --path . --script res://tests/core_0624_load_smoke_test.gd
printf '\nAbrir o projeto com F5 para testar cliques, câmeras, corrida e interface.\n'
