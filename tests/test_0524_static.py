"""Offline invariants for the new 3D-only Circuit Life layer."""
from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[1]
baselines = {
    '11a4cf845cf9f077be022b537a4c9b94ad2afa41e4f6043c035238d39cf56410': 'scripts/track_map.gd',
    'a03843f9ac2b818bdb98a3d3417e42f40d792064b48df4334bf008e2828f94eb': 'data/season_2012.json',
}
for sha, path in baselines.items():
    data = (root/path).read_bytes()
    assert hashlib.sha256(data).hexdigest() == sha, f'Approved asset unexpectedly changed: {path}'

track = (root/'scripts/track_3d.gd').read_text(encoding='utf-8')
main = (root/'scripts/main.gd').read_text(encoding='utf-8')
pit = (root/'scripts/pit_complex_3d.gd').read_text(encoding='utf-8')
director = (root/'scripts/tv_director.gd').read_text(encoding='utf-8')
for needed in ['_build_environment_details()', '_add_safety_barriers()', '_add_trees_multimesh()', '_add_grandstands()', 'pit_complex.prepare', 'get_pit_camera_target', '"pit"', 'update_pit_services']:
    assert needed in track, needed
for needed in ['position_for_stop', 'local_stop_position', 'tangent_for_stop', 'team_slots', 'update_pit_services']:
    assert needed in pit, needed
assert 'world_view.set_track_data(map_view.route, str(track["name"]), teams,' in main
assert 'world_view.set_broadcast_view(desired, desired_dir, secondary_pos, shot_style, delta, target_car_id)' in main
assert 'pit_status_label.text' in main
assert 'event_style = "pit"' in director
assert 'MAPA' not in pit
season = json.loads((root/'data/season_2012.json').read_text(encoding='utf-8'))
assert len(season['tracks']) == 20 and len(season['teams']) == 12
assert 'PIT_ENTRY_FRACTION' in (root/'scripts/race_engine.gd').read_text(encoding='utf-8')
print('APEX 0.5.2.5 STATIC OK: continuous pit path, approved 2D/3D models and 2012 data retained.')
