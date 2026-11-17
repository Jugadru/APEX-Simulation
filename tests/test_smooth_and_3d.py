"""Static regression checks for prototype; run Godot tests for actual graphics validation."""
from pathlib import Path
import json
root = Path(__file__).resolve().parents[1]
main=(root/'scripts/main.gd').read_text()
track=(root/'scripts/track_map.gd').read_text()
world=(root/'scripts/track_3d.gd').read_text()
car=(root/'scripts/car_model_3d.gd').read_text()
assert 'SubViewportContainer.new()' in main and 'SubViewport.new()' in main
assert 'world_view.set_race_cars' in main and 'world_view.set_track_data(map_view.route' in main
assert 'world_container.visible = render_mode == 1' in main
assert 'render_mode = 1 if sim_speed <= 2.0 else 0' in main
assert '"route_point"' in world and '"route_point"' in main
assert 'for iteration in range(3):' in track and 'first.lerp(second, 0.25)' in track
assert 'Mesh.PRIMITIVE_TRIANGLES' in world and 'ArrayMesh.new()' in world
assert '_build_road_sections()' in world and 'road_widths' in world
assert 'RUNOFF_MULTIPLIER' in world and 'CURB_BLOCK_METERS' in world
assert '_add_strip(' not in world  # no independent quads / needle spikes
assert 'Camera3D.new()' in world and 'PlaneMesh.new()' in world
assert 'BoxMesh.new()' in car and 'CylinderMesh.new()' in car
assert (root/'data/LICENSE-f1-circuits-MIT.txt').is_file()
season=json.loads((root/'data/season_2012.json').read_text())
assert len(season['tracks'])==20 and len(season['teams'])==12
print('PASS: 3D viewport, shared geometry, smoothing and data bindings checked')
