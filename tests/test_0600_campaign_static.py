"""Portable structural coverage for 0.6.0 (Godot runtime separately required)."""
from pathlib import Path
import json
from hashlib import sha256
from apex_contracts import check_build_version, check_legacy_garage_contract, check_0580_mechanics
r=Path(__file__).resolve().parents[1]
check_build_version(r,'0.6.0')
check_0580_mechanics(r)
check_legacy_garage_contract(r)
main=(r/'scripts/main.gd').read_text()
season=(r/'scripts/championship_2012.gd').read_text()
garage=(r/'scripts/garage.gd').read_text()
assert (r/'tests/core_0600_championship_smoke_test.gd').exists()
for token in ('ChampionshipScript.new()', 'func _resume_championship()', 'func _commit_championship_result()', 'func _show_championship_table()', 'func _reconcile_championship_rewards()', 'if championship_race_active:', 'championship.record_result(race.track, race.get_sorted(), race.clock)', 'championship.round_seed()', 'menu_column.add_child(menu_actions)', 'start_button = _button(menu_actions,'):
 assert token in main,token
for token in ('const POINTS := [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]', 'func record_result(', 'func start_new(', 'func load_save()', 'func standings(', '"calendar": calendar', 'updated["round_index"] = history.size()', 'func is_complete()', 'DirAccess.rename_absolute', 'if unique.size() != dp.size()'):
 assert token in season,token
for token in ('func credit_championship_prize(', '"championship_awards": raw_awards.duplicate(true)', 'if team["championship_awards"].has(award_id):', 'team["budget"] = int(team["budget"]) + amount'):
 assert token in garage,token
js=json.loads((r/'data/season_2012.json').read_text())
assert len(js['tracks'])==20 and len(js['teams'])==12 and sum(len(t['drivers']) for t in js['teams'])==24
assert main.count('func _start_race()')==1 and main.count('func _toggle_race()')==1
print('PASS 0600: menu, progression, scoring, saving, idempotent rewards, 2012 data, legacy physics preserved')
