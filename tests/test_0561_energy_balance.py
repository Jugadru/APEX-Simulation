"""Offline numeric regression for APEX 0.5.6.1 tactical KERS and local DRS.
Uses published GDScript constants. Runtime test mirrors actual Godot calls.
"""
from pathlib import Path
import re, ast
root=Path(__file__).resolve().parents[1]
source=(root/'scripts/core/race_kers_2012.gd').read_text()
performance=(root/'scripts/core/race_performance.gd').read_text()
engine=(root/'scripts/race_engine.gd').read_text()
ui=(root/'scripts/main.gd').read_text()

def constant(name):
    m=re.search(r'^const '+name+r'\s*:?=\s*(.*)$',source,re.MULTILINE)
    assert m, name
    value=m.group(1)
    if value.startswith('{') and not value.endswith('}'):
        value=value+source[m.end():].split('\n}',1)[0]+'\n}'
    return ast.literal_eval(value)

windows=constant('BURST_WINDOWS')
kw=constant('MODE_POWER_KW')
budget=constant('MODE_ZONE_ENERGY_KJ')
assert len(windows)==3
assert 0.0<windows[0][0]<windows[0][1]<windows[1][0]<windows[1][1]<windows[2][0]<windows[2][1]<1.0
assert kw=={'Economizar':18.0,'Equilibrado':40.0,'Atacar':60.0}
assert max(kw.values()) <= 60.0
for mode in kw:
    assert sum(budget[mode])<=400.0001
    assert len(budget[mode])==3
    assert max(budget[mode])<200, 'cannot use most energy in the first straight'

# Replay one entire lap at 0.2s integration using the exact zone budgets,
# powers and window positions specified in the GDScript module.
results={}
for mode in kw:
    remaining=400.0
    zone_spent=[0.,0.,0.]
    active_seconds=0.
    episodes=[]
    gained=0.
    for n in range(550):
        dt=0.2
        frac=(n*dt)/110
        zone=next((i for i,(a,b) in enumerate(windows) if a<=frac<=b),None)
        used=0.0
        if zone is not None:
            used=min(remaining, budget[mode][zone]-zone_spent[zone], kw[mode]*dt)
            used=max(0.,used)
            zone_spent[zone]+=used
            remaining-=used
        if used:
            if not episodes or episodes[-1] != zone:
                episodes.append(zone)
            active_seconds += used / kw[mode]
            eff={'Economizar':0.64,'Equilibrado':0.90,'Atacar':1.12}[mode]
            local_bonus = 6.55 * (used/dt/60.0) * eff
            boosted=110.0-local_bonus
            gained += dt * local_bonus/boosted
    results[mode]={'energy_kj':400-remaining,'powered_seconds':active_seconds,'zones':episodes,'gain_s':gained}
    assert episodes==[0,1,2],(mode,episodes)
    assert remaining>0.0 if mode=='Economizar' else abs(remaining)<0.001
    assert 400-remaining<=400.001
assert results['Economizar']['powered_seconds']>results['Equilibrado']['powered_seconds']>results['Atacar']['powered_seconds']
assert results['Atacar']['gain_s']>results['Equilibrado']['gain_s']>results['Economizar']['gain_s']
assert results['Atacar']['gain_s'] < 0.8 # not game-breaking
assert 'context.get("kers_power_kw"' in performance
assert 'var drs: float = -3.40' in performance
assert 'context["kers_power_kw"]' in engine
assert 'kers_gain_lap_s' in ui and 'drs_gain_lap_s' in ui
print('PASS: KERS 3 distinct modes, 3 bursts/lap, 60kW/400kJ ceilings, DRS pace & metrics')
for name, data in results.items():
    print('  ',name,':', {k:round(v,3) if isinstance(v,float) else v for k,v in data.items()})
