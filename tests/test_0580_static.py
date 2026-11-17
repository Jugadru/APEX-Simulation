"""Offline architectural and regression checks for APEX 0.5.8.0."""
from pathlib import Path
from hashlib import sha256

root = Path(__file__).resolve().parents[1]
# Original 0.5.7.0 digests, embedded to make this test portable.
ORIGINAL_0570_SHA256 = {
    'scripts/core/race_performance.gd': '5e948faea13a0bc6f550aa1f5f74b8382a21923f0f0dee5156f60a24a7087ada',

    'scripts/core/race_wet_physics.gd': 'b0d334bc15e506734c654b065915acc17d4eaff7b23885ca63f66871e4a7ecbf',

    'scripts/core/race_kers_2012.gd': 'd983fc5c788cfa7671b6fdb4de2094c7cf1b66e487826a8b0d4042972ec5fa2b',

    'scripts/core/race_drs_2012.gd': 'a00e4a6bf132543f1c6b2ffad340141c85e9fa809cb8e9d8bd34d80bdd3b1f59',

    'scripts/core/race_pit_lane.gd': '13526f7863021755534c1fc5f6831359fe5bd8634e156752210b4d316488a487',

    'scripts/core/race_pit_math.gd': '645c7a4bdf58d3a441d7fe09531dd794a411320ee3081c8ecc1fafbceba63268',

    'data/tyres_2012.json': '4de4eda11de68126b96f518160f779da68f969aa0b47b8c659fd1bd4d9abfd38'
}
engine = (root/'scripts/race_engine.gd').read_text()
ui = (root/'scripts/main.gd').read_text()
combat = (root/'scripts/core/race_combat.gd').read_text()
geometry = (root/'scripts/core/race_battle_geometry.gd').read_text()

assert 'func schedule_pit(car_id: int, target: String, target_lap: int) -> bool:' in engine
assert 'func cancel_scheduled_pit(car_id: int) -> bool:' in engine
assert 'scheduled_lap > 0 and exact_lap == scheduled_lap' in engine
assert 'car["pit_scheduled_lap"] = 0' in engine
assert 'car["pit_order_source"] = "ordem_imediata"' in engine
assert 'str(car.get("pit_order_source", "desconhecida"))' in engine
assert 'sem antecipação' in engine
assert 'AGENDAR BOX' in ui and 'SpinBox.new()' in ui and '_schedule_pit(' in ui
assert '_cancel_scheduled_pit(' in ui
assert 'get_engineer_advice(int(car["id"]))' in ui
assert 'BattleGeometry.evaluate(car, ahead, track)' in combat
assert 'combat_hesitation_s' in engine and 'combat_hesitation_s' in combat
assert 'outcome == "contact"' in combat
assert 'risk > 74.0 and awareness < 70.0' in geometry
assert 'GAMEPLAY_WIDTH_M' in geometry
assert 'set_pit_control_mode(car_id: int, mode: String)' in engine
assert '"pit_control_mode": "Manual"' in engine
assert 'and str(car.get("pit_control_mode", "Manual")) != "IA"' in engine
assert 'CONTROLE DE BOX' in ui and '_change_pit_mode(' in ui
assert (root/'tests/core_0580_pit_and_geometry_smoke_test.gd').exists()
# Core race physics and 2012 energy systems untouched. Keep existing handling.
for name in ('scripts/core/race_performance.gd', 'scripts/core/race_wet_physics.gd',
             'scripts/core/race_kers_2012.gd', 'scripts/core/race_drs_2012.gd',
             'scripts/core/race_pit_lane.gd', 'scripts/core/race_pit_math.gd',
             'data/tyres_2012.json'):
    assert sha256((root/name).read_bytes()).hexdigest() == ORIGINAL_0570_SHA256[name], name
print('PASS 0580: scheduled pit, UI, battle geometry, cause audit, legacy physics checks')
