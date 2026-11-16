"""Regression tests for 0.6.1.1 patch (run with Python 3)."""
from pathlib import Path
import hashlib, json, math
root=Path(__file__).resolve().parents[1]
source=Path('/mnt/data/APEX_GODOT_0.6.1_HUD_CLIMA_2012_EXPERIMENTAL')
main=(root/'scripts/main.gd').read_text()
track=(root/'scripts/track_map.gd').read_text()
weather=(root/'scripts/core/race_weather.gd').read_text()
assert 'func _frame_strategic_circuit()' in main
assert 'render_mode == 0 and camera_mode != "Seguir piloto"' in main
assert 'hud_layout_0611.cfg' in main and 'hud_layout_mode: int = 2' in main
assert 'var map_overlay_enabled: bool = false' in main
assert 'func rain_risk_window(seconds: float' in weather
assert 'rain_risk_window(seconds, 900.0)' in weather
assert 'forecast_minutes' in weather
assert 'climate_chance * 0.48 + max_approaching' not in weather
block=track.split('func _draw_strategic_circuit()',1)[1].split('func _draw_close_circuit()',1)[0]
assert '_draw_finish_and_pits(false)' in block
assert 'draw_polyline(route,' in block
assert 'SECTOR_COLORS[sector]' not in block
assert 'MAPA AÉREO 2D' in block
assert 'for car in cars:' in track and '_draw_dot' in track
for rel in ('scripts/race_engine.gd','scripts/core/race_team_autonomy.gd','scripts/core/race_ai_director.gd','scripts/core/race_strategy.gd','scripts/core/race_performance.gd','scripts/championship_2012.gd','scripts/track_3d.gd','scripts/garage.gd','data/season_2012.json'):
    before=(source/rel).read_bytes()
    after=(root/rel).read_bytes()
    assert hashlib.sha256(before).digest()==hashlib.sha256(after).digest(),rel
season=json.loads((root/'data/season_2012.json').read_text())
assert len(season['tracks'])==20 and sum(len(t['drivers']) for t in season['teams'])==24
assert '32.0][clampi(index, 0, 5)]' in main
print('PASS 0.6.1.1: new 2D overhead dots, 1600px compact HUD, rolling rain risk; racing engine, auto engineer and championship untouched.')
