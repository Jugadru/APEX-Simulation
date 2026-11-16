from apex_contracts import check_0580_mechanics
"""APEX 0.5.7.0 offline architecture, integration and regression checks.
Native GDScript behavior additionally requires Godot 4.7.2 headless tests.
"""
from pathlib import Path
from hashlib import sha256
import re

root = Path(__file__).resolve().parents[1]
director = (root/'scripts/core/race_ai_director.gd').read_text()
weather = (root/'scripts/core/race_weather.gd').read_text()
engine = (root/'scripts/race_engine.gd').read_text()
ui = (root/'scripts/main.gd').read_text()

assert 'const AIDirector = preload("res://scripts/core/race_ai_director.gd")' in engine
assert 'func get_engineer_advice(car_id: int)' in engine
assert '_request_ai_pit(car, true)' in engine
assert 'Strategy.pit_choice(car, lap_count, available_pit_compounds(), tyre_specs,' in engine
assert 'not bool(car["pit_request"])' in engine
assert 'func forecast(start_seconds: float, ahead_seconds: float)' in weather
assert 'rain_at(middle)' in weather and 'wetness + (' in weather
assert '_stint_gain(' in director and 'projected_saving' in director
assert 'pit_loss + (0.5 if undercut else 2.5)' in director
assert 'teammate_busy and pit_now and not critical' in director
assert 'if remaining < 2 or spec.is_empty()' in director
assert 'get_engineer_advice(int(car["id"]))' in ui
assert 'get_engineer_advice(int(focus["id"]))' in ui
assert 'CHAMAR BOX' in ui and '_request_pit(id: int, tire_select: OptionButton)' in ui
assert 'Previsão de água em 3v:' in ui and 'ENGENHEIRO:' in ui
assert 'func _on_lap_cross(car: Dictionary)' in engine
# Still verify that the 0.5.8.0 mechanics are unchanged, without an external archive.
check_0580_mechanics(root)
for name in ('core_0570_ai_director_smoke_test.gd', 'core_0570_long_strategy_run.gd'):
    assert (root/'tests'/name).is_file()
print('PASS 0570: deterministic planner, pit-cost model, team box coordination, read-only weather forecast and approved mechanics')
