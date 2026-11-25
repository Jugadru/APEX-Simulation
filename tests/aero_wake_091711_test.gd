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
 # 033 regression: a nearby off-axis car must not mask a real tow.
 var follower=car(10,.20,0)
 var offset=car(11,.205,1.2)
 var straight_ahead=car(12,.22,0)
 var pack=[follower,offset,straight_ahead]
 var legacy=Aero.choose(follower,pack,2000,5,0,0,0,false)
 var fixed=Aero.choose(follower,pack,2000,5,0,0,0)
 check(legacy.source_id==11 and legacy.tow_fraction==0,"032 historical source ranking")
 check(fixed.source_id==12 and fixed.tow_fraction>0,"033 effective tow source")
 check(Aero.choose(follower,[straight_ahead,offset,follower],2000,5,0,0,0)==fixed,"033 stable permutation")
 check(Aero.choose(follower,pack,2000,5,.8,.8,0).source_id==11,"corner selects effective dirty wake")
 check(Aero.choose(follower,pack,2000,5,0,0,1).source_id==12,"wet aligned tow")
 check(Aero.choose(follower,[follower,offset],2000,5,0,0,0)==Aero.clean(),"no phantom source")
 var tied=car(9,.22,0)
 check(Aero.choose(follower,[straight_ahead,tied],2000,5,0,0,0).source_id==9,"stable ID tie")
 check(Aero.choose(follower,[car(13,1.22,0)],2000,5,0,0,0).source_id==13,"lapped physical source")
 check(Aero.choose(follower,pack,2000,5,0,.8,0).tow_fraction==0,"braking transition")
 var pair=[car(0,.21,0),car(1,.2,0)]
 var metrics={0:{"target":100.0,"decision_pace":100.0,"line_ratio":0.0,"line_load":0.0,"ahead_load":0.0},1:{"target":100.0,"decision_pace":100.0,"line_ratio":0.0,"line_load":0.0,"ahead_load":0.0}}
 var track={"lap_km":5.0,"race_width_m":8.8,"overtake_zones":[]};var shape={"length":1000.0}
 var old=Space.plan(pair,metrics,.2,track,shape,{},false,false,false,false,40.0,true,true,true,true,true,false)
 var new=Space.plan(pair,metrics,.2,track,shape,{},false,false,false,false,40.0,true,true,true,true,true,true)
 check(new[1].states.aero_wake_032.source_id==0 and new[1].progress>old[1].progress,"actual sporting tow")
 check(new[1].states.race_lane==old[1].states.race_lane and new[0].progress==old[0].progress,"no steering or leader speed change")
 check(Space.plan(pair,metrics,.2,track,shape,{},false,false,false,false,12.0,true,true,true,true,true,true)==Space.plan(pair,metrics,.2,track,shape,{},false,false,false,false,12.0,true,true,true,true,true,false),"launch unchanged")
 print("AERO_WAKE_FIXTURE ",JSON.stringify({"close":close,"far":far,"corner":corner,"wet":wet,"sporting_old":old[1].progress,"sporting_new":new[1].progress}))
