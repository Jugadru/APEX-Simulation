#!/usr/bin/env bash
# APEX 13th improvement — independent offline Core 2 and contract regressions.
# Run from the complete PR #46 checkout:
#   GODOT_BIN="$HOME/Downloads/Godot_v4.7.2-stable_linux.x86_64" bash tools/run_pitwall_regressions_local.sh
# This is NOT a replacement for GdUnit4, GitHub Quality Gate, CodeQL or A/B baseline CI.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
if [[ ! -f project.godot || ! -f scripts/race_engine.gd ]]; then
  echo "APEX_13_REGRESSIONS_FAIL missing complete APEX project" >&2
  exit 2
fi

godot_bin="${GODOT_BIN:-godot}"
if ! command -v "$godot_bin" >/dev/null 2>&1 && [[ ! -x "$godot_bin" ]]; then
  echo "APEX_13_REGRESSIONS_FAIL Godot binary unavailable; set GODOT_BIN" >&2
  exit 2
fi
version="$("$godot_bin" --version)"
if [[ "$version" != *"4.7.2"* ]]; then
  echo "APEX_13_REGRESSIONS_FAIL expected Godot 4.7.2, found $version" >&2
  exit 2
fi
command -v python3 >/dev/null || { echo "APEX_13_REGRESSIONS_FAIL missing python3" >&2; exit 2; }
command -v timeout >/dev/null || { echo "APEX_13_REGRESSIONS_FAIL missing GNU timeout" >&2; exit 2; }

output="${APEX_13_REGRESSION_OUTPUT:-ci_artifacts/pitwall_regressions_local}"
mkdir -p -- "$output"
output="$(cd -- "$output" && pwd)"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/apex-13-regressions.XXXXXXXX")"
trap 'rm -rf -- "$scratch"' EXIT

report="$output/report.md"
printf '# APEX 13ª melhoria — regressões locais\n\n' > "$report"
printf 'Godot: %s\n\n' "$version" >> "$report"
printf '| Verificação | Resultado |\n|---|---|\n' >> "$report"
echo "APEX_13_REGRESSIONS_START Godot=$version"
ok_count=0

fail() {
  echo "APEX_13_REGRESSIONS_FAIL $1" >&2
  printf '| %s | FAIL |\n' "$1" >> "$report"
  printf '\n**INCOMPLETO** — consulte os logs. Nenhum merge foi autorizado.\n' >> "$report"
  exit 1
}

# These are the real stand-alone unit contracts from the PR workflows.
contracts=(
  test_apex_pitwall_intelligence.py
  test_apex_quality_gate.py
  test_compare_apex_benchmarks.py
  test_apex_scenario_matrix.py
  test_security_bandit_report.py
  test_gdscript_style_audit.py
)
for test_file in "${contracts[@]}"; do
  [[ -s "tools/tests/$test_file" ]] || fail "Contrato ausente $test_file"
  log="$output/${test_file%.py}.log"
  echo "APEX_13_REGRESSION_START $test_file"
  if ! python3 -m unittest discover -s tools/tests -p "$test_file" -v > "$log" 2>&1; then
    tail -n 60 "$log" >&2
    fail "$test_file"
  fi
  grep -Fxq 'OK' "$log" || fail "$test_file (ausência do OK)"
  printf '| Contrato Python %s | PASS |\n' "$test_file" >> "$report"
  ok_count=$((ok_count+1))
done

echo "APEX_13_REGRESSION_START Godot import"
if ! timeout 240s "$godot_bin" --headless --single-threaded-scene --path . --import > "$output/import.log" 2>&1; then
  tail -n 80 "$output/import.log" >&2
  fail "Godot import"
fi
if grep -Eiq '(^ERROR:|SCRIPT ERROR:|Parse Error:)' "$output/import.log"; then
  tail -n 80 "$output/import.log" >&2
  fail "Godot import (erros de parser)"
fi
printf '| Godot 4.7.2 import | PASS |\n' >> "$report"
ok_count=$((ok_count+1))

