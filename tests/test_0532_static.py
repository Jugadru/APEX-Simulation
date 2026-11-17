from apex_contracts import check_build_version
"""Static contract test for v0.5.3.2, without the Godot executable."""
from pathlib import Path
import hashlib
root=Path(__file__).resolve().parents[1]
main=(root/'scripts/main.gd').read_text()
portrait=(root/'scripts/apex_portrait_manager.gd').read_text()
mini=(root/'scripts/apex_mini_map.gd').read_text()
conditions=(root/'scripts/apex_track_conditions.gd').read_text()
check_build_version(root, '0.5.3.2')
for needle in ('_download_team_portraits', '_download_all_portraits', '_rebuild_player_cards', '_refresh_player_cards',
               'mini_map.set_track(map_view.route)', 'mini_map.set_cars(draw_cars, focused_id)',
               'race.weather_snapshot()', 'Clima ativo: ritmo, pneus, IA e DRS.'):
    assert needle in main, needle
assert 'LicenseShortName' in portrait and 'CREDITOS_FOTOGRAFIAS.txt' in portrait
assert 'HTTPRequest' in portrait and 'status_changed.emit' in portrait
assert 'route: PackedVector2Array' in mini and 'route_point' in mini
assert 'snapshot(seconds: float' in conditions and '"rain_probability"' in conditions
assert 'user://hud_layout_0530.cfg' in main
for rel in ('race_engine.gd','track_map.gd','track_3d.gd','car_model_3d.gd',
            'pit_complex_3d.gd','garage.gd','tv_director.gd','pit_analytics_chart.gd'):
    old=root.parent/'APEX_GODOT_0.5.3.1'/'scripts'/rel
    new=root/'scripts'/rel
    assert new.exists(), rel
    if old.exists():
        assert hashlib.sha256(old.read_bytes()).digest()==hashlib.sha256(new.read_bytes()).digest(), rel
print('PASS: portraits, mini map and shared physics weather snapshot; legacy 3D preserved')
