#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo 'APEX 0.5.4.3 — testes estáticos e regressões'
python3 tests/test_0543_static.py
python3 tests/verify_project.py
python3 tests/test_circuits_2012.py
python3 tests/test_pit_continuity_static.py
python3 tests/test_road_mesh_geometry.py
bin="${GODOT_BIN:-}"
if [[ -z "$bin" ]]; then
    for candidate in godot godot4 Godot; do
        if command -v "$candidate" >/dev/null 2>&1; then bin="$candidate"; break; fi
    done
fi
if [[ -z "$bin" ]]; then
    echo 'Godot não encontrado: verificações offline concluídas; teste GDScript pendente.'
    echo 'Defina GODOT_BIN=/caminho/para/Godot.AppImage e repita.'
    exit 0
fi
echo "Executando Godot: $bin"
"$bin" --headless --path . --editor --quit
a=(
    res://tests/core_0543_combat_smoke_test.gd
    res://tests/telemetry_0533_smoke_test.gd
    res://tests/double_stack_smoke_test.gd
)
for script in "${a[@]}"; do
    echo "Rodando $script"
    "$bin" --headless --path . --script "$script"
done
echo 'Todos os testes disponíveis concluídos.'
