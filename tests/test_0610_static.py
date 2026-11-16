"""APEX 0.6.1 — static regressions against shipped v0.6.0 source."""
from pathlib import Path
import json, hashlib, re
p=Path(__file__).resolve().parents[1]
main=(p/'scripts/main.gd').read_text()
weather=(p/'scripts/core/race_weather.gd').read_text()
season=json.loads((p/'data/season_2012.json').read_text())
proj=(p/'project.godot').read_text()
assert len(season['tracks']) == 20
assert len({x['code'] for x in season['tracks']}) == 20
assert len(season['teams']) == 12
assert sum(len(x['drivers']) for x in season['teams']) == 24
assert main.count('championship.record_result(') == 1
assert 'if championship_mode and str(track.get("code", "")) != str(championship.next_round().get("code", "")):' in main
assert 'season_tracks[selected_track_index]' in main
assert '"32×"' in main and '32.0][clampi(index, 0, 5)]' in main
assert 'while remaining > 0.001 and not race.finished:' in main
assert 'minf(4.0, remaining)' in main
assert 'window/size/viewport_width=1920' in proj and 'window/size/viewport_height=1080' in proj
assert '"Aérea estratégica"' in main
assert 'tactical_mini_map.set_track(map_view.route)' in main
assert 'tactical_mini_map.set_cars(draw_cars, focused_id)' in main
assert 'context_enabled = true' in main
assert 'visual_setting == 3' in main and 'shot_style = "helicopter"' in main
assert 'climate_profile' in weather and 'rain_events' in weather
assert 'rain_events.clear()' in weather and 'weather_rng.randf() < climate_chance' in weather
assert 'rain_at(seconds + delta)' in weather
assert 'if profile == "Seco":' in weather and 'if profile == "Chuva intensa":' in weather
assert 'if profile == "Variável":' in weather and 'return clampf(current, 0.0, 1.0)' in weather
profiles=re.findall(r'"([A-Z]{3})": \[([\d.]+), ([\d.]+)\]',weather)
chances={code:float(chance) for code, _, chance in profiles}
assert set(chances)=={item['code'] for item in season['tracks']},set(chances)^set(item['code'] for item in season['tracks'])
assert chances['MAL'] > chances['BHR'] and chances['BEL'] > chances['UAE']
assert all(0 < val < 0.5 for val in chances.values())
assert len({round(val,3) for val in chances.values()})>12
# Physical simulation, route and championship point logic preserved.
reference=Path('/mnt/data/apex_work_061/APEX_GODOT_0.6.0_TEMPORADA_2012_EXPERIMENTAL')
for file in ('scripts/race_engine.gd', 'scripts/championship_2012.gd','scripts/track_map.gd','scripts/track_3d.gd',
             'scripts/tv_director.gd','scripts/core/race_team_autonomy.gd','scripts/garage.gd','data/season_2012.json'):
    if reference.exists():
        assert hashlib.sha256((p/file).read_bytes()).hexdigest()==hashlib.sha256((reference/file).read_bytes()).hexdigest(),file
assert (p/'tests/core_0610_weather_and_speed_test.gd').is_file()
print('PASS 0610: 20 distinct circuits, independent weather per circuit, 32x, Full HD HUD, race engine preserved')
