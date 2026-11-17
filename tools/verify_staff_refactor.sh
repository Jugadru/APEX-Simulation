#!/usr/bin/env bash
# Run with GODOT_BIN=/path/to/godot bash tools/verify_staff_refactor.sh [--ui]
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
godot_bin=${GODOT_BIN:-godot}
qa_dir="$project_dir/qa/refactor"
mkdir -p "$qa_dir"
tests=(staff_refactor_parity_test soul_staff_0650_model_test soul_staff_0650_migration_test staff_0648_contracts_test soul_staff_0650_season_test staff_0648_career_integration_test soul_staff_0650_three_tracks_test)
if [[ ${1:-} == --ui ]]; then
    tests+=(staff_0648_ui_test soul_staff_0650_ui_test)
fi
# A unique data directory for each test prevents migration from real user saves.
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
for test_name in "${tests[@]}"; do
    mkdir -p "$test_root/$test_name"
    mode=(--headless)
    if [[ $test_name == *_ui_test ]]; then
        mode=(--borderless --position 0,0 --audio-driver Dummy)
    fi
    log="$qa_dir/$test_name.log"
    if ! XDG_DATA_HOME="$test_root/$test_name" timeout "${TEST_TIMEOUT_SECONDS:-600}" "$godot_bin" "${mode[@]}" \
        --path "$project_dir" --script "tests/$test_name.gd" > "$log" 2>&1; then
        cat "$log"
        exit 1
    fi
    if grep -Eq 'SCRIPT ERROR:|(^|_)FAIL|^ERROR:' "$log"; then
        cat "$log"
        exit 1
    fi
    echo "PASS $test_name"
done