# Mirror the EXACT script/marker contracts from .github/workflows/godot-setup.yml.
core2=(
  'team_orders_066810_test.gd|TEAM_ORDERS_066810_PASS'
  'team_orders_066810_ui_test.gd|TEAM_ORDERS_066810_UI_PASS'
  'team_radio_06689_advice_test.gd|TEAM_RADIO_06689_PASS'
  'radio_0668101_booked_pit_advice_test.gd|RADIO_0668101_BOOKED_PIT_PASS'
  'team_radio_06689_ui_test.gd|TEAM_RADIO_UI_06689_PASS'
  'racecraft_06688_grip_defense_test.gd|RACECRAFT_06688_GRIP_PASS'
  'driver_dynamics_06687_tyre_judgement_test.gd|DRIVER_DYNAMICS_06687_PASS'
  'driver_dynamics_06687_ui_test.gd|DRIVER_DYNAMICS_06687_UI_PASS'
  'core2_06686_sort_contract.gd|CORE2_06686_SORT_CONTRACT_PASS'
  'driver_dynamics_0661_test.gd|DRIVER_DYNAMICS_0661_PASS'
  'racecraft_0662_test.gd|RACECRAFT_0662_UNIT_PASS'
  'pit_incidents_double_stack_test.gd|APEX INCIDENT DOUBLE STACK OK'
  'replay_0660_test.gd|REPLAY_UNIT_PASS'
  'car_model_smoke_test.gd|APEX CAR MODEL TEST OK'
)
for entry in "${core2[@]}"; do
  file="${entry%%|*}"
  marker="${entry#*|}"
  [[ -s "tests/$file" ]] || fail "Core 2 ausente $file"
  label="${file%.gd}"
  home="$scratch/$label"
  mkdir -p -- "$home/data" "$home/config" "$home/cache"
  log="$output/$label.log"
  echo "APEX_13_REGRESSION_START $label"
  if ! env HOME="$home" XDG_DATA_HOME="$home/data" \
      XDG_CONFIG_HOME="$home/config" XDG_CACHE_HOME="$home/cache" \
      timeout 240s "$godot_bin" --headless --single-threaded-scene --path . \
      --script "res://tests/$file" > "$log" 2>&1; then
    tail -n 65 "$log" >&2
    fail "$label (Godot encerrou com erro)"
  fi
  if ! grep -Fq -- "$marker" "$log"; then
    tail -n 65 "$log" >&2
    fail "$label (marcador ausente)"
  fi
  if grep -Eiq '(^ERROR:|SCRIPT ERROR:|Parse Error:)' "$log"; then
    tail -n 65 "$log" >&2
    fail "$label (Godot reportou erros)"
  fi
  echo "APEX_13_REGRESSION_PASS $label"
  printf '| Core 2 %s | PASS |\n' "$label" >> "$report"
  ok_count=$((ok_count+1))
done

[[ -s tests/high_speed_growth_066723_benchmark.gd ]] || fail "Benchmark ausente"
echo "APEX_13_REGRESSION_START benchmark 500 ticks"
home="$scratch/benchmark"
mkdir -p -- "$home/data" "$home/config" "$home/cache"
if ! env HOME="$home" XDG_DATA_HOME="$home/data" \
    XDG_CONFIG_HOME="$home/config" XDG_CACHE_HOME="$home/cache" APEX_TICKS=500 \
    timeout 240s "$godot_bin" --headless --path . \
    --script res://tests/high_speed_growth_066723_benchmark.gd \
    > "$output/benchmark.log" 2>&1; then
  tail -n 65 "$output/benchmark.log" >&2
  fail "Benchmark 500 ticks"
fi
grep -Fq 'GROWTH_DONE' "$output/benchmark.log" || fail "Benchmark (marcador ausente)"
if grep -Eiq '(^ERROR:|SCRIPT ERROR:|Parse Error:)' "$output/benchmark.log"; then
  fail "Benchmark (Godot reportou erros)"
fi
printf '| Benchmark Core 2 de 500 ticks | PASS |\n' >> "$report"
ok_count=$((ok_count+1))

printf '\n**%d verificações concluídas com PASS**.\n\n' "$ok_count" >> "$report"
printf '**Não executados:** GdUnit4, auditorias por serviço (Codacy/CodeQL/Quality Gate remoto), comparação A/B com checkout da main e testes de interface gráfica.\n' >> "$report"
echo "APEX_13_REGRESSIONS_PASS checks=$ok_count report=$report"
