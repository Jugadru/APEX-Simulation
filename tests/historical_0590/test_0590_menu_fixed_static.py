#!/usr/bin/env python3
"""Static guards for the 0.5.9.0 missing race-start button regression."""
from pathlib import Path
from hashlib import sha256
root=Path(__file__).resolve().parents[1]
main=(root/'scripts/main.gd').read_text()
assert 'var menu_scroll: ScrollContainer' in main
assert 'var menu_actions: VBoxContainer' in main
assert 'menu_column.add_child(menu_scroll)' in main
assert 'menu_column.add_child(menu_actions)' in main
assert 'start_button = _button(menu_actions,' in main
assert 'start_button = _button(box,' not in main
assert 'start_button.name = "StartRaceButton"' in main
assert 'start_button.custom_minimum_size = Vector2(0, 52)' in main
assert 'menu_hero.visible = sz.x >= 1100.0' in main
assert 'minf(1220.0, maxf(300.0, sz.x - 32.0))' in main
assert main.count('func _start_race()') == 1
assert main.count('start_button = _button(') == 1
assert 'func _start_race()' in main and 'race = RaceScript.new' in main
# Original fingerprints from the verified 0.5.9.0 Hotfix 1; no external folder required.
expected = {
    'scripts/race_engine.gd': 'e0e63a1f1e700a381ded2548050c9e2391037bc2571779e56ec464b32636c708',
    'scripts/track_map.gd': '11a4cf845cf9f077be022b537a4c9b94ad2afa41e4f6043c035238d39cf56410',
    'scripts/track_3d.gd': 'a90bcddab446cfa8b1ae745c569d3c26b9a9d9d51596e608d98924c34caf77fd',
    'scripts/tv_director.gd': '6fb42841214235ec0b1458558803edb3afb43be0e1ab2536daeb67ee756ae7ce',
    'scripts/garage.gd': '79e7091e0c21b93d60b267f7a34aa40c4b76068010ff749bc008d395cb796435',
    'scripts/core/race_team_autonomy.gd': '1f522df4960b845f96052d41ffdb44456240f235e8e2048295eab33a0805fba8',
    'data/season_2012.json': 'a03843f9ac2b818bdb98a3d3417e42f40d792064b48df4334bf008e2828f94eb',
    'project.godot': '495dc1a3373fa2a55465a5d544a331438a1451324c0102bbc201deb386069ccf',
}
for name, checksum in expected.items():
    assert sha256((root/name).read_bytes()).hexdigest() == checksum, name
print('PASS: start action pinned outside scroll; responsive menu; original race/garage/data preserved')
