#!/usr/bin/env bash
# Each script has its own disposable user data, settings, cache and legacy HOME.
# A save migration test can still create and reload saves within its process.
set -euo pipefail
script="${1:?test script required}"
[[ "$script" =~ ^[A-Za-z0-9_]+\.gd$ ]] || exit 2
sandbox="$(mktemp -d "${RUNNER_TEMP:-/tmp}/apex-test.XXXXXXXX")"
# Audio helper processes may briefly write XDG config after Godot exits.
# Retry only sandbox cleanup, never a failed sporting test.
cleanup() {
    local status=$?
    trap - EXIT
    for attempt in 1 2 3; do
        if rm -rf -- "$sandbox"; then exit "$status"; fi
        sleep 0.2
    done
    echo "APEX_TEST_ISOLATION_CLEANUP_FAILED: $sandbox" >&2
    if [ "$status" -ne 0 ]; then exit "$status"; fi
    exit 1
}
trap cleanup EXIT
export HOME="$sandbox/home"
export XDG_DATA_HOME="$sandbox/data"
export XDG_CONFIG_HOME="$sandbox/config"
export XDG_CACHE_HOME="$sandbox/cache"
export XDG_STATE_HOME="$sandbox/state"
mkdir -p "$HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
echo "APEX_TEST_ISOLATION script=$script data=$XDG_DATA_HOME"
# The Pit Wall scene test explicitly requires real framebuffer captures.
# Use a software-rendered virtual display, NOT Godot's dummy headless renderer.
# All other tests retain their original headless command.
case "$script" in
    pitwall_0649_ui_test.gd|race_engineer_0922_ui_test.gd)
        command -v xvfb-run >/dev/null || { echo "APEX_GRAPHICAL_TEST_BLOCKED: xvfb-run missing" >&2; exit 1; }
        echo "APEX_TEST_RENDERER script=$script mode=xvfb_gl_compatibility"
        # Graphical CI has no audio device; select Dummy explicitly, not headless video.
        LIBGL_ALWAYS_SOFTWARE=1 timeout 240s xvfb-run -a -s "-screen 0 1920x1080x24" godot --audio-driver Dummy --rendering-method gl_compatibility --single-threaded-scene --path . --script "res://tests/$script"
        ;;
    *)
        timeout 240s godot --headless --single-threaded-scene --path . --script "res://tests/$script"
        ;;
esac
