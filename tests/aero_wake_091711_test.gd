extends SceneTree
const Aero=preload("res://scripts/core/race_aero_wake_091711.gd")
const Race=preload("res://scripts/race_engine.gd")
const Space=preload("res://scripts/core/race_space_0655.gd")
const Replay=preload("res://scripts/core/race_replay_0660.gd")
const Codec=preload("res://scripts/core/race_state_codec_0660.gd")
const Merge=preload("res://scripts/core/race_merge_traffic_0669174.gd")
const Decision=preload("res://scripts/core/race_independent_racecraft_091710.gd")
var checks:=0
var failures:Array[String]=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);printerr("AERO_WAKE_FAIL ",label)
func car(id:int,p:float,lane:float)->Dictionary:
 return {"id":id,"progress":p,"race_lane":lane,"finished":false,"pit_left":0.0}
func fixture():
 var close=Aero.sample(10,25,0,0,0,0)
 var far=Aero.sample(30,100,0,0,0,0)
 var corner=Aero.sample(10,25,0,.8,.8,0)
 var wet=Aero.sample(10,25,0,0,0,1)
 check(close.tow_fraction>far.tow_fraction and far.tow_fraction>0,"tow decays with gap")
 check(Aero.apply(100,close)<100 and close.dirty_fraction==0,"straight benefit")
 check(Aero.apply(100,corner)>100 and corner.tow_fraction==0,"dirty air corner cost")
 check(wet.tow_fraction<close.tow_fraction and wet.wet_buffer_fraction>0,"wet caution")
 check(Aero.sample(10,25,1.5,0,0,0).tow_fraction==0 and Aero.sample(10,25,1.5,.8,.8,0).dirty_fraction>0,"dirty wake broader than tow")
 check(Aero.sample(10,25,3,.8,.8,0).exposure==0,"clean lateral air")
 check(Aero.sample(10,25,0,0,.8,0).tow_fraction==0,"anticipate braking")
 check(Aero.sample(10,150,0,0,0,0)==Aero.clean(),"range cutoff")
 check(Aero.sample(6.0,10,0,0,0,0)==Aero.clean(),"overlap not wake")
 var subject=car(4,0.995,0);var aligned=car(2,1.005,0);var off=car(1,1.003,2.95);var behind=car(3,.985,0)
 var source=Aero.choose(subject,[subject,aligned,off,behind],1000,5,0,0,0)
 check(source.source_id==2 and is_equal_approx(source.gap_m,50),"wrap and aligned source")
 var extra=car(5,1.018,0)
 check(Aero.choose(subject,[extra,aligned,subject,off],1000,5,0,0,0)==source,"no stacked wake and order independent")
 aligned.pit_left=2.0
 check(Aero.choose(subject,[subject,aligned,off,behind],1000,5,0,0,0)==Aero.clean(),"pit excluded")
 aligned.pit_left=0;aligned.finished=true
 check(Aero.choose(subject,[subject,aligned],1000,5,0,0,0)==Aero.clean(),"finished excluded")
 var pair=[car(0,.21,0),car(1,.2,0)]
 var metrics={0:{"target":100.0,"decision_pace":100.0,"line_ratio":0.0,"line_load":0.0,"ahead_load":0.0},1:{"target":100.0,"decision_pace":100.0,"line_ratio":0.0,"line_load":0.0,"ahead_load":0.0}}
 var track={"lap_km":5.0,"race_width_m":8.8,"overtake_zones":[]};var shape={"length":1000.0}
 var old=Space.plan(pair,metrics,.2,track,shape,{},false,false,false,false,40.0,true,true,true,true,true,false)
 var new=Space.plan(pair,metrics,.2,track,shape,{},false,false,false,false,40.0,true,true,true,true,true,true)
 check(new[1].states.aero_wake_032.source_id==0 and new[1].progress>old[1].progress,"actual sporting tow")
 check(new[1].states.race_lane==old[1].states.race_lane and new[0].progress==old[0].progress,"no steering or leader speed change")
 check(Space.plan(pair,metrics,.2,track,shape,{},false,false,false,false,12.0,true,true,true,true,true,true)==Space.plan(pair,metrics,.2,track,shape,{},false,false,false,false,12.0,true,true,true,true,true,false),"launch unchanged")
 print("AERO_WAKE_FIXTURE ",JSON.stringify({"close":close,"far":far,"corner":corner,"wet":wet,"sporting_old":old[1].progress,"sporting_new":new[1].progress}))
