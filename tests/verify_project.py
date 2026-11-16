"""Offline checks of Godot source layout; does not replace running Godot."""
from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
required = [
    'project.godot', 'scenes/main.tscn', 'data/teams.json', 'data/season_2012.json',
    'scripts/main.gd', 'scripts/track_map.gd', 'scripts/race_engine.gd',
    'scripts/garage.gd', 'scripts/tv_director.gd', 'scripts/track_3d.gd', 'tests/ui_smoke_test.gd',
]
for name in required:
    assert (root / name).is_file(), f'Missing {name}'
season = json.loads((root / 'data/season_2012.json').read_text(encoding='utf-8'))
assert season['season'] == 2012
assert len(season['teams']) == 12
assert sum(len(team['drivers']) for team in season['teams']) == 24
assert len(season['tracks']) == 20
main = (root / 'scripts/main.gd').read_text(encoding='utf-8')
view = (root / 'scripts/track_map.gd').read_text(encoding='utf-8')
engine = (root / 'scripts/race_engine.gd').read_text(encoding='utf-8')
for needed in ['VISUAL_OPTIONS', '_apply_visual_from_setting', '_cycle_info_mode', '_start_race', 'season_tracks']:
    assert needed in main, needed
for needed in ['MODE_MAP', 'MODE_CLOSE', 'set_track_data', '_draw_close_circuit', '_draw_strategic_circuit', '_draw_small_car']:
    assert needed in view, needed
for needed in ['track_payload', 'base_lap', 'pit_loss', 'func step(sim_delta: float)', 'GRID 2012']:
    assert needed in engine, needed
assert 'func select(engine' in (root / 'scripts/tv_director.gd').read_text(encoding='utf-8')
assert 'func buy(team_name' in (root / 'scripts/garage.gd').read_text(encoding='utf-8')
print('APEX STATIC OK — 2012, 24 pilotos, 20 pistas, visual auto F1M, motor por pista.')

assert "SubViewportContainer.new()" in main and "world_view.set_track_data" in main
assert "Closed Chaikin corner cutting" in view
print("APEX V0.5.2.1 STATIC OK — camera 3D, mapa suave e simulacao mantida")
