#!/bin/sh
# APEX v0.6.4.9.7 — validação de coordenação, 1 funcionalidade por versão.
set -eu
PROJECT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BIN=${GODOT_BIN:-godot}
OUT="$PROJECT/qa/06497/revalidacao_local"
mkdir -p "$OUT"
for name in team_pit_06497_unit_test team_pit_06497_integration_test lap_strategy_06496_test lap_strategy_06496_auto_gate_test double_stack_06492_entry_test pitwall_06491_stint_reset_test; do
    XDG_DATA_HOME="$OUT/$name" "$BIN" --headless --path "$PROJECT" --script "res://tests/$name.gd" > "$OUT/$name.log" 2>&1
    if grep -Eq 'SCRIPT ERROR|Parser Error|FAIL' "$OUT/$name.log"; then
        cat "$OUT/$name.log"
        exit 1
    fi
    echo "PASS $name"
done
if command -v xvfb-run >/dev/null 2>&1; then
    XDG_DATA_HOME="$OUT/ui" xvfb-run -a "$BIN" --path "$PROJECT" --script res://tests/team_pit_06497_ui_test.gd > "$OUT/ui.log" 2>&1
    echo "PASS UI 1600x900 / 1920x1080"
else
    echo "SKIP UI (xvfb-run indisponível)"
fi
if [ "${APEX_RUN_FULL_GP:-0}" = "1" ]; then
    for code in GBR ITA; do
        XDG_DATA_HOME="$OUT/$code" "$BIN" --headless --path "$PROJECT" --script res://tests/auditoria_06497_gp.gd -- --code "$code" > "$OUT/$code.log" 2>&1
        echo "PASS corrida $code"
    done
fi
