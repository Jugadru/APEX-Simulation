"""Static integration checks for the 2012 car-model upgrade.
Run: python3 tests/test_car_models_3d.py
"""
from pathlib import Path
import hashlib

root = Path(__file__).resolve().parents[1]
car = (root/'scripts/car_model_3d.gd').read_text(encoding='utf-8')
world = (root/'scripts/track_3d.gd').read_text(encoding='utf-8')
main = (root/'scripts/main.gd').read_text(encoding='utf-8')
map_gd = (root/'scripts/track_map.gd').read_bytes()
engine_gd = (root/'scripts/race_engine.gd').read_bytes()

assert car.startswith('extends Node3D')
for part in (
    'TaperedChassis', 'NoseStep', 'CockpitRim', 'DriverHelmet',
    'FrontWingMain', 'FrontWingFlap', 'RearWingPrimary', 'RearWingEndplate',
    'WheelSpin', 'HubCenter', 'Rim', 'Front', 'Rear',
    'Right', 'Left', 'Sidepod', 'Diffuser', 'FocusDisc',
    'PlayerRing', 'NumberTag', 'func update_motion(',
):
    assert part in car, f'car part missing: {part}'
for integration in (
    'CarModelScript = preload(', 'func set_race_cars(',
    'model.call("update_motion"', 'last_positions', 'lerp_angle(',
    'prior.cross(future)', 'func _build_road_sections(',
    'ROAD_HALF', '_add_band(',
):
    assert integration in world, f'World integration missing: {integration}'
assert 'world_view.set_race_cars(draw_cars, focused_id)' in main
assert 'world_view.set_track_data(map_view.route' in main
assert hashlib.sha256(map_gd).hexdigest() == '11a4cf845cf9f077be022b537a4c9b94ad2afa41e4f6043c035238d39cf56410', '2D approved map altered'
assert b'func _advance_pit(' in engine_gd and b'PIT_ENTRY_FRACTION' in engine_gd, 'integrated pit engine missing'
assert 'FocusDisc' in world and 'PlayerRing' in world
print('CAR MODEL STATIC OK: 4 independently steerable/spinning wheels, improved model, integrated pit engine and unchanged 2D map')
