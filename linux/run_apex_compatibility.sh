#!/bin/sh
# Alternative renderer for devices without Vulkan support.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
APEX_RENDERER=gl_compatibility exec "$HERE/run_apex.sh"
