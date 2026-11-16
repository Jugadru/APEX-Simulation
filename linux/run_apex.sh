#!/bin/sh
# Apex Motorsport Manager Godot 0.5.1 — launches a locally installed Godot 4.
# Does not download anything or modify previous Apex releases.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT=$(CDPATH= cd -- "$HERE/.." && pwd)
if [ ! -f "$PROJECT/project.godot" ]; then
  echo "Arquivo project.godot nao encontrado em: $PROJECT" >&2
  exit 1
fi
BIN=""
for candidate in "${GODOT_BIN:-}" godot4 godot /usr/local/bin/godot /usr/bin/godot ; do
  if [ -z "$candidate" ]; then continue; fi
  if command -v "$candidate" >/dev/null 2>&1; then
    candidate=$(command -v "$candidate")
    version=$("$candidate" --version 2>/dev/null | head -n 1 || true)
    case "$version" in 4.*) BIN=$candidate; break ;; esac
  fi
done
if [ -z "$BIN" ]; then
  echo "Nao encontrei o Godot 4 no PATH." >&2
  echo "Abra o Godot manualmente e importe $PROJECT/project.godot" >&2
  echo "Ou defina GODOT_BIN=/caminho/para/seu/Godot_AppImage e execute este script." >&2
  exit 1
fi
exec "$BIN" --path "$PROJECT" --rendering-method "${APEX_RENDERER:-forward_plus}"
