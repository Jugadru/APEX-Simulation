#!/bin/sh
# Eight dependent rounds, separate Godot processes, same isolated persistent saves.
set -eu
PROJECT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BIN=${GODOT_BIN:-godot}
OUT=${APEX_CAREER_QA_DIR:-"$PROJECT/qa/0645/career_native_020"}
mkdir -p "$OUT"
OUT=$(CDPATH= cd -- "$OUT" && pwd)
RUNTIME=$(mktemp -d)
trap 'rm -rf "$RUNTIME"' EXIT HUP INT TERM
export XDG_DATA_HOME="$RUNTIME"
export APEX_CAREER_QA_DIR="$OUT"
cd "$PROJECT"
"$BIN" --version > "$OUT/engine_version.txt"
for round in 0 1 2 3 4 5 6 7; do
 number=$((round + 1))
 log="$OUT/round_$number.log"
 code=0
 timeout 14400 "$BIN" --headless --path "$PROJECT" --script tests/career_0645_native_worker.gd -- "$round" > "$log" 2>&1 || code=$?
 echo "$code" > "$OUT/round_$number.exit"
 if [ "$code" -ne 0 ] || grep -Eq 'SCRIPT ERROR|FAIL|ERROR:' "$log"; then
  cat "$log"
  exit 1
 fi
 echo "PASS career round $number"
done
