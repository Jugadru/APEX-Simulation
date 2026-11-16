"""Source-level regression checks. These do not prove Godot runtime execution."""
from pathlib import Path
import hashlib, json
root=Path(__file__).resolve().parents[1]
previous=root.parent/'APEX_GODOT_0.5.2.8'
engine=(root/'scripts/race_engine.gd').read_text()
ui=(root/'scripts/main.gd').read_text()
chart=(root/'scripts/pit_analytics_chart.gd').read_text()
for key in ['pit_history', '_record_pit_history', 'get_pit_summary', 'get_team_pit_comparison', 'get_pit_history', 'position_after', 'untrained_service']:
    assert key in engine, key
assert (root/'scripts/core/race_pit_lane.gd').read_text().count('host._record_pit_history(car)') == 1  # exactly one terminal record
assert 'if str(car["pit_stage"]) == "done":' in (root/'scripts/core/race_pit_lane.gd').read_text()
assert 'pit_history.append' in engine
for key in ['Análises','_refresh_pit_analytics', '_pit_engineer_recommendation', '_export_pit_csv', 'file.store_csv_line','analytics_chart.set_records']:
    assert key in ui, key
assert 'custom_minimum_size' in chart and 'func _draw()' in chart
assert 'get_pit_history(selected_team)' in ui
assert 'training_saved' in engine and 'net_vs_untrained' in engine
if previous.is_dir() and all((previous/name).is_file() for name in ['data/season_2012.json', 'scripts/garage.gd', 'scripts/track_map.gd', 'scripts/track_3d.gd', 'scripts/car_model_3d.gd', 'scripts/tv_director.gd', 'scripts/pit_complex_3d.gd']):
    for name in ['data/season_2012.json','scripts/garage.gd','scripts/track_map.gd','scripts/track_3d.gd', 'scripts/car_model_3d.gd','scripts/tv_director.gd','scripts/pit_complex_3d.gd']:
        a,b=(root/name).read_bytes(),(previous/name).read_bytes()
        assert hashlib.sha256(a).digest()==hashlib.sha256(b).digest(), f'Preserved game logic changed: {name}'
else:
    print('SKIP: archived v0.5.2.8 baseline unavailable; current engine/geometric checks are in test_0533_static.py')
season=json.loads((root/'data/season_2012.json').read_text())
assert len(season['tracks'])==20 and len(season['teams'])==12 and sum(len(team['drivers']) for team in season['teams'])==24
for name in ['pit_analytics_smoke_test.gd','pit_analytics_incident_test.gd','pit_analytics_ui_test.gd']:
    assert (root/'tests'/name).exists()
print('PASS v0.5.2.9 static: telemetry, chart, team comparison, no baseline 3D/2D/crew changes')
