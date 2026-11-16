"""Checks project files and 2012 season data without requiring Godot installed."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
assert (root / 'project.godot').is_file()
assert (root / 'scenes/main.tscn').is_file()
for name in ('main','race_engine','garage','track_map','tv_director'):
    text = (root / f'scripts/{name}.gd').read_text(encoding='utf-8')
    assert text.startswith('extends '), name
    assert 'func ' in text, name
season = json.loads((root / 'data/season_2012.json').read_text(encoding='utf-8'))
assert season['season'] == 2012
assert len(season['teams']) == 12
assert sum(len(t['drivers']) for t in season['teams']) == 24
assert len(season['tracks']) == 20
spa = [t for t in season['tracks'] if t['code'] == 'BEL'][0]
assert spa['laps'] == 44 and abs(spa['lap_km'] - 7.004) < 1e-9
assert len(spa['points']) >= 40 and spa['points'][0] == spa['points'][-1]
print('STATIC CHECK OK: 2012 season, 12 teams, 24 drivers, 20 tracks.')
