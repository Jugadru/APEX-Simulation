"""Offline checks; does not replace executing GDScript in Godot."""
from pathlib import Path
import hashlib, re, json
root=Path(__file__).resolve().parents[1]
base=Path('/mnt/data/apex_build_0525/APEX_GODOT_0.5.2.4.3')
def get(rel): return (root/rel).read_text(encoding='utf-8')
engine=get('scripts/race_engine.gd')
pit=get('scripts/pit_complex_3d.gd')
track=get('scripts/track_3d.gd')
car=get('scripts/car_model_3d.gd')
main=get('scripts/main.gd')
if base.is_dir():
    for name in ['scripts/track_map.gd','data/season_2012.json','scripts/tv_director.gd']:
        assert hashlib.sha256((root/name).read_bytes()).digest()==hashlib.sha256((base/name).read_bytes()).digest(), f'Approved file changed: {name}'
else:
    print('SKIP: external v0.5.2.4.3 archive unavailable; test_0533_static.py checks frozen source fingerprints')
assert len(json.loads(get('data/season_2012.json'))['teams'])==12
assert len(json.loads(get('data/season_2012.json'))['tracks'])==20
assert float(re.search(r'PIT_SERVICE_BEGIN: float = ([.0-9]+)', engine).group(1))==float(re.search(r'STOP_START: float = ([.0-9]+)', pit).group(1))
assert float(re.search(r'PIT_SERVICE_END: float = ([.0-9]+)', engine).group(1))==float(re.search(r'STOP_END: float = ([.0-9]+)', pit).group(1))
for wanted in ['pit_service_total','pit_service_elapsed','pit_service_complete','pit_old_tire', 'pit_last_service','car["tire"] = str(car["pit_target"])']:
    assert wanted in engine, wanted
for wanted in ['crew_rigs','Mecanico_','ToolArm','PneuNovo','update_pit_services','service_labels','stop_position','team_paths']:
    assert wanted in pit, wanted
for wanted in ['update_pit_services(servicing_cars','set_pit_wheel_swap','set_tire_compound']:
    assert wanted in track, wanted
for wanted in ['CompoundStripe','set_pit_wheel_swap','set_tire_compound']:
    assert wanted in car, wanted
for wanted in ['pit_timer_label','pit_service_elapsed','pit_service_total','CRONÔMETRO BOX']:
    assert wanted in main, wanted
assert 'PitComplexScript.new()' in track
print('APEX 0.5.2.5 STATIC OK: approved race visuals retained, crew, wheel swap and pit stopwatch integrated.')
