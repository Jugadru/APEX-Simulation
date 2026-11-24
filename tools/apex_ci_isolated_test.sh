#!/usr/bin/env bash
# Each script has its own disposable user data, settings, cache and legacy HOME.
# A save migration test can still create and reload saves within its process.
set -euo pipefail
script="${1:?test script required}"
[[ "$script" =~ ^[A-Za-z0-9_]+\.gd$ ]] || exit 2
sandbox="$(mktemp -d "${RUNNER_TEMP:-/tmp}/apex-test.XXXXXXXX")"
trap 'rm -rf -- "$sandbox"' EXIT
export HOME="$sandbox/home"
export XDG_DATA_HOME="$sandbox/data"
export XDG_CONFIG_HOME="$sandbox/config"
export XDG_CACHE_HOME="$sandbox/cache"
export XDG_STATE_HOME="$sandbox/state"
mkdir -p "$HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
echo "APEX_TEST_ISOLATION script=$script data=$XDG_DATA_HOME"
timeout 240s godot --headless --single-threaded-scene --path . --script "res://tests/$script"
