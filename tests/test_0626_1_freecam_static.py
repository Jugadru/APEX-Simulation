#!/usr/bin/env python3
"""Apex 0.6.2.6.1 camera input contract tests (not native Godot tests)."""
from pathlib import Path
import hashlib
import json
import re
import unittest

ROOT=Path(__file__).resolve().parents[1]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

class FreeCameraHotfix(unittest.TestCase):
    def test_input_routed_before_gui(self):
        main=(ROOT/'scripts/main.gd').read_text()
        self.assertIn('func _input(event: InputEvent) -> void:\n\tRaceViewController._camera_mouse_input(self, event)',main)
        self.assertIn('func _unhandled_input(event: InputEvent) -> void:\n\tRaceViewController._unhandled_input(self, event)',main)
        self.assertIn('RaceViewController.update_free_navigation(self, delta)',main)
        self.assertEqual(main.count('RaceViewController.update_free_navigation(self, delta)'),1)

    def test_mouse_drag_and_hud_protection(self):
        camera=(ROOT/'scripts/apex_race_view_controller.gd').read_text()
        self.assertIn('static func _camera_mouse_input(host, event: InputEvent)', camera)
        self.assertIn('static func _pointer_over_race_ui(host, pointer_pos: Vector2)',camera)
        self.assertIn('gui_get_hovered_control()',camera)
        self.assertIn('hud.background_dimmer.visible',camera)
        self.assertIn('card.get(name, null)',camera)
        self.assertIn('MOUSE_BUTTON_MIDDLE',camera)
        self.assertIn('MOUSE_BUTTON_LEFT',camera)
        self.assertIn('host.world_view.pan_by(event.relative)',camera)
        self.assertIn('host.cam.position -= event.relative / host.cam.zoom',camera)
        self.assertIn('host.dragging = false',camera)
        old_keys=camera.split('static func _unhandled_input(host, event: InputEvent) -> void:',1)[1]
        self.assertNotIn('InputEventMouseMotion',old_keys)
        self.assertIn('KEY_SPACE',old_keys)

    def test_no_passive_camera_moves_outside_free_mode(self):
        c=(ROOT/'scripts/apex_race_view_controller.gd').read_text()
        self.assertIn('host.camera_mode != "Livre" or host.dragging:',c)
        self.assertIn('Input.is_key_pressed(KEY_A)',c)
        self.assertIn('Input.is_key_pressed(KEY_D)',c)
        self.assertIn('Input.is_key_pressed(KEY_W)',c)
        self.assertIn('Input.is_key_pressed(KEY_S)',c)
        self.assertIn('if mouse_pos.x < margin:',c)
        self.assertIn('if mouse_pos.y < margin:',c)

    def test_preserves_simulation_and_camera_algorithms(self):
        baseline=json.loads((ROOT/'tests/0626_1_preserved_sha256.json').read_text())
        for item, expected in baseline.items():
            with self.subTest(path=item):
                self.assertEqual(sha(ROOT/item),expected)

    def test_loading_dependencies(self):
        for file in (ROOT/'scripts').rglob('*.gd'):
            source=file.read_text(encoding='utf-8')
            for dep in re.findall(r'preload\("res://([^\"]+)"\)',source):
                self.assertTrue((ROOT/dep).exists(),f'{file}: {dep}')
        self.assertTrue((ROOT/'tests/core_0626_1_freecam_smoke_test.gd').exists())
        self.assertIn('0.6.2.6.1',(ROOT/'project.godot').read_text())

if __name__=='__main__':
    unittest.main(verbosity=2)
