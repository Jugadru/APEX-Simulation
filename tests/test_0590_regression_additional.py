#!/usr/bin/env python3
"""0.5.9.0 team-control regression assertions (static; run native smoke in Godot)."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
main=(root/'scripts/main.gd').read_text()
engine=(root/'scripts/race_engine.gd').read_text()
auto=(root/'scripts/core/race_team_autonomy.gd').read_text()
garage=(root/'scripts/garage.gd').read_text()
# Two independent driver pit modes become IA only when the global control is Auto.
assert 'for car in race.player_cars():' in main
assert 'race.set_pit_control_mode(int(car["id"]), "IA" if mode == "Automático" else "Manual")' in main
# The game's pit planner must still block autonomous earlier stops when a manual stop is scheduled.
assert 'int(car.get("pit_scheduled_lap", 0)) > 0' in engine
assert 'func schedule_pit(car_id: int, target: String, target_lap: int) -> bool' in engine
# UI must allow changing global mode mid-race.
assert 'live_team_mode_picker = _option(controls,' in main
assert 'func _select_live_team_mode(index: int)' in main
# Save migration: older teams need 0-level staff without resetting old level/budget/crew.
for item in ('"budget": maxi(0, int(state.get("budget", INITIAL_BUDGET)))',
             '"levels": cleaned', '"crew_levels": cleaned_crew', '"staff_levels": cleaned_staff'):
    assert item in garage, item
# Staff logic decisions must remain bounded and not contain direct pit calls.
assert 'clampi(int(staff.get("Engenheiro", 0)), 0, 3)' in auto
assert 'clampi(int(staff.get("Estrategista", 0)), 0, 3)' in auto
assert 'order_pit(' not in auto
assert 'set_pit_control_mode(' not in auto
print('PASS: team manual/auto, separate manual pit schedule, staff and legacy saves')
