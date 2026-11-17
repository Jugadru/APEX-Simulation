#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tests/test_0629_preserved_static.py
if [[ -n "${GODOT_BIN:-}" ]]; then
  godot_bin="$GODOT_BIN"
elif command -v godot >/dev/null 2>&1; then
  godot_bin="$(command -v godot)"
elif command -v godot4 >/dev/null 2>&1; then
  godot_bin="$(command -v godot4)"
else
  echo 'Godot nao encontrado; defina GODOT_BIN=/caminho/para/Godot_v4.7.2-stable_linux.x86_64' >&2
  exit 1
fi
for t in core_0629_environment_smoke_test core_0629_calendar_smoke_test core_0628_1_visual_smoke_test core_0628_scenery_smoke_test core_0627_tv_director_smoke_test core_0626_1_freecam_smoke_test core_0625_dry_strategy_smoke_test; do
  echo "[TESTE] $t"
  "$godot_bin" --headless --path . --script "res://tests/$t.gd"
done
