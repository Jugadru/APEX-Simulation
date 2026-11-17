from pathlib import Path
import hashlib
root=Path(__file__).resolve().parents[1]
theme=(root/'scripts/apex_hud_theme.gd').read_text(encoding='utf-8')
main=(root/'scripts/main.gd').read_text(encoding='utf-8')
assert 'for class_name in' not in theme, 'Reserved GDScript identifier remains'
assert 'for control_type in ["Button", "OptionButton"]:' in theme
assert ', control_type,' in theme
assert 'const HudThemeScript = preload("res://scripts/apex_hud_theme.gd")' in main
assert 'screen.theme = HudThemeScript.build()' in main
for file in ('race_engine.gd','pit_complex_3d.gd','track_3d.gd','car_model_3d.gd','track_map.gd'):
    previous=Path('/mnt/data/APEX_GODOT_0.5.3.0/scripts')/file
    now=root/'scripts'/file
    if previous.exists():
        assert now.read_bytes()==previous.read_bytes(), file + ' altered unexpectedly'
print('HUD source hotfix OK: reserved keyword removed, theme connected, gameplay preserved')
