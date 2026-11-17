"""APEX 0.6.2.3 static regression checks; does NOT substitute Godot parser/runtime."""
from pathlib import Path
import re, sys, hashlib, unittest
ROOT=Path(__file__).resolve().parents[1]
S=ROOT/'scripts'
MODULES={
'apex_race_commands.gd':['select_pre_race_team_mode','select_live_team_mode','apply_team_control','autonomy_tick','change_pace','request_pit','change_pit_mode','schedule_pit','cancel_scheduled_pit','toggle_race'],
'apex_race_view_controller.gd':['change_speed','change_visual_setting','apply_visual_from_setting','frame_strategic_circuit','change_camera_mode','change_director_preset','change_tv_shot','nearest_rival','select_pilot_option','on_position_pressed','zoom_by','reset_camera','unhandled_input'],
'apex_telemetry_reports.gd':['refresh_car_diagnostics','refresh_telemetry_panel','export_telemetry'],
'apex_pit_reports.gd':['refresh_pit_analytics','crew_training_cost_spent','pit_engineer_recommendation','export_pit_csv'],
'apex_menu_screen.gd':['build_menu'],
'apex_garage_screen.gd':['build_garage'],
'apex_race_session_controller.gd':['start_race','end_to_menu'],
'apex_radio_feed.gd':['set_radio_filter','render_commentary']}
class ModularHUDTest(unittest.TestCase):
 def test_project_root(self):
  self.assertTrue((ROOT/'scenes/main.tscn').exists())
  self.assertEqual(len(re.findall(r'^\[application\]',(ROOT/'project.godot').read_text(),re.M)),1)
  self.assertIn('0.6.2.3',(ROOT/'project.godot').read_text())
 def test_modules_preloads_and_delegate_signatures(self):
  main=(S/'main.gd').read_text()
  for filename, funcs in MODULES.items():
   src=(S/filename).read_text()
   self.assertTrue(src.startswith('extends RefCounted'),filename)
   self.assertIn('preload("res://scripts/'+filename+'")',main)
   for fn in funcs:
    self.assertRegex(src,r'(?m)^static func _'+fn+r'\(host(?:, |\))')
    self.assertRegex(main,r'(?m)^func _'+fn+r'\(')
    self.assertRegex(main,r'(?m)^\t(?:return )?\w+\._'+fn+r'\(self(?:, |\))')
 def test_no_leaking_global_writes(self):
  # A helper must always modify host's live state, not create an accidental local.
  vars_global=set(re.findall(r'(?m)^var\s+(\w+)',(S/'main.gd').read_text()))
  for filename in MODULES:
   source=(S/filename).read_text()
   for i,line in enumerate(source.splitlines(),1):
    if not line.startswith('\t') or line.lstrip().startswith('#'): continue
    clean=re.sub(r'"(?:\\.|[^"\\])*"','""',line).split('#',1)[0]
    for var in vars_global:
     if re.search(r'(?<![\w.])'+re.escape(var)+r'\s*=(?!=)',clean):
      self.fail(f'{filename}:{i}: global assignment missing host: {var}')
 def test_tracking_from_process(self):
  main=(S/'main.gd').read_text()
  view=(S/'apex_race_view_controller.gd').read_text()
  self.assertIn('RaceViewController.update_tracking(self, delta)',main)
  self.assertIn('static func update_tracking(host, delta: float)',view)
  self.assertIn('host.world_view.set_broadcast_view',view)
  self.assertIn('host.map_view.point_on_track',view)
  self.assertIn('host.get_viewport_rect().size',view)
  self.assertIn('race.step(batch)',main)
  self.assertIn('map_view.set_race_cars(draw_cars, focused_id)',main)
 def test_hud_approval_preserved(self):
  h=(S/'apex_race_hud_0622.gd').read_text()
  self.assertIn('var card_height: float = 166.0',h)
  self.assertIn('bottom_bar.size = Vector2(255.0, 48.0)',h)
  self.assertIn('var xx: float = 17.0 if i == 0 else width_px - card_width - 17.0',h)
  self.assertIn('card["expanded"].position = Vector2(detail_x, card_y - expanded_height - 8.0)',h)
  self.assertIn('"CHAMAR BOX"',h)
  self.assertIn('"EVENTOS"',h)
  self.assertIn('"RÁDIO"',h)
 def test_no_mixed_indentation_in_new_modules(self):
  for filename in MODULES:
   for i,line in enumerate((S/filename).read_text().splitlines(),1):
    if line.startswith(' '): self.fail(f'{filename}:{i}: spaces indentation')
    if line.startswith('\t') and re.match(r'\t+ ',line):
     self.fail(f'{filename}:{i}: tab-space mixed indentation')
 def test_no_external_imports(self):
  for filename in MODULES:
   text=(S/filename).read_text()
   for dep in re.findall(r'preload\("res://([^\"]+)"\)',text):
    self.assertTrue((ROOT/dep).is_file(),f'{filename} -> {dep}')
 def test_module_size_reduction(self):
  self.assertLess(len((S/'main.gd').read_text().splitlines()),1850)
 def test_engine_signature_manifest(self):
  manifest=ROOT/'tests/core_0623_sha256.txt'
  self.assertTrue(manifest.is_file())
  for line in manifest.read_text().splitlines():
   if not line.strip() or line.startswith('#'): continue
   digest, rel=line.split('  ',1)
   self.assertEqual(hashlib.sha256((ROOT/rel).read_bytes()).hexdigest(),digest,rel)
if __name__=='__main__':
 unittest.main(verbosity=2)
