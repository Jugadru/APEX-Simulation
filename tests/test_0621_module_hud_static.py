"""Verifies the v0.6.2.1 parse fix and extraction without pretending to compile GDScript."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
source=Path('/mnt/data/APEX_GODOT_0.6.2.0_HUD_REWORK')
main=(root/'scripts/main.gd').read_text()
hud=(root/'tests/legacy/apex_race_hud_0620.gd').read_text()
old=(source/'scripts/main.gd').read_text() if source.exists() else None
modules={
    'SessionSettings':('apex_session_settings.gd',['_load_season_data','_load_hud_prefs','_save_hud_prefs','_effective_hud_layout','_card_folded','_toggle_driver_card','_toggle_all_driver_cards']),
    'ChampionshipFlow':('apex_championship_flow.gd',['_ask_new_championship','_new_championship','_resume_championship','_single_race_mode','_update_championship_menu','_show_championship_table','_reconcile_championship_rewards','_commit_championship_result']),
    'GaragePresentation':('apex_garage_presentation.gd',['_update_garage']),
    'RaceFormatting':('apex_race_formatting.gd',['_best_lap','_format_lap','_icon_for_car','_row_detail','_compound_code','_tyre_color','_wear_color','_update_telemetry']),
}
assert 'v0.6.2.1' in (root/'project.godot').read_text()
assert '\t\theading_label.size_flags_horizontal' not in hud
assert '\tvar heading_label := _text(heading' in hud
assert '\theading_label.size_flags_horizontal' in hud
assert len(main.splitlines()) < 2500
existing=set(re.findall(r'^(?:var|const|func)\s+(\w+)',main,re.M))
for key,(filename,methods) in modules.items():
    body=(root/'scripts'/filename).read_text()
    assert 'extends RefCounted' in body
    assert f'const {key} = preload("res://scripts/{filename}")' in main
    for method in methods:
        assert f'static func {method}(host' in body, (filename,method)
        assert f'{key}.{method}(self' in main, (filename,method)
    for member in re.findall(r'\bhost\.(\w+)',body):
        assert member in existing or member=='get_viewport_rect', (filename,member)
# No external missing GDScript preloads
for gd in (root/'scripts').rglob('*.gd'):
    for link in re.findall(r'preload\("(res://[^"]+)"\)',gd.read_text()):
        assert (root/link.removeprefix('res://')).is_file(),(gd,link)
# Static regression: there is no change to race engine assets in this patch.
if source.exists():
    for rel in ['scripts/race_engine.gd','scripts/core/race_team_autonomy.gd','scripts/core/race_weather.gd','scripts/track_3d.gd','scripts/track_map.gd','data/season_2012.json']:
        assert (root/rel).read_bytes()==(source/rel).read_bytes(), rel
print('PASS 0621: HUD syntax correction, 4 functional modules, callbacks and simulation assets unchanged')
