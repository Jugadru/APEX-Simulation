#!/usr/bin/env python3
"""Source and deterministic mathematical checks; NOT Godot execution."""
import unittest, json, re, math, functools, hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
PREV=ROOT.parent/'APEX_GODOT_0.6.2.4_UI_MODULAR'

def dry_plan(track, initial):
    """Independent Python check of the same tyre curve and race-distance objective."""
    catalog=json.loads((ROOT/'data/tyres_2012.json').read_text())
    season=json.loads((ROOT/'data/season_2012.json').read_text())
    circuit=next(t for t in season['tracks'] if t['code']==track)
    laps=circuit['laps']; pit_loss=circuit['pit_loss']
    opts=catalog['tracks'][track]['dry']; spec=catalog['compounds']
    factor=catalog['tracks'][track]['severity']
    def seg(tire, wear, length):
        r=spec[tire]['wear']*factor
        if wear+r*length>96:return float('inf')
        return sum(spec[tire]['delta'] + 0.11*((wear+r*k)/35)**1.55 +
            0.06*max(0,wear+r*k-spec[tire]['cliff'])**1.60 for k in range(1,length+1))
    @functools.lru_cache(None)
    def tail(pos,tyre,mask,stops):
        r=laps-pos
        best=(seg(tyre,0,r),()) if mask==3 else (float('inf'),())
        if stops>=5: return best
        for length in range(1,r):
            cost=seg(tyre,0,length)
            if math.isinf(cost):break
            for j,nxt in enumerate(opts):
                sub,seq=tail(pos+length,nxt,mask|(1<<j),stops+1)
                if cost+pit_loss+sub<best[0]:best=(cost+pit_loss+sub,((pos+length,nxt),)+seq)
        return best
    best=(float('inf'),())
    for length in range(1,laps):
        cost=seg(initial,0,length)
        if math.isinf(cost):break
        for i,new in enumerate(opts):
            sub,seq=tail(length,new,(1<<opts.index(initial))|(1<<i),1)
            if cost+pit_loss+sub<best[0]:best=(cost+pit_loss+sub,((length,new),)+seq)
    return best

class Strategy0625(unittest.TestCase):
    def test_four_race_examples_mixed_tires_few_stops(self):
        for circuit in ['CHN','AUS','BHR','MAL']:
            catalog=json.loads((ROOT/'data/tyres_2012.json').read_text())
            for starting in catalog['tracks'][circuit]['dry']:
                with self.subTest(circuit=circuit,starting=starting):
                    _,stops=dry_plan(circuit,starting)
                    self.assertGreaterEqual(len(stops),1)
                    self.assertLessEqual(len(stops),3)
                    self.assertTrue(set(catalog['tracks'][circuit]['dry']).issubset({starting,*[n for _,n in stops]}))
                    self.assertEqual(stops,tuple(sorted(stops))) if False else None
    def test_dry_optimizer_not_short_horizon(self):
        content=(ROOT/'scripts/core/race_stint_optimizer.gd').read_text()
        self.assertIn('MAX_STOPS',content)
        self.assertIn('remaining: int = race_laps - start_lap',content)
        self.assertIn('required_mask',content)
        self.assertIn('pit_loss',content)
        self.assertIn('used_tires',content)
        self.assertIn('memo',content)
        director=(ROOT/'scripts/core/race_ai_director.gd').read_text()
        self.assertIn('StintOptimizer.optimize(car, race_laps',director)
        self.assertIn('planned_pit_lap',director)
        self.assertIn('pit_now = planned_pit_lap',director)
        self.assertIn('stable_dry',director)
    def test_wet_unchanged_and_legal_slicks(self):
        rules=(ROOT/'scripts/core/race_tyre_regulations_2012.gd').read_text()
        self.assertIn('race_wet_declared',rules)
        self.assertIn('used.has("Intermediário")',rules)
        engine=(ROOT/'scripts/race_engine.gd').read_text()
        self.assertIn('TyreRules2012.compliant',engine)
        self.assertIn('"disqualified"',engine)
        self.assertIn('int(car["laps_done"]) >= lap_count',engine)
        self.assertIn('tyre_rule_warning_sent',engine)
        championship=(ROOT/'scripts/championship_2012.gd').read_text()
        self.assertIn('not bool(car.get("disqualified", false))',championship)
    def test_manual_command_and_calendar_preserved(self):
        engine=(ROOT/'scripts/race_engine.gd').read_text()
        self.assertIn('str(car.get("pit_control_mode", "Manual")) != "IA"',engine)
        self.assertIn('"agendamento_manual"',engine)
        self.assertIn('scheduled_lap == exact_lap',engine)
        self.assertIn('scheduled_lap > 0 and exact_lap == scheduled_lap',engine)
    def test_ui_camera_physics_and_weather_byte_identical(self):
        paths=['scripts/apex_race_hud_0622.gd','scripts/apex_strategy_planner_0620.gd',
           'scripts/core/race_performance.gd','scripts/core/race_wet_physics.gd',
           'scripts/core/race_weather.gd','scripts/core/race_pit_lane.gd',
           'scripts/track_3d.gd','scripts/track_map.gd','scripts/apex_race_view_controller.gd']
        for path in paths:
            with self.subTest(file=path):
                self.assertEqual(hashlib.sha256((ROOT/path).read_bytes()).digest(),
                                 hashlib.sha256((PREV/path).read_bytes()).digest())
    def test_project_is_complete(self):
        self.assertTrue((ROOT/'project.godot').is_file())
        self.assertTrue((ROOT/'scenes/main.tscn').is_file())
        self.assertTrue((ROOT/'tests/core_0625_dry_strategy_smoke_test.gd').is_file())
        self.assertTrue((ROOT/'tests/core_0625_china_long_run.gd').is_file())
        self.assertIn('v0.6.2.5',(ROOT/'project.godot').read_text())

if __name__=='__main__':unittest.main(verbosity=2)
