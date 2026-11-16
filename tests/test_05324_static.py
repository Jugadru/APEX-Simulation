from apex_contracts import check_build_version, check_legacy_garage_contract
"""Offline contract test for the F1M-inspired controls and native commentary."""
from pathlib import Path
import hashlib
root=Path(__file__).resolve().parents[1]
main=(root/'scripts/main.gd').read_text(encoding='utf-8')
commentary=(root/'scripts/apex_commentary.gd').read_text(encoding='utf-8')
timeline=(root/'scripts/apex_stint_timeline.gd').read_text(encoding='utf-8')
project=(root/'project.godot').read_text(encoding='utf-8')
check_build_version(root, '0.5.3.2.4')
# The only pit-call entrypoints are the bottom driver cards; no command in the pit-wall tabs.
card=main.split('func _create_player_card(',1)[1].split('func _driver_initials(',1)[0]
assert card.count('_request_pit.bind(')==2 # one expanded, one folded
assert 'CHAMAR BOX' in card and 'quick_pit' in card
assert '"pace": pace_picker' in card and '"tire": tire_picker' in card
assert 'func _build_driver_strategy(' not in main
strategy_ui=main.split('var strategy_tab := ScrollContainer.new()',1)[1].split('var radio_tab := VBoxContainer.new()',1)[0]
assert '_request_pit.bind(' not in strategy_ui
assert 'StrategyTimelineScript.new()' in strategy_ui
for key in ('strategy_stints.update_cars','_refresh_car_diagnostics','diagnostic_primary','diagnostic_secondary',
            '_set_radio_filter','_render_commentary','"Pista"','_refresh_pitwall_summary',
            'pitwall_summary_body','radio_filter_buttons'):
    assert key in main, key
for category in ('"grid"','"pass"','"lead"','"pit"','"pit_failure"','"double_stack"','"pit_exit"','"wear"'):
    assert category in commentary, category
for role in ('NARRADOR','ANALISTA','BOXES','ENGENHEIRO'):
    assert role in commentary, role
assert 'MAX_LINES: int = 72' in commentary
assert 'update_cars(cars: Array, lap_count: int, history: Array = [])' in timeline
# Approved physical simulation unchanged; telemetry hooks are tested separately.
sha256={

'track_map.gd':'11a4cf845cf9f077be022b537a4c9b94ad2afa41e4f6043c035238d39cf56410',
'track_3d.gd':'a90bcddab446cfa8b1ae745c569d3c26b9a9d9d51596e608d98924c34caf77fd',
'car_model_3d.gd':'1ab76995515e728fca0745fe30e9ff3bb3073e42376d15503f4de1c5c7c627d5',
'pit_complex_3d.gd':'c35eabd4fbb08fdbea95b5584a8b0f31bade7d1c5f41bdf15b7689b0d72b3587',
'tv_director.gd':'6fb42841214235ec0b1458558803edb3afb43be0e1ab2536daeb67ee756ae7ce',
'pit_analytics_chart.gd':'a55ec381bdc701170db37636333282114a305cfd52c76411e5f275a0cc02595d',
'apex_mini_map.gd':'7ffd8d5b31fc22328ade16b717c9aeb80065dfdb18c4111c3f5f82a3159e93da',
'apex_track_conditions.gd':'37e1bd4538465f0ef30b7b6aacb30f5b905c96a428433507e4a4b1a95982b322',
}
# Check archived engine hashes from the base build directly; ignore entries
# not listed in the baseline (the UI-specific portrait manager has its own tests).
check_legacy_garage_contract(root)
for name, expected in sha256.items():
    assert hashlib.sha256((root/'scripts'/name).read_bytes()).hexdigest()==expected,name
print('PASS: v0.5.3.2.4 UI commands, commentary, car diagnostics, strategy and preserved engine')