func drive(data:Dictionary,track:Dictionary,modern:bool,climate:String,ticks:int)->Dictionary:
 var race=Race.new(data.teams,"Ferrari",42,{},track,{})
 race.aero_wake_enabled=modern;race.configure_weather(climate);race.running=true
 var tow:=0;var dirty:=0;var max_tow:=0.0;var max_dirty:=0.0;var side:=0;var reverse_steer:=0;var stops:=0;var overlaps:=0;var reverse:=0;var passes:=0;var changed:=0;var last_sign:Dictionary={};var initial:Dictionary={};var start:=Time.get_ticks_usec()
 for c in race.cars:initial[c.id]=int(c.grid)
 for tick in range(ticks):
  var before:Dictionary={}
  for c in race.cars:before[c.id]=c.duplicate(false)
  race.step(.2)
  if race.clock<24:continue
  var active:Array=[]
  for c in race.cars:
   if not Space.active(c) or not Space.active(before[c.id]):continue
   active.append(c)
   var delta:float=float(c.progress)-float(before[c.id].progress)
   if delta<=1e-8:stops+=1
   if delta< -1e-8:reverse+=1
   var aero:Dictionary=c.get("aero_wake_032",{})
   if not aero.is_empty():
    if float(aero.tow_fraction)>0.00001:tow+=1
    if float(aero.dirty_fraction)>0.00001:dirty+=1
    max_tow=maxf(max_tow,float(aero.tow_fraction));max_dirty=maxf(max_dirty,float(aero.dirty_fraction))
   var line:Dictionary=race.RacingLine.sample(race.racing_line_profile,float(c.progress),0,80)
   var d:float=float(c.race_lane)-float(before[c.id].race_lane)
   if float(line.load)<.12 and str(c.combat_state) not in Decision.ATTACK and int(c.race_defending_against)<0:
    if absf(d)>.025:
     var sign_d:float=signf(d)
     if last_sign.has(c.id) and last_sign[c.id]!=sign_d:reverse_steer+=1
     last_sign[c.id]=sign_d
   else:last_sign.erase(c.id)
  for i in range(active.size()):
   for j in range(i+1,active.size()):
    var gap:float=absf(Merge.relative_gap(float(active[i].progress),float(active[j].progress),float(race.space_profile.length)))
    var lane:float=absf(float(active[i].race_lane)-float(active[j].race_lane))
    if gap<6.39999 and lane<2.94999:overlaps+=1
    if gap<7.4 and lane>=2.94:side+=1
 var sorted:Array=race.get_sorted()
 for i in range(sorted.size()):
  passes+=int(sorted[i].combat_passes)
  if int(initial[sorted[i].id])!=i+1:changed+=1
 return {"hash":Codec.sporting_hash(race,{}),"tow_samples":tow,"dirty_samples":dirty,"max_tow":max_tow,"max_dirty":max_dirty,"stopped":stops,"reversals":reverse,"overlaps":overlaps,"straight_reversals":reverse_steer,"side":side,"passes":passes,"changed_grid":changed,"elapsed_us":Time.get_ticks_usec()-start}
func run():
 fixture()
 if "--fixture-only" in OS.get_cmdline_user_args():
  print("AERO_WAKE_REPORT ",JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1);return
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
 var code:String=OS.get_environment("APEX_AERO_TRACK") if OS.has_environment("APEX_AERO_TRACK") else "ITA"
 var climate:String=OS.get_environment("APEX_AERO_CLIMATE") if OS.has_environment("APEX_AERO_CLIMATE") else "Seco"
 var ticks:int=int(OS.get_environment("APEX_AERO_TICKS")) if OS.has_environment("APEX_AERO_TICKS") else 600
 var track:Dictionary={}
 for t in data.tracks:
  if t.code==code:track=t;break
 var old=drive(data,track,false,climate,ticks)
 var new=drive(data,track,true,climate,ticks)
 print("AERO_WAKE_AB ",JSON.stringify({"track":code,"climate":climate,"ticks":ticks,"old":old,"new":new}))
 check(new.tow_samples>0 and new.dirty_samples>0,"both effects exercised")
 check(new.max_tow<=Aero.TOW_FRACTION and new.max_dirty<=Aero.DIRTY_FRACTION,"bounded modifiers")
 check(new.overlaps<=old.overlaps and new.stopped<=old.stopped and new.reversals==0,"no safety regression")
 check(new.straight_reversals<=old.straight_reversals*2+20,"no material steering regression")
 if code=="ITA" and climate=="Seco":
  if ticks==600:check(old.hash=="4f2d91a2a34de0c8e0bcf04fef7f84858fdc4aafbfcc2230909b5524a54b8514","independent 031 reference")
  var again=drive(data,track,true,climate,ticks)
  check(new.hash==again.hash,"deterministic 032")
  for rev in [Replay.PRE_AERO_WAKE_SIMULATION_REVISION,Replay.SIMULATION_REVISION]:
   var rec=Replay.new();rec.attach(Race.new(data.teams,"Ferrari",42,{},track,{}));rec.recorded_simulation_revision=rev
   for i in range(350):check(rec.step_tick(),"record tick")
   var play=Replay.new()
   check(play.load_data(rec.export_data()) and play.seek(350) and play.first_divergence<0,"archive "+rev)
   check(play.seek(170) and play.seek(350),"seek "+rev)
 print("AERO_WAKE_REPORT ",JSON.stringify({"checks":checks,"failures":failures}))
 if failures.is_empty():print("AERO_WAKE_091711_PASS")
 quit(0 if failures.is_empty() else 1)
