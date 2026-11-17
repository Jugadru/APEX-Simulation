"""Regression guard for the GDScript indentation error in v0.6.1.1."""
from pathlib import Path
import hashlib
import sys

ROOT = Path(__file__).resolve().parents[1]
gd_files = sorted(ROOT.rglob('*.gd'))
assert gd_files, 'GDScript files missing'
problems = []
for src in gd_files:
    text = src.read_text(encoding='utf-8')
    # Tabs and spaces used as competing indentation styles in the same file
    # are rejected here to prevent the exact bug that hit track_map.gd.
    tab_lines = [i for i, ln in enumerate(text.splitlines(), 1) if ln.startswith('\t')]
    space_lines = [i for i, ln in enumerate(text.splitlines(), 1)
                   if ln.startswith(' ') and ln.lstrip()]
    if tab_lines and space_lines:
        problems.append(f'{src.relative_to(ROOT)}: tab/space indentation mix (spaces at {space_lines[:10]})')
    # Reject non-multiple-of-four leading spaces even in otherwise space-only files.
    for i, ln in enumerate(text.splitlines(), 1):
        if ln.startswith(' ') and ln.lstrip() and (len(ln) - len(ln.lstrip(' '))) % 4:
            problems.append(f'{src.relative_to(ROOT)}:{i}: inconsistent space depth')
track_map = (ROOT / 'scripts' / 'track_map.gd').read_text(encoding='utf-8')
start = track_map.index('func _draw_strategic_circuit() -> void:')
end = track_map.index('func _draw_close_circuit() -> void:', start)
block = track_map[start:end]
assert '\tdraw_polyline(route' in block
assert 'func _draw_dot(' in track_map
assert 'func point_on_track(' in track_map
assert not problems, '\n'.join(problems)
assert (ROOT / 'project.godot').exists()
assert (ROOT / 'scenes' / 'main.tscn').exists()
print(f'PASS: indentation and strategic-map regression across {len(gd_files)} GDScript files')
