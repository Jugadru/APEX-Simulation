"""APEX 0.5.5.1: numeric tuning regression; no Godot executable required."""
from pathlib import Path
import json, math
root = Path(__file__).resolve().parents[1]
physics = (root/'scripts/core/race_wet_physics.gd').read_text(encoding='utf-8')
strategy = (root/'scripts/core/race_strategy.gd').read_text(encoding='utf-8')
specs = json.loads((root/'data/tyres_2012.json').read_text(encoding='utf-8'))['compounds']
assert '23.0 * pow' not in physics, 'old flood penalty persists'
assert '5.0 * pow(maxf(0.0, (w - 0.55) / 0.45), 1.55)' in physics
assert '8.0 * pow(maxf(0.0, 1.0 - w / 0.74), 1.1)' in physics
assert ('float(old_spec.get("delta", 0.0))' in strategy or 'float(current_spec.get("delta", 0.0))' in strategy)
assert 'float(new_spec.get("delta", 0.0))' in strategy

def tyre_cost(name: str, water: float) -> float:
    delta = specs[name]['delta']
    if name == 'Intermediário':
        water_penalty = 5.0*max(0.,1.-water/.24)**1.25 + 5.*max(0.,(water-.55)/.45)**1.55
    elif name == 'Chuva':
        water_penalty = 8.0*max(0.,1.-water/.74)**1.1 + .8*max(0.,(water-.92)/.08)
    else:
        raise ValueError(name)
    return delta + water_penalty
for w in (x/100. for x in range(100, 101)):
    pass
for w in [0.25, 0.40, 0.55, 0.65]:
    assert tyre_cost('Intermediário', w) < tyre_cost('Chuva', w), w
for w in [0.85, 0.90, 0.95, 1.0]:
    assert tyre_cost('Chuva', w) < tyre_cost('Intermediário', w), w
    advantage = tyre_cost('Intermediário', w) - tyre_cost('Chuva', w)
    assert advantage < 2.5, (w, advantage)
    assert advantage*8.0 < 20.0, (w, advantage*8)
assert abs(tyre_cost('Chuva', 0.78)-tyre_cost('Intermediário', 0.78)) < 0.2
print('PASS 0.5.5.1: wet/inter cross-over, 8 lap advantage <20s at 85-100% standing water')
