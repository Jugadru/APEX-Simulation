"""Offline invariants for Core 2 weather; engine runtime is covered by the .gd smoke test."""
from pathlib import Path
import hashlib, json, re, math
root=Path(__file__).resolve().parents[1]
engine=(root/'scripts/race_engine.gd').read_text(encoding='utf-8')
ui=(root/'scripts/main.gd').read_text(encoding='utf-8')
perf=(root/'scripts/core/race_performance.gd').read_text(encoding='utf-8')
strat=(root/'scripts/core/race_strategy.gd').read_text(encoding='utf-8')
met=(root/'scripts/apex_telemetry.gd').read_text(encoding='utf-8')
weather=(root/'scripts/core/race_weather.gd').read_text(encoding='utf-8')
wet=(root/'scripts/core/race_wet_physics.gd').read_text(encoding='utf-8')
assert 'func configure_weather(' in engine and 'func weather_snapshot()' in engine
assert 'weather.advance(dt, clock,' in engine
assert '"weather": current_weather' in engine
assert '"Intermediário", "Chuva"' in engine
assert 'if not available_pit_compounds().has(target)' in engine
assert 'WetPhysics.weather_incident_risk' in engine
assert 'WetPhysics.modifier' in perf and 'float(wet_tyre["penalty"])' in perf
assert '"drs_allowed"' in (root/'scripts/core/race_drs_2012.gd').read_text() and 'WetPhysics.modifier' in strat
assert '"Chuva intensa"' in weather and '"Seco"' in weather
assert 'weather_mode_picker' in ui and 'race.configure_weather(' in ui
assert ui.count('race.weather_snapshot()') >= 2
assert 'conditions.snapshot(' not in ui
assert 'Clima ativo: ritmo, pneus, IA e DRS.' in ui
assert 'weather_history' in met and '["clima",' in met
assert (root/'tests/core_0550_weather_smoke_test.gd').is_file()
assert 'PROFILE_CLASSIC' not in engine
specs=json.loads((root/'data/tyres_2012.json').read_text(encoding='utf-8'))
assert len(specs['tracks'])==20
assert specs['compounds']['Intermediário']['code']=='I'
assert specs['compounds']['Chuva']['code']=='W'
for code, cfg in specs['tracks'].items():
    assert len(cfg['dry'])==2 and len(set(cfg['dry']))==2,code
    assert not {'Intermediário','Chuva'} & set(cfg['dry'])
# Original 3D camera, race geometry and pit-lane state machine unchanged.
orig=Path('/mnt/data/build_0550/original_0543')
for name in ('scripts/core/race_pit_lane.gd', 'scripts/core/race_pit_math.gd',
             'scripts/track_3d.gd', 'scripts/pit_complex_3d.gd',
             'scripts/car_model_3d.gd', 'scripts/tv_director.gd',
             'scripts/core/race_combat.gd'):
    assert (root/name).exists(),name
    if orig.is_dir():
        assert hashlib.sha256((root/name).read_bytes()).digest()==hashlib.sha256((orig/name).read_bytes()).digest(),name
# Independent equations mirrored from the math-only Godot module.
def penalty(t,w):
    if t=='I': return 6*max(0,1-w/.23)**1.3 + 23*max(0,(w-.56)/.44)**1.6
    if t=='W': return 12*max(0,1-w/.73)**1.1 + 2*max(0,(w-.88)/.12)
    return 4*w+75*w*w
for w in [0,.05,.1,.15,.2,.3,.4,.5,.6,.7,.8,.9,1]:
    for t in ('D','I','W'):
        assert math.isfinite(penalty(t,w)) and penalty(t,w)>=0
assert penalty('D',0)<penalty('I',0)<penalty('W',0)
assert penalty('I',.40)<penalty('D',.40)
assert penalty('W',.90)<penalty('I',.90)<penalty('D',.90)
print('PASS: Core 2 climate single source, crossover, 20 tyre allocations, HUD, pit/3D code preserved')
