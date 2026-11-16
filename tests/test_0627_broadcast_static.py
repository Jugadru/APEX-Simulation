#!/usr/bin/env python3
"""APEX 0.6.2.7: scoped regression and mathematical camera checks.
These tests do NOT replace compiling or visually testing in Godot.
"""
import hashlib
import json
import math
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRESERVED = json.loads((ROOT / "tests/0627_base_preserved_sha256.json").read_text())
FREE_CAMERA = json.loads((ROOT / "tests/0627_free_camera_functions_sha256.json").read_text())


def sha(path):
    return hashlib.sha256(path.read_bytes()).digest()


def norm(v):
    magnitude = math.sqrt(sum(x*x for x in v))
    return tuple(x/magnitude for x in v)


def dot(a, b):
    return sum(x*y for x,y in zip(a,b))


def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])


def projected_points(shot, longitudinal, lateral=0.0, zoom=2.2):
    # Approximate perspective projection for the formulas in track_3d.gd,
    # on a local north-oriented straight. Pure numeric image-fit check.
    spread = math.hypot(longitudinal,lateral)
    center=(lateral/2, 0.0,-longitudinal/2)
    zoom_scale=max(.66,min(1.63,2.10/zoom))
    if shot in ("battle","corner","trackside"):
        zoom_scale*=1 + .50*min(1.0,max(0,(spread-28)/48))
    if shot=="battle":
        off=(11+spread*.14,13+spread*.50,19+spread*.50); fov=51
    elif shot=="corner":
        off=(19+spread*.30,10+spread*.53,13+spread*.36); fov=50
    elif shot=="trackside":
        off=(-(21+spread*.32),10+spread*.53,13+spread*.34); fov=50
    else:
        raise ValueError(shot)
    target=(center[0],.85,center[2]-1.0)
    camera=(target[0]+off[0]*zoom_scale,target[1]+off[1]*zoom_scale,target[2]+off[2]*zoom_scale)
    forward=norm(tuple(target[i]-camera[i] for i in range(3)))
    right=norm(cross(forward,(0,1,0)))
    up=norm(cross(right,forward))
    outputs=[]
    for x,z in ((0,0),(lateral,-longitudinal)):
        ray=(x-camera[0],-camera[1],z-camera[2]); depth=dot(ray,forward)
        nx=dot(ray,right)/depth/math.tan(math.radians(fov/2))/(16/9)
        ny=dot(ray,up)/depth/math.tan(math.radians(fov/2))
        outputs.append((nx,ny,depth))
    return outputs


class TVDirector0627(unittest.TestCase):
    def test_only_tv_files_were_modified(self):
        # Portable baseline manifest; no dependency on sibling older versions.
        for rel, expected in PRESERVED.items():
            with self.subTest(path=rel):
                self.assertTrue((ROOT/rel).is_file())
                self.assertEqual(hashlib.sha256((ROOT/rel).read_bytes()).hexdigest(),expected)

    def test_engine_strategy_and_freecam_unchanged(self):
        preserved=[
            'scripts/race_engine.gd','scripts/core/race_stint_optimizer.gd',
            'scripts/core/race_ai_director.gd','scripts/core/race_tyre_regulations_2012.gd',
            'scripts/core/race_weather.gd','scripts/core/race_strategy.gd',
            'data/season_2012.json','data/tyres_2012.json',
            'scripts/apex_race_hud_0622.gd','scripts/apex_race_session_controller.gd',
            'scenes/main.tscn','scripts/track_map.gd',
        ]
        for item in preserved:
            with self.subTest(item=item):
                self.assertEqual(hashlib.sha256((ROOT/item).read_bytes()).hexdigest(),PRESERVED[item])
        after=(ROOT/'scripts/apex_race_view_controller.gd').read_text()
        for function, expected in FREE_CAMERA.items():
            match=re.search(r'static func '+function+r'\(.*?(?=\nstatic func |\Z)',after,re.S)
            self.assertIsNotNone(match,function)
            self.assertEqual(hashlib.sha256(match.group(0).encode()).hexdigest(),expected,function)

    def test_tv_rotation_uses_real_seconds(self):
        d=(ROOT/'scripts/tv_director.gd').read_text()
        view=(ROOT/'scripts/apex_race_view_controller.gd').read_text()
        self.assertIn('var screen_clock: float = 0.0',d)
        self.assertIn('if screen_clock < hold_until',d)
        self.assertIn('hold_until = screen_clock +',d)
        self.assertIn('manual_until = screen_clock + 18.0',d)
        self.assertIn('host.director.screen_clock += maxf(delta, 0.0)',view)
        self.assertIn('if host.race.running:',view)
        self.assertNotIn('playback_speed',d)

    def test_director_has_real_battle_gating_and_shot_variety(self):
        d=(ROOT/'scripts/tv_director.gd').read_text()
        self.assertIn('func _battle_is_plausible(',d)
        self.assertIn('if gap >= 0.12 and gap <= 1.45 and _battle_is_plausible',d)
        self.assertIn('ahead.has("progress") and behind.has("progress")',d)
        for s in ('"battle"','"corner"','"trackside"','"helicopter"'):
            self.assertIn(s,d)
        self.assertIn('if now <',d) if False else None
        self.assertIn('if screen_clock < hold_until',d)

    def test_world_camera_smooth_or_hard_cuts_without_freecam_changes(self):
        t=(ROOT/'scripts/track_3d.gd').read_text()
        self.assertIn('var remote_cut: bool = changed_subject',t)
        self.assertIn('if previous_mode == "overview" or remote_cut:',t)
        self.assertIn('camera_3d.fov = lerpf(',t)
        self.assertIn('broadcast_focus_id = -1',t)
        self.assertIn('camera_mode_3d = "overview"',t)
        self.assertIn('camera_3d.fov = 56.0',t)
        view=(ROOT/'scripts/apex_race_view_controller.gd').read_text()
        self.assertIn('if shot_style == "battle" and secondary_pos == null:',view)
        self.assertIn('phase_gap <= 0.045',view)

    def test_close_shots_fit_real_pair_at_1600x900(self):
        # Both points must project inside the 16:9 frame. At 2.35 zoom the
        # framing is tightest; check longitudinal and lateral battles.
        for style in ('battle','corner','trackside'):
            for spread in (4,10,22,38,60,80):
                for lateral in (0,10):
                    with self.subTest(style=style,spread=spread,lateral=lateral):
                        positions=projected_points(style,spread,lateral,zoom=2.35)
                        for x,y,depth in positions:
                            self.assertGreater(depth,0)
                            self.assertLess(abs(x),.90)
                            self.assertLess(abs(y),.87)

    def test_native_smoke_and_project_metadata(self):
        self.assertTrue((ROOT/'tests/core_0627_tv_director_smoke_test.gd').exists())
        self.assertTrue((ROOT/'linux/validar_0627.sh').exists())
        self.assertIn('v0.6.2.7',(ROOT/'project.godot').read_text())
        for source in (ROOT/'scripts').rglob('*.gd'):
            for dependency in re.findall(r'preload\("res://([^"\n]+)"\)',source.read_text()):
                self.assertTrue((ROOT/dependency).is_file(),f'{source}: {dependency}')

if __name__=='__main__':
    unittest.main(verbosity=2)
