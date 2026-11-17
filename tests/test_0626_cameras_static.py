#!/usr/bin/env python3
"""Static and geometric checks for APEX 0.6.2.6.
Not a Godot parser or graphics test; use core_0626_camera_smoke_test.gd too.
"""
from pathlib import Path
import hashlib
import math
import re
import unittest
ROOT=Path(__file__).resolve().parents[1]
PREV=ROOT.parent/'APEX_GODOT_0.6.2.5_STRATEGY_FIX'

class Camera0626(unittest.TestCase):
    def test_core_simulation_and_tyres_are_byte_identical(self):
        critical=[
            'scripts/race_engine.gd','scripts/core/race_ai_director.gd',
            'scripts/core/race_stint_optimizer.gd','scripts/core/race_tyre_regulations_2012.gd',
            'scripts/core/race_strategy.gd','scripts/core/race_weather.gd',
            'scripts/core/race_team_autonomy.gd','scripts/core/race_performance.gd',
            'scripts/core/race_wet_physics.gd','scripts/track_map.gd',
            'data/tyres_2012.json','data/season_2012.json',
            'scripts/championship_2012.gd','scenes/main.tscn',
        ]
        for f in critical:
            with self.subTest(f=f):
                self.assertEqual(hashlib.sha256((ROOT/f).read_bytes()).digest(),
                                 hashlib.sha256((PREV/f).read_bytes()).digest())

    def test_hud_only_aerial_view_selection_was_touched(self):
        current=(ROOT/'scripts/apex_race_hud_0622.gd').read_text()
        previous=(PREV/'scripts/apex_race_hud_0622.gd').read_text()
        adjustment='''\n\t\t# The aerial preset follows race action by default. "Livre" is still
\t\t# available separately in CORRIDA > CÂMERA.
\t\thost.mode_picker.select(2)
\t\thost._change_camera_mode(2)'''
        self.assertIn(adjustment,current)
        self.assertEqual(current.replace(adjustment,''),previous)

    def test_3d_shots_keep_2d_track_and_drivers_in_sync(self):
        track=(ROOT/'scripts/track_3d.gd').read_text()
        view=(ROOT/'scripts/apex_race_view_controller.gd').read_text()
        self.assertIn('func set_broadcast_view(',track)
        self.assertIn('var midpoint: Vector3 = p.lerp(companion, 0.5)',track)
        self.assertIn('var spread: float = p.distance_to(companion)',track)
        self.assertIn('"aerial"',track)
        self.assertIn('func enter_free_view() -> void:',track)
        self.assertIn('focus_point = Vector3(camera_look_target.x, 0.0, camera_look_target.z)',track)
        self.assertIn('1.0 - exp(',track)
        self.assertIn('host.world_view.set_broadcast_view(desired, desired_dir, secondary_pos',view)
        self.assertIn('host.map_view.point_on_track(other_progress)',view)
        self.assertIn('phase > 0.038',view)
        self.assertIn('"pit" if shot_style == "pit" else "aerial"',view)
        self.assertIn('intended * host.camera_zoom_multiplier',view)
        self.assertIn('if host.visual_setting == 0:',view)
        for shot in ('chase','battle','corner','helicopter','trackside','pit'):
            self.assertIn(f'valid_style == "{shot}"',track)

    def test_director_prioritizes_real_battles_and_events(self):
        director=(ROOT/'scripts/tv_director.gd').read_text()
        for feature in ['secondary_focus_id = wanted_secondary',
                        'hold_until = now +',
                        'manual_until',
                        'if wanted_score == 12 and now >= 12.0',
                        'if score > wanted_score',
                        'if now < hold_until and wanted_score < 90']:
            self.assertIn(feature,director)

    def test_race_start_has_live_camera(self):
        session=(ROOT/'scripts/apex_race_session_controller.gd').read_text()
        self.assertIn('host.camera_mode = "Diretor TV"',session)
        self.assertIn('host.mode_picker.select(2)',session)
        self.assertIn('host.tv_shot_override = "Automático"',session)

    def test_project_structure_and_native_smoke(self):
        proj=(ROOT/'project.godot').read_text()
        self.assertIn('v0.6.2.6',proj)
        self.assertIn('run/main_scene="res://scenes/main.tscn"',proj)
        self.assertTrue((ROOT/'linux/validar_0626.sh').exists())
        self.assertTrue((ROOT/'tests/core_0626_camera_smoke_test.gd').exists())
        for path in (ROOT/'scripts').rglob('*.gd'):
            src=path.read_text()
            for entry in re.findall(r'preload\("res://([^"]+)"\)',src):
                self.assertTrue((ROOT/entry).is_file(),f'{path}: {entry}')

    def test_framing_spread_scales_not_fixed_close_up(self):
        # Independent sanity check of the new camera parameterization. Points
        # are on the same straight, horizontally separated in world coordinates;
        # their projected extents should remain within a 16:9 perspective view.
        tan_half=math.tan(math.radians(56)/2)
        for spread in (6.0,22.0,55.0,80.0):
            # aerial shot when zoom=1.35; direction north (0,0,-1)
            midpoint=spread/2
            camera_right=4.0
            camera_height=34.0+spread*.32
            camera_behind=15.0+spread*.14
            distance_scale=1.72/1.35
            # relative to camera target; intended lookahead = 7 along -z
            cx=midpoint+camera_right*distance_scale
            cy=.7+camera_height*distance_scale
            cz=-7+camera_behind*distance_scale
            forward=[midpoint-cx,.7-cy,-7-cz]
            norm=math.sqrt(sum(a*a for a in forward))
            forward=[a/norm for a in forward]
            right=[-forward[2],0,forward[0]]
            length=math.sqrt(sum(a*a for a in right))
            right=[a/length for a in right]
            up=[right[1]*forward[2]-right[2]*forward[1],right[2]*forward[0]-right[0]*forward[2],right[0]*forward[1]-right[1]*forward[0]]
            for x in (0.0,spread):
                ray=[x-cx,-cy,-cz]
                depth=sum(ray[i]*forward[i] for i in range(3))
                self.assertGreater(depth,0)
                nx=sum(ray[i]*right[i] for i in range(3))/depth/tan_half/(16/9)
                ny=sum(ray[i]*up[i] for i in range(3))/depth/tan_half
                self.assertLess(abs(nx),.85,(spread,x,nx))
                self.assertLess(abs(ny),.80,(spread,x,ny))

if __name__=='__main__':
    unittest.main(verbosity=2)
