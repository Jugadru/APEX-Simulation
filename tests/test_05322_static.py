"""Source and geometric invariants for the 0.5.3.2.2 HUD hotfix.
Offline only; use hud_05322_ui_test.gd in Godot for scene validation.
"""
from pathlib import Path
import hashlib
root=Path(__file__).resolve().parents[1]
source=(root/'scripts/main.gd').read_text(encoding='utf-8')
for required in (
    'func _effective_hud_layout()', 'func _card_folded(',
    'func _toggle_driver_card(', 'func _toggle_all_driver_cards()',
    'func _layout_ui()', '"broadcast_layout"',
    '"driver_card_%d_folded"', '"Auto", "Completa", "Compacta", "Cinema"',
    'var details := VBoxContainer.new()', 'card["details"].visible = not folded',
    'bottom_bar.position.y - total_height - 10.0',
    '"tire": tire_picker', '_request_pit.bind(', 'KEY_V',
):
    assert required in source, f'missing HUD element: {required}'
assert 'player_card_strip.add_theme_constant_override("separation"' not in source
assert 'two balanced rows' not in source
engine_files=[
    'race_engine.gd','garage.gd','track_map.gd','track_3d.gd',
    'car_model_3d.gd','pit_complex_3d.gd','tv_director.gd',
    'pit_analytics_chart.gd','apex_mini_map.gd','apex_track_conditions.gd',
    'apex_portrait_manager.gd',
]
previous=root.parent/'APEX_GODOT_0.5.3.2.1'/'scripts'
if previous.is_dir():
    for file in engine_files:
        assert hashlib.sha256((root/'scripts'/file).read_bytes()).digest()==hashlib.sha256((previous/file).read_bytes()).digest(),file

def rectangles(width,height,mode,folded=(False,False)):
    compact=(mode==2) or (mode==0 and (width<1500 or height<850))
    cinema=mode==3
    left_width=450 if width>=1650 else (405 if width>=1320 else 323)
    right_width=420 if width>=1550 else (390 if width>=1280 else 315)
    if compact:
        left_width=min(left_width,330)
        right_width=min(right_width,325)
    left=(10,124,left_width,height-70-124-10)
    right=(width-10-right_width,124,right_width,height-70-124-10)
    mx=10+left_width+12 if not cinema else 16
    rx=width-10-right_width-12 if not cinema else width-16
    avail=max(160,rx-mx)
    stacked=avail<510
    card_width=min(318,max(205,(avail-12)/2))
    if stacked: card_width=min(340,avail)
    heights=[86 if fold else 215 for fold in folded]
    total_height=sum(heights)+12 if stacked else max(heights)
    total_width=card_width if stacked else card_width*2+12
    cx=mx+max(0,(avail-total_width)/2)
    cy=max(132,height-70-total_height-10)
    cards=[]
    for i in range(2):
        x=cx if stacked else cx+i*(card_width+12)
        y=cy+(sum(heights[:i])+12*i if stacked else 0)
        cards.append((x,y,card_width,heights[i]))
    return left,right,cards,height-70

def intersects(a,b):
    ax,ay,aw,ah=a
    bx,by,bw,bh=b
    return ax<bx+bw and ax+aw>bx and ay<by+bh and ay+ah>by
for w,h in [(900,600),(1024,768),(1280,720),(1366,768),(1600,900),(1920,1080)]:
    compact=w<1500 or h<850
    folded=(True,True)
    left,right,cards,bottom=rectangles(w,h,0,folded)
    for c in cards:
        assert not intersects(c,left) and not intersects(c,right), (w,h,c,left,right)
        assert c[1]+c[3]<=bottom+0.1,(w,h,c,bottom)
    if h>=720:
        left,right,cards,bottom=rectangles(w,h,1,(False,False))
        for c in cards:
            assert not intersects(c,left) and not intersects(c,right),(w,h,c)
            assert c[1]+c[3]<=bottom+0.1,(w,h,c,bottom)
print('PASS: broadcast HUD controls, responsive layout on 6 sizes, motor/3D unchanged')
