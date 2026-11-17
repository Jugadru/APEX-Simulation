#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
GODOT_BIN=${GODOT_BIN:-godot}
"$GODOT_BIN" --headless --path "$ROOT" --script "res://tests/auditoria_06496_silverstone.gd" -- --code GBR
