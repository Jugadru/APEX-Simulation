#!/usr/bin/env python3
"""Static tests for original 0.6.2.8 procedural scenery (not a Godot render test)."""
import hashlib, json, re, unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
PRESERVED = json.loads((ROOT/'tests/0628_preserved_sha256.json').read_text())
CAR_FUNCTIONS = json.loads((ROOT/'tests/0628_car_behaviour_sha256.json').read_text())

class Scenery0628(unittest.TestCase):
    def test_racing_and_tv_files_preserved_byte_for_byte(self):
        for path, expected in PRESERVED.items():
            with self.subTest(path=path):
                self.assertEqual(hashlib.sha256((ROOT/path).read_bytes()).hexdigest(),expected)

    def test_track_scene_connects_own_module(self):
        source=(ROOT/'scripts/track_3d.gd').read_text()
        self.assertIn('preload("res://scripts/apex_circuit_scenery_0628.gd")',source)
        self.assertIn('CircuitSceneryScript.add_details(course_root',source)
        self.assertIn('CircuitSceneryScript.palette_for(course_name)',source)
        self.assertIn('world_environment_3d.environment.background_color',source)
        self.assertIn('if bool(CircuitSceneryScript.palette_for(course_name)["trees"]):',source)
        self.assertIn('func _build_road_sections()',source)
        self.assertIn('func _add_band(',source)

    def test_all_twenty_circuits_and_biomes(self):
        tracks=json.loads((ROOT/'data/season_2012.json').read_text())['tracks']
        self.assertEqual(len(tracks),20)
        names=[t['name'].lower() for t in tracks]
        for key in ('bahrain','yas marina','buddh','monaco','valencia','marina bay','sepang','interlagos'):
            self.assertTrue(any(key in name for name in names),key)
        biome_src=(ROOT/'scripts/apex_circuit_scenery_0628.gd').read_text()
        for key in ('desert','urban','tropical','temperate','ground','patch_a','patch_b','sky'):
            self.assertIn(key,biome_src)
        self.assertIn('"trees": false',biome_src)

    def test_car_visual_parts_only_and_dynamics_unchanged(self):
        model=(ROOT/'scripts/car_model_3d.gd').read_text()
        for token in ('SidepodInlet','MirrorStalk','MirrorCase','FrontWingOutboardFlap','RainLightVisual'):
            self.assertIn(token,model)
        for name,expected in CAR_FUNCTIONS.items():
            match=re.search(r'(?ms)^func '+name+r'\(.*?(?=^func |\Z)',model)
            self.assertIsNotNone(match,name)
            self.assertEqual(hashlib.sha256(match.group(0).encode()).hexdigest(),expected,name)

    def test_scenery_stays_visual_only(self):
        scene=(ROOT/'scripts/apex_circuit_scenery_0628.gd').read_text()
        for forbidden in ('CollisionShape3D','PhysicsBody3D','Area3D','Rigidbody','apply_force','race_engine.gd','race_stint_optimizer.gd'):
            self.assertNotIn(forbidden,scene)
        self.assertIn('_is_outside_other_sections',scene)
        self.assertIn('MultiMeshInstance3D',scene)
        self.assertIn('for slot in range(18)',scene)
        self.assertIn('for slot in range(12)',scene)

    def test_scripts_preloads_resolve(self):
        for gd in (ROOT/'scripts').rglob('*.gd'):
            for dep in re.findall(r'preload\("res://([^"\n]+)"\)',gd.read_text()):
                self.assertTrue((ROOT/dep).is_file(),f'{gd}: {dep}')

    def test_native_smoke_and_release_files(self):
        for path in ('tests/core_0628_scenery_smoke_test.gd','linux/validar_0628.sh','docs/arquivo/guias/README_antigos/README_0628.md','docs/arquivo/changelogs/CHANGELOG_0628.md'):
            self.assertTrue((ROOT/path).is_file(),path)
        self.assertIn('v0.6.2.8',(ROOT/'project.godot').read_text())

    def test_no_mixed_indentation_in_changed_scripts(self):
        for rel in ('scripts/track_3d.gd','scripts/apex_circuit_scenery_0628.gd','scripts/car_model_3d.gd'):
            for i,line in enumerate((ROOT/rel).read_text().splitlines(),1):
                ws=line[:len(line)-len(line.lstrip(' \t'))]
                self.assertFalse(' ' in ws and '\t' in ws, f'{rel}:{i} has mixed indentation')
                if ws: self.assertNotIn(' ',ws, f'{rel}:{i} uses space indentation')

if __name__=='__main__': unittest.main(verbosity=2)
