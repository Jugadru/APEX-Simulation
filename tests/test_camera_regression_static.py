"""Structural regression checks for TV-follow camera repair.
Run locally with: python3 tests/test_camera_regression_static.py
Does not replace a test inside the Godot engine.
"""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
track = (root/'scripts/track_3d.gd').read_text(encoding='utf-8')
main = (root/'scripts/main.gd').read_text(encoding='utf-8')
director = (root/'scripts/tv_director.gd').read_text(encoding='utf-8')
zoom_fn = track.split('func set_zoom(', 1)[1].split('func set_follow(', 1)[0]
assert 'if camera_mode_3d == "overview":' in zoom_fn
assert '_apply_camera()' in zoom_fn
assert 'set_broadcast_view' in track
for style in ('chase','battle','corner','trackside','helicopter'):
    assert 'valid_style == "%s"' % style in track
assert 'world_view.set_broadcast_view' in main
assert 'tv_shot_picker' in main and '_change_tv_shot' in main
assert 'shot_counter' in director and 'camera_style = action_shots[shot_counter % action_shots.size()]' in director
print('CAMERA REGRESSION STATIC OK: no TV-centre reset, 5 angles, manual shot selector')
