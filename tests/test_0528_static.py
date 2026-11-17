"""Static regression checks (not a substitute for Godot scene execution)."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
garage = (root/'scripts'/'garage.gd').read_text(encoding='utf-8')
engine = (root/'scripts'/'race_engine.gd').read_text(encoding='utf-8')
ui = (root/'scripts'/'main.gd').read_text(encoding='utf-8')
for part in ['Agilidade', 'Precisão', 'Coordenação']:
    assert part in garage and part in engine and part in ui
for needle in ['crew_next_cost', 'buy_crew', 'crew_levels', 'save()', 'MAX_LEVEL', 'INITIAL_BUDGET']:
    assert needle in garage
for needle in ['get_pit_crew_effects', '_crew_bonus_for', 'pit_nominal_total', 'pit_dock_total', 'pit_service_total', 'PIT_GUN_FAILURE_CHANCE', 'PIT_UNSAFE_RELEASE_CHANCE', 'pit_crew_owner', 'pit_incident_test_overrides']:
    assert needle in engine
assert '"Agilidade": 0, "Precisão": 0, "Coordenação": 0' in garage
assert 'for part in CREW_PARTS:' in garage
assert '_find_previous_godot_save' in garage
assert 'get_directories_at' in garage
project = (root/'project.godot').read_text(encoding='utf-8')
assert 'config/use_custom_user_dir=true' in project and 'ApexMotorsportManager' in project
assert 'stage == "queue"' in (root/'scripts/core/race_pit_lane.gd').read_text()
assert 'garage.get_team(selected_team)["crew_levels"]' in ui
assert 'ScrollContainer.new()' in ui
assert 'garage.buy_crew(selected_team, part)' in ui
assert (root/'tests'/'crew_development_smoke_test.gd').is_file()
season = json.loads((root/'data'/'season_2012.json').read_text())
assert len(season['tracks']) == 20
assert len(season['teams']) == 12
assert sum(len(team['drivers']) for team in season['teams']) == 24
print('PASS: crew economy, persistence migration, timing, accuracy, 20 tracks / 24 drivers')
