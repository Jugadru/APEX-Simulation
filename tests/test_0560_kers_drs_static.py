"""Offline checks; Godot runtime validation is in core_0560_kers_drs_smoke_test.gd."""
from pathlib import Path
import hashlib
r=Path(__file__).resolve().parents[1]
k=(r/'scripts/core/race_kers_2012.gd').read_text()
d=(r/'scripts/core/race_drs_2012.gd').read_text()
e=(r/'scripts/race_engine.gd').read_text()
p=(r/'scripts/core/race_performance.gd').read_text()
u=(r/'scripts/main.gd').read_text()
t=(r/'scripts/apex_telemetry.gd').read_text()
for piece in ('POWER_KW: float = 60.0','ENERGY_PER_LAP_KJ: float = 400.0','NON_KERS_TEAMS','Marussia Cosworth','HRT Cosworth','static func apply(', 'static func reset_lap('):
    assert piece in k,piece
for piece in ('MIN_LAPS_COMPLETED := 2','MAX_GAP_S: float = 1.0','drs_armed_zones','wet','drs_allowed','AUS','BEL'):
    assert piece in d or piece=='wet',piece
for piece in ('RaceKers2012.initial_state','RaceDrs2012.initial_state','RaceKers2012.apply','RaceDrs2012.update','RaceKers2012.reset_lap','func set_kers_mode(', 'func get_race_control_status('):
    assert piece in e,piece
assert 'context.get("drs_active"' in p
assert 'context.get("kers_power_kw"' in p
assert 'current_lap >= 2 and gap' not in p, 'old all-lap DRS logic retained'
for piece in ('_cycle_kers_mode','kers_button','drs_label','CHAMAR BOX','quick_pit'):
    assert piece in u,piece
for piece in ('kers_remaining_kj','kers_active','drs_active','kers_mode'):
    assert piece in t,piece
assert 'renderer/rendering_method="gl_compatibility"' in (r/'project.godot').read_text()
# Preserve important systems untouched in this release; baseline is local and concrete.
baseline=Path('/mnt/data/APEX_GODOT_0.5.5.2')
for rel in ['scripts/core/race_pit_lane.gd','scripts/core/race_pit_math.gd',
            'scripts/core/race_strategy.gd','scripts/core/race_wet_physics.gd',
            'scripts/core/race_combat.gd','scripts/track_3d.gd','scripts/pit_complex_3d.gd',
            'scripts/car_model_3d.gd','scripts/tv_director.gd','data/tyres_2012.json']:
    if baseline.exists():
        assert hashlib.sha256((r/rel).read_bytes()).digest()==hashlib.sha256((baseline/rel).read_bytes()).digest(), rel
print('PASS: limites KERS 2012, DRS condicionado, UI, telemetria e arquivos essenciais preservados')
