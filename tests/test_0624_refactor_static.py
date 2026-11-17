"""Apex 0.6.2.4 code regression checks (static only, NOT Godot runtime)."""
from __future__ import annotations
from pathlib import Path
import hashlib
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
S = ROOT / 'scripts'
PREV = Path('/mnt/data/APEX_GODOT_0.6.2.3_REFACTORED')
MODULES = {
    'apex_race_ui_legacy_builder.gd': ['_build_game_ui'],
    'apex_race_ui_layout.gd': [
        '_layout_ui', '_apply_hud_visibility', '_change_hud_layout',
        '_toggle_left_panel', '_toggle_right_panel', '_toggle_context_panel',
        '_toggle_tactical_map', '_toggle_hud'],
    'apex_race_ui_presenter.gd': [
        '_update_game_ui', '_set_pitwall_mode', '_refresh_strategy_blocks',
        '_refresh_pitwall_summary', '_cycle_info_mode'],
    'apex_race_ui_legacy_cards.gd': [
        '_rebuild_player_cards', '_create_player_card', '_refresh_player_cards',
        '_driver_initials', '_focus_driver', '_focus_player_slot',
        '_cycle_kers_mode', '_open_driver_strategy'],
}
UNCHANGED = [
    'scripts/race_engine.gd','scripts/track_3d.gd','scripts/track_map.gd',
    'scripts/core/race_weather.gd','scripts/core/race_team_autonomy.gd',
    'scripts/apex_race_hud_0622.gd','scripts/apex_strategy_planner_0620.gd',
    'scripts/apex_race_view_controller.gd','scenes/main.tscn',
    'scripts/apex_race_commands.gd','scripts/apex_race_session_controller.gd',
]

class TestApex0624(unittest.TestCase):
    def test_new_modules_exist_and_are_preloaded(self):
        main = (S/'main.gd').read_text()
        for filename in MODULES:
            self.assertTrue((S/filename).is_file(), filename)
            self.assertIn('preload("res://scripts/'+filename+'")',main)
            self.assertTrue((S/filename).read_text().startswith('extends RefCounted'))

    def test_all_old_signal_names_keep_a_wrapper(self):
        main=(S/'main.gd').read_text()
        for filename,names in MODULES.items():
            module=(S/filename).read_text()
            alias=''.join(x.title() for x in filename.removesuffix('.gd').removeprefix('apex_').split('_'))
            for name in names:
                self.assertEqual(len(re.findall(r'(?m)^func '+name+r'\(',main)),1)
                self.assertEqual(len(re.findall(r'(?m)^static func '+name+r'\(host[,)]',module)),1)
                self.assertIn(alias+'.'+name+'(self',main)

    def test_no_unqualified_main_properties_in_modules(self):
        baseline=(PREV/'scripts/main.gd').read_text()
        globals_=set(re.findall(r'(?m)^var\s+(\w+)',baseline))
        functions=set(re.findall(r'(?m)^func\s+(\w+)\(',baseline))
        for filename in MODULES:
            src=(S/filename).read_text()
            locals_=set(re.findall(r'(?m)\bvar\s+(\w+)',src))
            locals_ |= set(re.findall(r'(?m)\bfor\s+(\w+)\s+in\b',src))
            for no,line in enumerate(src.splitlines(),1):
                if not line.startswith('\t') or line.lstrip().startswith('#'):continue
                # Remove string literals and inline comments.
                clean=re.sub(r'"(?:\\.|[^"\\])*"','""',line).split('#',1)[0]
                for m in re.finditer(r'(?<![\w.])([A-Za-z_]\w*)\b',clean):
                    word=m.group(1)
                    if word in (globals_|functions)-locals_:
                        self.fail(f'{filename}:{no} : unqualified host.{word}')

    def test_ui_only_scope_preserves_game_and_hud_bytes(self):
        for rel in UNCHANGED:
            self.assertEqual(hashlib.sha256((ROOT/rel).read_bytes()).hexdigest(),
                             hashlib.sha256((PREV/rel).read_bytes()).hexdigest(),rel)

    def test_main_is_coordinator_not_a_megascript(self):
        main=(S/'main.gd').read_text()
        self.assertLess(len(main.splitlines()),800)
        self.assertIn('RaceUI',main.replace('RaceUi','RaceUI'))
        self.assertIn('const RaceUiLegacyBuilder',main)
        self.assertIn('const RaceUiPresenter',main)
        self.assertIn('const RaceUiLayout',main)
        self.assertIn('const RaceUiLegacyCards',main)
        self.assertIn('RaceViewController.update_tracking(self, delta)',main)
        self.assertIn('race.step(batch)',main)

    def test_minimap_and_two_player_hud_preserved(self):
        hud=(S/'apex_race_hud_0622.gd').read_text()
        for needle in ['var card_height: float = 166.0',
                       'card["expanded"].position = Vector2(detail_x, card_y - expanded_height - 8.0)',
                       '"CHAMAR BOX"','"RÁDIO"',
                       'bottom_bar.size = Vector2(255.0, 48.0)']:
            self.assertIn(needle,hud)

    def test_module_indentation_and_delimiters(self):
        for filename in MODULES:
            source=(S/filename).read_text()
            self.assertNotIn('\r',source)
            for lineno,line in enumerate(source.splitlines(),1):
                self.assertFalse(line.startswith(' '),(filename,lineno,'leading spaces'))
                self.assertFalse(re.match(r'^\t+ ',line),(filename,lineno,'mixed indent'))
            # A lightweight lexical delimiter check, not a GDScript parser.
            masked=re.sub(r'"(?:\\.|[^"\\])*"','""',source)
            masked=re.sub(r'(?m)#.*$','',masked)
            stack=[]
            match={')':'(',']':'[','}':'{'}
            for ch in masked:
                if ch in '([{': stack.append(ch)
                elif ch in ')]}':
                    self.assertTrue(stack,(filename,ch,'extra closer'))
                    self.assertEqual(stack.pop(),match[ch],filename)
            self.assertFalse(stack,(filename,'unclosed delimiters'))

    def test_module_resource_references_exist(self):
        for filename in MODULES:
            source=(S/filename).read_text()
            for rel in re.findall(r'preload\("res://([^"]+)"\)',source):
                self.assertTrue((ROOT/rel).is_file(),(filename,rel))

    def test_project_entrypoint(self):
        project=(ROOT/'project.godot').read_text()
        self.assertIn('v0.6.2.4',project)
        self.assertIn('run/main_scene="res://scenes/main.tscn"',project)
        self.assertTrue((ROOT/'scenes/main.tscn').is_file())

    def test_original_0623_is_untouched(self):
        self.assertGreater((PREV/'scripts/main.gd').stat().st_size,(ROOT/'scripts/main.gd').stat().st_size)
        self.assertEqual(len((PREV/'scripts/main.gd').read_text().splitlines()),1782)

if __name__=='__main__': unittest.main(verbosity=2)
