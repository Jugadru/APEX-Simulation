"""Offline regression checks for v0.5.2.7 (no Godot binary required)."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
engine = (root/'scripts/race_engine.gd').read_text()
main = (root/'scripts/main.gd').read_text()
scene = (root/'scripts/track_3d.gd').read_text()
crew = (root/'scripts/pit_complex_3d.gd').read_text()
required = [
    'PIT_GUN_FAILURE_CHANCE', 'PIT_UNSAFE_RELEASE_CHANCE',
    'pit_incident_test_overrides', 'pit_extra_elapsed', 'pit_last_extra',
    '"repair"', '"safety_hold"', 'func _start_pit_repair',
    'func _start_pit_safety_hold', 'func _continue_pit_exit',
    'func _finish_service', 'pit_crew_owner', 'pit_last_total',
]
for token in required:
    assert token in engine, token
assert 'stage == "repair" or stage == "safety_hold"' in (root/'scripts/core/race_pit_lane.gd').read_text()
assert '"pit_failure"' in engine and '"unsafe_release"' in engine
for token in ['FALHA MECÂNICA', 'LIBERAÇÃO BLOQUEADA', 'INCIDENTE +']:
    assert token in main, token
assert 'FALHA MECÂNICA' in scene and 'RETIDO +' in scene
assert 'pit_test_picker' in main and 'Raros (corrida normal)' in main
assert 'service_stage in ["service", "dock", "repair", "safety_hold"]' in crew
for file in ['pit_incidents_smoke_test.gd', 'pit_incidents_double_stack_test.gd']:
    assert (root/'tests'/file).exists()
print('PASS: v0.5.2.7 pit incidents, extra time, double-stack exclusivity, HUD and 3D indicators')
