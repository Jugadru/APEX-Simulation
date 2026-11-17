#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo 'APEX 0.6.2.8 — Cenários / testes'
python3 tests/test_0628_scenery_static.py
python3 tests/test_0612_indent_static.py
if command -v godot4 >/dev/null 2>&1; then
  GODOT=godot4
elif command -v godot >/dev/null 2>&1; then
  GODOT=godot
else
  echo 'Godot não localizado; testes nativos não executados.'
  exit 0
fi
"$GODOT" --headless --path . --script res://tests/core_0628_scenery_smoke_test.gd
"$GODOT" --headless --path . --script res://tests/core_0627_tv_director_smoke_test.gd
"$GODOT" --headless --path . --script res://tests/core_0626_1_freecam_smoke_test.gd
"$GODOT" --headless --path . --script res://tests/core_0625_dry_strategy_smoke_test.gd
echo 'APEX 0.6.2.8 — validação nativa concluída.'
