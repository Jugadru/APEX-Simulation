#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo 'APEX v0.6.2.5 — verificações estáticas'
python3 tests/test_0625_dry_strategy_static.py
python3 tests/test_0612_indent_static.py
if command -v godot >/dev/null 2>&1; then
 GODOT=godot
elif command -v godot4 >/dev/null 2>&1; then
 GODOT=godot4
else
 echo 'Godot não encontrado. Testes nativos não executados.'
 exit 0
fi
echo 'Validando scripts e cenário principal no Godot...'
"$GODOT" --headless --path . --script res://tests/core_0624_load_smoke_test.gd
"$GODOT" --headless --path . --script res://tests/core_0625_dry_strategy_smoke_test.gd
if [[ "${1:-}" == '--long' ]]; then
 echo 'Corrida completa China no Godot...'
 "$GODOT" --headless --path . --script res://tests/core_0625_china_long_run.gd
fi
echo 'Validação concluída.'
