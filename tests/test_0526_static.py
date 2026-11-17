"""Offline regression checks for Double Stack integration (not a Godot runtime test)."""
from pathlib import Path
import re, hashlib, json
root=Path(__file__).resolve().parents[1]
read=lambda path:(root/path).read_text(encoding='utf-8')
engine=read('scripts/race_engine.gd')
visual=read('scripts/track_3d.gd')
pit=read('scripts/pit_complex_3d.gd')
main=read('scripts/main.gd')
assert len(json.loads(read('data/season_2012.json'))['teams'])==12
assert len(json.loads(read('data/season_2012.json'))['tracks'])==20
for token in ['PIT_QUEUE_PHASE','pit_crew_owner','pit_last_wait','pit_last_total','"queue"','get_team_pit_status','_garage_available','_release_garage','_advance_pit']:
    assert token in engine,token
for token in ['"stage": stage','QueueTag','FILA +%.1fs','pit_wait']:
    assert token in visual,token
for token in ['update_pit_services','service_frames','"service": 3','service_stage in ["service", "dock", "repair", "safety_hold"]']:
    assert token in pit,token
for token in ['DOUBLE STACK','NA FILA','pit_wait','pit_stage']:
    assert token in main,token
assert float(re.search(r'PIT_SERVICE_BEGIN: float = ([.0-9]+)', engine).group(1))==float(re.search(r'STOP_START: float = ([.0-9]+)',pit).group(1))
assert float(re.search(r'PIT_SERVICE_END: float = ([.0-9]+)', engine).group(1))==float(re.search(r'STOP_END: float = ([.0-9]+)',pit).group(1))
assert 0.0 < float(re.search(r'PIT_QUEUE_PHASE: float = ([.0-9]+)',engine).group(1)) < 0.43
# Immutable approved systems: compare against the SHA-256 hashes of the
# previously distributed v0.5.2.5, so the checks work on the user's PC.
approved_sha256 = {
    'scripts/track_map.gd': '11a4cf845cf9f077be022b537a4c9b94ad2afa41e4f6043c035238d39cf56410',
    # garage.gd intentionally evolves in v0.5.2.8 to persist mechanic training.
    'scripts/tv_director.gd': '6fb42841214235ec0b1458558803edb3afb43be0e1ab2536daeb67ee756ae7ce',
    'scripts/car_model_3d.gd': '1ab76995515e728fca0745fe30e9ff3bb3073e42376d15503f4de1c5c7c627d5',
    'data/season_2012.json': 'a03843f9ac2b818bdb98a3d3417e42f40d792064b48df4334bf008e2828f94eb',
}
for name, expected_hash in approved_sha256.items():
    assert hashlib.sha256((root/name).read_bytes()).hexdigest() == expected_hash, f'Approved content changed: {name}'
print('APEX 0.5.2.6 regression OK: one garage per team, queue, UI, tire crew, 2012 contents.')
