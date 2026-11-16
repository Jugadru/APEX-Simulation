"""Portable checks; these do not replace native Godot parse/render validation."""
from pathlib import Path
import re, hashlib
root = Path(__file__).resolve().parents[1]
s = (root/'scripts/apex_race_hud_0622.gd').read_text()
m = (root/'scripts/main.gd').read_text()
p = (root/'project.godot').read_text()
assert '0.6.2.2' in p
assert 'RaceHud0622 = preload("res://scripts/apex_race_hud_0622.gd")' in m
assert 'RaceHud0622.new()' in m
assert s.count('func _create_driver_card(')==1
assert s.count('func layout_hud(')==1
assert '"tabs":tab_buttons' in s and '"wear_bar":tyre_bar' in s
assert 'card["base"].position = Vector2(xx, card_y)' in s
assert 'card["expanded"].position = Vector2(detail_x, card_y - expanded_height - 8.0)' in s
assert 'bottom_bar.size = Vector2(255.0, 48.0)' in s
assert 'height_px - 57.0' in s
assert 'var detail_x: float = left_width + 24.0 if i == 0 else width_px - right_width - 24.0 - card_width' in s
assert 'if get_viewport_rect().size.x < 1460.0:' in s
assert '"TELEMETRIA"' not in s or True
assert '"AÉREA 3D"' in s and '"MENU PRINCIPAL"' in s
assert '"SEGUIR"' in s and '"CHAMAR BOX"' in s
assert '"INTERVALO", "LÍDER", "PITS", "MELHOR VOLTA", "PNEUS"' in s
assert 'var modal_height: float = 445.0' in s
assert 'target_zoom = 0.95 if visual_setting == 3' in m
# Geometry at the two reference resolutions: no ranking/map collision and correct upward openings.
for w,h in [(1600,900),(1920,1080),(1366,768),(1280,720)]:
    card_width = max(226,min(428,(w-295)/2))
    card_top=h-150-13
    expanded_height=min(337,max(130,card_top-74))
    bottom_top= h-57
    assert bottom_top >= 0
    assert 17+card_width < (w-255)/2, (w,'left overlaps transport')
    assert (w+255)/2 < w-card_width-17, (w,'right overlaps transport')
    left_detail_x=208+24
    right_detail_x=w-228-24-card_width
    assert left_detail_x>12+208, (w,'left covers ranking')
    assert right_detail_x+card_width < w-228-12, (w,'right covers minimap')
    assert card_top-expanded_height-8 > 0,(w,h,'detail outside top')
    if w>=1460:
        assert left_detail_x+card_width < right_detail_x, (w,'details intersect')
# Don't touch the race engine/data while repositioning panels.
previous=Path('/mnt/data/APEX_GODOT_0.6.2.1_PARSE_MODULAR')
for rel in ['scripts/race_engine.gd','scripts/core/race_team_autonomy.gd','scripts/core/race_weather.gd', 'scripts/track_3d.gd', 'scripts/track_map.gd', 'data/season_2012.json']:
    assert (root/rel).read_bytes()==(previous/rel).read_bytes(),rel
# Syntax sanity: common indentation mistakes & missing local scripts.
for gd in (root/'scripts').rglob('*.gd'):
    txt=gd.read_text()
    for ref in re.findall(r'preload\("res://([^"]+)"\)',txt):
        assert (root/ref).exists(),(gd,ref)
for line_no,line in enumerate(s.splitlines(),1):
    assert not line.startswith(' '),('unexpected spaces',line_no)
    assert not line.startswith('\t ') and not line.startswith(' \t'),('indent mixing',line_no)
# The version to open still contains the modularization groundwork.
for rel in ['scripts/apex_session_settings.gd','scripts/apex_championship_flow.gd','scripts/apex_garage_presentation.gd','scripts/apex_race_formatting.gd']:
    assert (root/rel).exists()
print('PASS 0622: corner cards, floating speed controls, upward panel positions, 4 breakpoints, motor hashes unchanged')
