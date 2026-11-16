#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${1:-}"
if [[ -z "$GODOT" ]]; then
  if command -v godot4 >/dev/null; then GODOT="$(command -v godot4)";
  elif command -v godot >/dev/null; then GODOT="$(command -v godot)";
  else echo 'Informe o caminho do Godot 4.7.2: bash linux/validar_0628_1.sh /caminho/Godot_v4.7.2-stable_linux.x86_64'; exit 1; fi
fi
"$GODOT" --headless --path . --editor --import --quit
for test in core_0628_1_visual_smoke_test core_0628_scenery_smoke_test core_0627_tv_director_smoke_test core_0626_1_freecam_smoke_test core_0625_dry_strategy_smoke_test; do
  "$GODOT" --headless --path . --script "res://tests/${test}.gd"
done
echo 'APEX v0.6.2.8.1 — validação nativa concluída.'