func drive(data:Dictionary,track:Dictionary,revision:int,climate:String,ticks:int,seed:int=42,full:bool=false)->Dictionary:
 var race=Race.new(data.teams,"Ferrari",seed,{},track,{})
 race.aero_wake_enabled=revision>=32;race.aero_wake_corrected=revision>=33;race.configure_weather(climate);race.running=true
 var tow:=0;var dirty:=0;var max_tow:=0.0;var max_dirty:=0.0;var side:=0;var reverse_steer:=0;var stops:=0;var overlaps:=0;var reverse:=0;var passes:=0;var changed:=0;var last_sign:Dictionary={};var initial:Dictionary={};var start:=Time.get_ticks_usec()
 for c in race.cars:initial[c.id]=int(c.grid)
 var by_driver:Dictionary={};var last_active_tick:Dictionary={};var engine_us:int=0;var actual_ticks:int=0;var peak_memory:float=0.0;var pits:int=0;var classification:Array=[]
 for tick in range(ticks):
  if race.finished:break
  var before:Dictionary={}
  for c in race.cars:before[c.id]=c.duplicate(false)
  var step_start:=Time.get_ticks_usec()
  race.step(.2)
  engine_us+=Time.get_ticks_usec()-step_start
  actual_ticks+=1
  if tick%100==0:peak_memory=maxf(peak_memory,Performance.get_monitor(Performance.MEMORY_STATIC))
  for c in race.cars:
   if float(c.pit_left)>0 and float(before[c.id].pit_left)<=0:pits+=1
  if race.clock<24:continue
  var active:Array=[]
  for c in race.cars:
   if not Space.active(c) or not Space.active(before[c.id]):
    last_sign.erase(c.id);last_active_tick.erase(c.id);continue
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
     if last_sign.has(c.id) and last_sign[c.id]!=sign_d:
      reverse_steer+=1
      by_driver[c.id]=int(by_driver.get(c.id,0))+1
     last_active_tick[c.id]=tick
     last_sign[c.id]=sign_d
   else:
    last_sign.erase(c.id);last_active_tick.erase(c.id)
  for i in range(active.size()):
   for j in range(i+1,active.size()):
    var gap:float=absf(Merge.relative_gap(float(active[i].progress),float(active[j].progress),float(race.space_profile.length)))
    var lane:float=absf(float(active[i].race_lane)-float(active[j].race_lane))
    if gap<6.39999 and lane<2.94999:overlaps+=1
    if gap<7.4 and lane>=2.94:side+=1
 var sorted:Array=race.get_sorted()
 for i in range(sorted.size()):
  classification.append({"id":sorted[i].id,"position":sorted[i].position,"laps":sorted[i].get("finish_laps",0),"finished":sorted[i].finished})
  passes+=int(sorted[i].combat_passes)
  if int(initial[sorted[i].id])!=i+1:changed+=1
 return {"hash":Codec.sporting_hash(race,{}),"tow_samples":tow,"dirty_samples":dirty,"max_tow":max_tow,"max_dirty":max_dirty,"stopped":stops,"reversals":reverse,"overlaps":overlaps,"straight_reversals":reverse_steer,"side":side,"passes":passes,"changed_grid":changed,"elapsed_us":Time.get_ticks_usec()-start,"engine_us":engine_us,"ticks":actual_ticks,"peak_static_bytes_sampled":peak_memory,"pits":pits,"finished":race.finished,"leader_finished":race.first_finish_at>=0.0,"classification":classification,"driver_reversals":by_driver}
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
 var seed:int=int(OS.get_environment("APEX_AERO_SEED")) if OS.has_environment("APEX_AERO_SEED") else 42
 var full:bool=OS.get_environment("APEX_AERO_FULL")=="1"
 if full:ticks=60000
 check(not track.is_empty(),"track found")
 if track.is_empty():quit(1);return
 var old=drive(data,track,31,climate,ticks,seed,full)
 var new=drive(data,track,33,climate,ticks,seed,full)
 print("AERO_WAKE_AB ",JSON.stringify({"track":code,"climate":climate,"ticks":ticks,"seed":seed,"full":full,"old":old,"new":new}))
 check(new.tow_samples>0 and new.dirty_samples>0,"both effects exercised")
 check(new.max_tow<=Aero.TOW_FRACTION and new.max_dirty<=Aero.DIRTY_FRACTION,"bounded modifiers")
 check(new.overlaps<=old.overlaps and new.stopped<=old.stopped and new.reversals==0,"no safety regression")
 check(new.straight_reversals<=old.straight_reversals+maxi(2,ceili(old.straight_reversals*.10)),"aggregate steering regression <=10% (two-event floor)")
 for id in new.driver_reversals:
  var baseline:int=int(old.driver_reversals.get(id,0))
  check(int(new.driver_reversals[id])<=baseline+maxi(3,ceili(baseline*.10)),"individual steering regression id="+str(id))
 if full:
  check(old.finished and new.finished and old.leader_finished and new.leader_finished,"both GPs reach chequered flag and finish")
  check(new.classification.size()==24 and new.pits>0,"classification and actual pit entries")
  var ids:Dictionary={};var ranks:Dictionary={}
  for entry in new.classification:
   ids[entry.id]=true;ranks[entry.position]=true
   check(entry.finished,"classified car finished id="+str(entry.id))
  check(ids.size()==24 and ranks.size()==24,"unique final classification")
 if code=="ITA" and climate=="Seco" and seed==42:
  if ticks==600:check(old.hash=="4f2d91a2a34de0c8e0bcf04fef7f84858fdc4aafbfcc2230909b5524a54b8514","independent 031 reference")
  var again=drive(data,track,33,climate,ticks,seed,full)
  check(new.hash==again.hash,"deterministic 033")
  for rev in [Replay.PRE_AERO_WAKE_SIMULATION_REVISION,Replay.PRE_WAKE_SOURCE_SIMULATION_REVISION,Replay.SIMULATION_REVISION]:
   var rec=Replay.new();rec.attach(Race.new(data.teams,"Ferrari",42,{},track,{}));rec.recorded_simulation_revision=rev
   for i in range(350):check(rec.step_tick(),"record tick")
   var play=Replay.new()
   check(play.load_data(rec.export_data()) and play.seek(350) and play.first_divergence<0,"archive "+rev)
   check(play.seek(170) and play.seek(350),"seek "+rev)
 print("AERO_WAKE_REPORT ",JSON.stringify({"checks":checks,"failures":failures}))
 if failures.is_empty():print("AERO_WAKE_091711_PASS")
 quit(0 if failures.is_empty() else 1)
