#!/usr/bin/env python3
"""Offline verification for the v0.5.9.0 integration, not a Godot runtime test."""
from pathlib import Path
from hashlib import sha256
import json

root = Path(__file__).resolve().parents[1]
main = (root / "scripts/main.gd").read_text()
garage = (root / "scripts/garage.gd").read_text()
auto = (root / "scripts/core/race_team_autonomy.gd").read_text()
project = (root / "project.godot").read_text()

assert 'v0.5.9.0' in project and 'v0.6.0' not in project
assert 'window/size/viewport_width=1600' in project  # no premature HUD 0.6.0
assert 'window/size/viewport_height=900' in project
for required in (
    'pre_race_team_mode_picker = _option', 'live_team_mode_picker = _option',
    'func _apply_team_control(', 'func _autonomy_tick(',
    'race.set_pit_control_mode(int(car["id"]), "IA" if mode == "Automático" else "Manual")',
    'TeamAutonomyScript.decide(', 'race.set_pace(car_id,', 'race.set_kers_mode(car_id,',
    'func _change_pit_mode(', 'team_control_mode == "Manual"',
    'card["pace"].disabled = team_control_mode == "Automático"',
    'card["pit_mode"].disabled = team_control_mode == "Automático"',
    'card["kers_button"].disabled = not kers_enabled',
    'func _request_pit(', 'func _schedule_pit(', 'func _cancel_scheduled_pit(',
    'func _process(delta: float)', 'race.step(delta * sim_speed)',
):
    assert required in main, required
for required in (
    'STAFF_ROLES := ["Estrategista", "Engenheiro"]',
    'func staff_next_cost(', 'func hire_staff(',
    '"staff_levels": cleaned_staff', 'func save()', 'func _load_data()',
):
    assert required in garage, required
for required in ('static func decide(', 'var engineer:', 'var strategist:', 'var forecast:',
                 '"pace": pace', '"kers": kers', '"reason": why'):
    assert required in auto, required
assert main.count('func _start_race()') == 1
assert main.count('func _process(delta: float)') == 1
assert 'func _request_ai_pit(' in (root/'scripts/race_engine.gd').read_text()
assert 'pit_scheduled_lap' in (root/'scripts/race_engine.gd').read_text()
season=json.loads((root/'data/season_2012.json').read_text())
assert len(season['tracks'])==20 and len(season['teams'])==12
assert sum(len(t['drivers']) for t in season['teams'])==24
# Guard against GDScript parser failures caused by mixed indentation in changed files.
for file in ['scripts/main.gd','scripts/garage.gd','scripts/core/race_team_autonomy.gd']:
    for i,ln in enumerate((root/file).read_text().splitlines(),1):
        assert not ln.startswith(' '),f'{file}:{i}: mixed spaces/tab indentation'
# These are reference fingerprints from the original 0.5.8.0 ZIP.
reference={
    'scripts/race_engine.gd': 'e0e63a1f1e700a381ded2548050c9e2391037bc2571779e56ec464b32636c708',
    'scripts/track_map.gd': '11a4cf845cf9f077be022b537a4c9b94ad2afa41e4f6043c035238d39cf56410',
    'scripts/track_3d.gd': 'a90bcddab446cfa8b1ae745c569d3c26b9a9d9d51596e608d98924c34caf77fd',
    'scripts/tv_director.gd': '6fb42841214235ec0b1458558803edb3afb43be0e1ab2536daeb67ee756ae7ce',
    'data/season_2012.json': 'a03843f9ac2b818bdb98a3d3417e42f40d792064b48df4334bf008e2828f94eb',
}
for name,checksum in reference.items():
    got=sha256((root/name).read_bytes()).hexdigest()
    assert got == checksum,(name,got,checksum)
print('PASS 0590: team manual/auto wiring, staff save, UI, 2012 data, base motor and visuals preserved')
