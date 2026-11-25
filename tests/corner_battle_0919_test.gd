extends SceneTree
const Corner=preload("res://scripts/core/race_corner_battle_0919.gd")
const Space=preload("res://scripts/core/race_space_0655.gd")
var checks:int=0
var failures:Array[String]=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);printerr("CORNER_BATTLE_FAIL ",label)
func run():
 check(Corner.phase(.04,.08)=="straight","straight")
 check(Corner.phase(.12,.6)=="entry","entry")
 check(Corner.phase(.65,.62)=="apex","apex")
 check(Corner.phase(.6,.12)=="exit","exit")
 var c={"id":1,"race_lane":0.0,"combat_state":"closing","combat_target_id":0}
 var d={"id":0,"race_lane":.4}
 var tactic={"commit":true,"defense":true,"attack_goal":-2.95,"margin_m":.4,"side":"left","blocked":false}
 var snapshot:PackedByteArray=var_to_bytes([c,d,tactic])
 check(Corner.refine(c,d,tactic,9,2.95,.04,.08,0,false)==tactic,"straight legacy")
 check(not Corner.refine(c,d,tactic,9,2.95,.3,.7,0,false).commit,"late entry veto")
 check(not Corner.refine(c,d,tactic,9,2.95,.8,.75,0,false).commit,"late apex veto")
 check(Corner.refine(c,d,tactic,14,2.95,.3,.7,0,false)==tactic,"early clear attack survives")
 check(Corner.refine(c,d,tactic,10.5,2.95,.3,.7,0,false)==tactic,"moderate dry gap not over-restricted")
 var small=tactic.duplicate();small.attack_goal=-0.8
 check(Corner.refine(c,d,small,9,2.95,.3,.7,0,false)==small,"small lateral correction not vetoed")
 check(Corner.refine(c,d,tactic,12,2.95,.3,.7,0,false).commit and not Corner.refine(c,d,tactic,12,2.95,.3,.7,.9,false).commit,"wet margin expands")
 check(Corner.refine(c,d,tactic,9,2.95,.7,.1,0,false)==tactic,"exit preserves base decision")
 check(snapshot==var_to_bytes([c,d,tactic]),"pure no input mutation")
 var rejected=tactic.duplicate();rejected.commit=false
 check(Corner.refine(c,d,rejected,6,2.95,.7,.7,0,false)==rejected,"never resurrect veto")
 c.race_lane=-2.6;c.combat_state="duel"
 var hold=Corner.refine(c,d,tactic,6,2.95,.6,.65,.6,false)
 check(hold.commit and hold.attack_goal==-2.6 and not hold.defense,"occupied legal corridor held")
 check(not Corner.refine(c,d,tactic,6,2.0,.6,.65,.6,true).has("corner_reason"),"narrowing stays with solver")
 check(Corner.refine(c,d,tactic,6,2.95,.7,.1,0,false)==tactic,"established exit uses normal solver")
 check(Corner.refine(c,d,tactic,6,2.95,.3,.7,0,false)==tactic,"established entry uses normal solver")
 c.combat_target_id=9
 check(not Corner.refine(c,d,tactic,6,2.95,.6,.65,.6,false).has("corner_reason"),"unrelated duel cannot claim hold")
 # Real RaceSpace integration: late entry attack in a controlled passing zone.
 var attacker={"id":1,"progress":.2,"race_lane":0.0,"combat_state":"closing","combat_target_id":0,"attack_charge":2.0,"skill":95,"risk_tolerance":80,"spatial_awareness":95}
 var defender={"id":0,"progress":.209,"race_lane":.4,"skill":70,"defense_aggression":50}
 var grid=[defender,attacker]
 var metrics={0:{"target":105.0,"decision_pace":105.0,"line_load":.7,"ahead_load":.8,"line_ratio":0.0},1:{"target":100.0,"decision_pace":100.0,"line_load":.3,"ahead_load":.7,"line_ratio":0.0}}
 var track={"race_width_m":8.8,"lap_km":5.0,"overtake_zones":[[0.1,.4]]}
 var shape={"length":1000.0}
 var old=Space.plan(grid,metrics,.2,track,shape,{},false,false,true,false,40.0,true,true,true,true,true,true,true,true,true,true,false)
 var new=Space.plan(grid,metrics,.2,track,shape,{},false,false,true,false,40.0,true,true,true,true,true,true,true,true,true,true,true)
 check(old[1].states.combat_attempts==1,"036 base attack exercised")
 check(new[1].states.racecraft_memory.get("corner_reason","")=="late_commit_entry" and new[1].states.combat_attempts==0,"037 real entry veto no phantom attempt")
 check(float(new[1].progress)>=float(attacker.progress),"solver no reverse")
 print("CORNER_BATTLE_REPORT ",JSON.stringify({"checks":checks,"failures":failures}))
 if failures.is_empty():print("CORNER_BATTLE_0919_PASS")
 quit(0 if failures.is_empty() else 1)
