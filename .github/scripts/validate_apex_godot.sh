#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$GITHUB_WORKSPACE/ci-logs"
cd "$GITHUB_WORKSPACE"

function report() {
  local title="$1" outcome="$2" detail="$3"
  echo "| $title | $outcome | $detail |" >> "$GITHUB_STEP_SUMMARY"
}

echo "### APEX v0.6.6.8 — validação nativa Godot 4.7.2" >> "$GITHUB_STEP_SUMMARY"
echo "" >> "$GITHUB_STEP_SUMMARY"
echo "| Etapa | Status | Observações |" >> "$GITHUB_STEP_SUMMARY"
echo "| --- | --- | --- |" >> "$GITHUB_STEP_SUMMARY"

failure_count=0

function attempt() {
  local title="$1"
  local timeout_s="$2"
  local file="$3"
  shift 3
  local status=0
  timeout --signal=TERM --kill-after=10s "$timeout_s"s "$@" > "$file" 2>&1 || status=$?
  tail -n 35 "$file" || true
  if [ "$status" -eq 0 ]; then
    report "$title" "PASS" "exit 0"
  else
    failure_count=$((failure_count+1))
    if [ "$status" -eq 124 ]; then
      report "$title" "INCONCLUSIVE" "timeout $timeout_s s"
    else
      report "$title" "FAIL" "exit $status"
    fi
    echo "::error::$title: exit $status. Veja ci-logs."
  fi
  return 0
}

./godot --version > ci-logs/godot-version.log 2>&1
version="$(cat ci-logs/godot-version.log)"
echo "Motor: $version"
if [[ "$version" != *"4.7.2"* ]]; then
  report "Motor Godot" "FAIL" "Versão errada"
  exit 1
fi
report "Motor Godot" "PASS" "$version"

attempt "Importação do editor" 240 ci-logs/editor-import.log \
  ./godot --headless --editor --path . --import --quit

if [ "$failure_count" -ne 0 ]; then
  echo "::error::Importação do editor falhou; testes dependentes não serão executados."
  exit 1
fi

while IFS='|' read -r name path timeout_s; do
  [ -n "$name" ] || continue
  safe="$(echo "$name" | tr ' /' '__')"
  attempt "$name" "$timeout_s" "ci-logs/$safe.log" \
    ./godot --headless --path . --script "$path"
done <<'ENDTESTS'
HUD_UNIT|res://tests/hud_rebroadcast_0668_unit.gd|90
HUD_SCENE_INTEGRATION|res://tests/hud_rebroadcast_0668_integration.gd|150
HUD_FOUR_TRACK_SMOKES|res://tests/hud_rebroadcast_0668_scenarios.gd|180
PITWALL_SAME_TICK|res://tests/pitwall_0667_same_tick_regression.gd|150
REPLAY_MANUAL_PIT_BOUNDARIES|res://tests/replay_0660_boundaries.gd|180
ENDTESTS

if [ "$failure_count" -gt 0 ]; then
  echo "::error::$failure_count etapa(s) falharam. Examine os logs."
  exit 1
fi
echo "Todos os testes selecionados terminaram com exit 0."
