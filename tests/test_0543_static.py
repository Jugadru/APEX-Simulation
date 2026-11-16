from apex_contracts import check_legacy_garage_contract
"""Standalone static contracts for v0.5.4.3 (not a substitute for Godot)."""
from pathlib import Path
import hashlib, json, re
root=Path(__file__).resolve().parents[1]
engine=(root/'scripts/race_engine.gd').read_text(encoding='utf8')
main=(root/'scripts/main.gd').read_text(encoding='utf8')
combat=(root/'scripts/core/race_combat.gd').read_text(encoding='utf8')
perf=(root/'scripts/core/race_performance.gd').read_text(encoding='utf8')
strategy=(root/'scripts/core/race_strategy.gd').read_text(encoding='utf8')
rules=(root/'scripts/core/race_rules.gd').read_text(encoding='utf8')
assert 'const RacePerformance = preload(' in engine
assert 'const Performance = preload(' not in engine
assert 'PROFILE_CLASSIC' not in '\n'.join((engine,main,combat,perf,strategy,rules))
assert 'sim_profile_picker' not in main
assert 'set_simulation_profile(' not in engine
assert 'simulation_profile := Rules.PROFILE_CORE2' in engine
assert 'return Tyres2012.available(' in engine
assert 'var old_order: Array = []' in engine and 'entry.duplicate(true)' in engine
assert 'pace_metrics[int(old_car["id"])]' in engine
assert 'RacePerformance.evaluate(old_car, context)' in engine
assert 'Strategy.pit_choice(car, lap_count, available_pit_compounds(), tyre_specs,' in engine
for token in ('ATTACKING','CLOSING','PREPARING','DEFENDING','RECOVERING','DUEL','combat_cooldown','combat_duel_time','predicted_ahead','in_passing_zone','result["progress"]'):
    assert token in combat, token
assert not re.search(r'brng.', combat.lower())
assert 'Combat.advance(' in engine
assert 'defenders[int(contest["defender_id"])]' in engine
assert '"combat_attempts"' in engine
assert '"combat_passes"' in engine
assert '"battle"' in engine
assert '"CHAMAR BOX"' in main and '"BOX"' in main
assert (root/'tests/core_0543_combat_smoke_test.gd').is_file()
assert not (root/'tests/fixtures/race_engine_0533.gd').exists(), 'Old engine should not be packaged'
season=json.loads((root/'data/season_2012.json').read_text(encoding='utf8'))
assert len(season['teams'])==12 and len(season['tracks'])==20
cats=json.loads((root/'data/tyres_2012.json').read_text(encoding='utf8'))
assert len(cats['tracks']) == 20
# 3D models, pit-lane mechanics, garage persisted unchanged from the archived v0.5.4.2 release.
expected={
    'scripts/core/race_pit_lane.gd': '13526f7863021755534c1fc5f6831359fe5bd8634e156752210b4d316488a487',
    'scripts/core/race_pit_math.gd': '645c7a4bdf58d3a441d7fe09531dd794a411320ee3081c8ecc1fafbceba63268',
    'scripts/track_3d.gd': 'a90bcddab446cfa8b1ae745c569d3c26b9a9d9d51596e608d98924c34caf77fd',
    'scripts/pit_complex_3d.gd': 'c35eabd4fbb08fdbea95b5584a8b0f31bade7d1c5f41bdf15b7689b0d72b3587',
}
check_legacy_garage_contract(root)
for rel, old_hash in expected.items():
    if old_hash != 'PLACEHOLDER':
        assert hashlib.sha256((root/rel).read_bytes()).hexdigest() == old_hash, f'Unexpected gameplay regression: {rel}'
print('PASS: Core 2 único, estados de disputa, 2012, pit lane e HUD estáveis')
