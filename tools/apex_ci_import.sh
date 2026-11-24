#!/usr/bin/env bash
set -euo pipefail
log="${1:?provide import log path}"
for attempt in 1 2 3; do
  rm -rf .godot
  set +e
  timeout 240s godot --headless --single-threaded-scene --path . --import > "${log}.${attempt}" 2>&1
  status=$?
  set -e
  cp "${log}.${attempt}" "$log"
  if grep -Eiq '(SCRIPT ERROR:|Parse Error:)' "$log"; then cat "$log"; exit 1; fi
  if [ "$status" -eq 0 ]; then
    if grep -Eiq '^ERROR:' "$log"; then cat "$log"; exit 1; fi
    echo "APEX_CI_IMPORT_PASS attempt=$attempt"
    exit 0
  fi
  if [ "$attempt" -eq 3 ] || { [ "$status" -ne 134 ] && [ "$status" -ne 139 ]; }; then
    cat "$log"; exit "$status"
  fi
  echo "Godot native import crash ($status); retrying"
done
