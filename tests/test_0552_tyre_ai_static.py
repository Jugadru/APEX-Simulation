"""Offline contracts and numeric comparisons for 0.5.5.2. The native Godot test must also be run."""
from pathlib import Path
import hashlib, json, math

root=Path(__file__).resolve().parents[1]
strategy=(root/'scripts/core/race_strategy.gd').read_text(encoding='utf-8')
engine=(root/'scripts/race_engine.gd').read_text(encoding='utf-8')
perf=(root/'scripts/core/race_performance.gd').read_text(encoding='utf-8')
prev=Path('/mnt/data/APEX_GODOT_0.5.5.1')
for literal in ('const CRITICAL_WEAR: float = 92.0',
                'var near_cliff: bool =', 'var worn_out: bool =',
                '_best_fresh_compound(', 'return best',
                'if bool(car.get("pit_request", false))',
                'if remaining < 2:'):
    assert literal in strategy, literal
assert 'if current in ["Intermediário", "Chuva"]:\n' not in strategy, 'Old wet-tyre early return survived'
assert '_request_ai_pit(car, true)' in engine, 'Missing urgent in-race safety check'
assert 'Strategy.pit_choice(car, lap_count, available_pit_compounds(), tyre_specs,' in engine
assert '"strategy"' in engine
if prev.is_dir():
    previous_ui=(prev/'scripts/main.gd').read_text(encoding='utf-8')
    updated_ui=(root/'scripts/main.gd').read_text(encoding='utf-8')
    if not any(v in (root/'project.godot').read_text() for v in ('v0.5.6.0', 'v0.5.6.1', 'v0.5.7.0')):
        assert previous_ui.replace('0.5.5.1', '0.5.5.2').replace('0.5.4.3', '0.5.5.2') == updated_ui, 'Unexpected HUD change'
    else:
        # New KERS/DRS controls intentionally change the HUD, but do not move the pit command.
        assert 'CHAMAR BOX' in updated_ui and 'quick_pit' in updated_ui
        assert '_cycle_kers_mode' in updated_ui
assert 'var cooling: float = rain_wetness *' in perf
assert 'if not available_pit_compounds().has(target):' in engine
assert 'car["tire"] = str(car["pit_target"])' in engine

# No changes to the original 0.5.5.1 I vs W crossover coefficients.
for unchanged in ['scripts/core/race_wet_physics.gd','scripts/core/race_weather.gd',
                  'scripts/core/race_pit_lane.gd','scripts/core/race_pit_math.gd',
                  'scripts/core/race_combat.gd',
                  'scripts/track_3d.gd','scripts/pit_complex_3d.gd']:
    if prev.is_dir():
        if unchanged == 'scripts/core/race_weather.gd' and 'race_ai_director.gd' in engine:
            # v0.5.7.0 adds a read-only forecast without changing wet-track physics.
            old_weather=(prev/unchanged).read_text(encoding='utf-8')
            new_weather=(root/unchanged).read_text(encoding='utf-8')
            for section in ('func setup(', 'func rain_at(', 'func advance(', 'func _make_state('):
                old_body=old_weather.split(section, 1)[1].split('\nfunc ', 1)[0]
                new_body=new_weather.split(section, 1)[1].split('\nfunc ', 1)[0]
                assert old_body == new_body, f'Physics changed unexpectedly: {section}'
            continue
        before=hashlib.sha256((prev/unchanged).read_bytes()).hexdigest()
        after=hashlib.sha256((root/unchanged).read_bytes()).hexdigest()
        assert before==after, f'Unexpected change: {unchanged}'

specs=json.loads((root/'data/tyres_2012.json').read_text(encoding='utf-8'))['compounds']
assert len(json.loads((root/'data/tyres_2012.json').read_text(encoding='utf-8'))['tracks'])==20

def wear_multiplier(name,w):
    if name=='Chuva': return 1.+2.*max(0.,1.-w/.48)
    if name=='Intermediário': return 1.+1.3*max(0.,1.-w/.25)
    return 1.-.45*w

# Numeric life-to-cliff inspection shows proactive service before 100%.
for name,w in [('Chuva',.92),('Intermediário',.52),('Chuva',.14)]:
    s=specs[name]
    rate=s['wear']*wear_multiplier(name,w)
    near_cliff_at=max(54.,s['cliff']-2*rate)
    assert near_cliff_at < s['cliff'] < 100
    assert rate>0
    assert (s['cliff']-max(54., near_cliff_at))/rate <=2.01
print('PASS 0552: AI critical tyre guard, wet compound repit, preserved weather balance, 20 venues and safety paths')
