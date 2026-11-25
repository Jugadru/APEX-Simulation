extends SceneTree
const Aero=preload("res://scripts/core/race_aero_wake_091711.gd")
const Race=preload("res://scripts/race_engine.gd")
const Space=preload("res://scripts/core/race_space_0655.gd")
const Replay=preload("res://scripts/core/race_replay_0660.gd")
const Codec=preload("res://scripts/core/race_state_codec_0660.gd")
const Merge=preload("res://scripts/core/race_merge_traffic_0669174.gd")
const Decision=preload("res://scripts/core/race_independent_racecraft_091710.gd")
const PitLane=preload("res://scripts/core/race_pit_lane.gd")
class ExitHost:
 extends RefCounted
 var records:int=0
 func _event(_kind:String,_id:int,_msg:String,_priority:int):pass
 func _record_lap_cross(_car:Dictionary,_prev:float,_strategy:bool):pass
 func _record_pit_history(_car:Dictionary):records+=1
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
 # 034: two laterally separated cars must not converge simultaneously.
 var traffic_pair=[car(20,.20,-1.5),car(21,.201,1.5)]
 var intents={20:{"lane":-1.5,"next_lane":-1.3,"next":.202},21:{"lane":1.5,"next_lane":1.3,"next":.203}}
 Space.prevent_convergence(traffic_pair,intents,1000.0)
 check(intents[20].next_lane==-1.5 and intents[21].next_lane==1.5,"simultaneous convergence veto")
 var pit_plan={20:{"progress":.202},21:{"progress":.203}}
 check(not Space.pit_exit_clear(.201,traffic_pair,pit_plan,[],1000.0),"pit exit occupied")
 check(not Space.pit_exit_clear(.995,[],{},[.001],1000.0),"pit exit reserved across finish line")
 check(Space.pit_exit_clear(.4,traffic_pair,pit_plan,[],1000.0),"pit exit free")
 var host=ExitHost.new()
 var exit_car={"id":99,"name":"Fixture","progress":.999,"pit_from":.9,"pit_to":1.0,"pit_stage":"exit","pit_stage_elapsed":3.9,"pit_phase":.99,"pit_nominal_total":10.0,"pit_total":10.0,"pit_active_elapsed":9.9,"pit_extra_elapsed":0.0,"pit_wait":0.0,"pit_service_delay":0.0,"pit_release_delay":0.0,"pit_incident_type":"","pit_last_service":2.0,"pit_left":.1}
 PitLane.advance(host,exit_car,.2,.2,.4,.6,false)
 check(exit_car.pit_stage=="exit" and exit_car.pit_left>0 and host.records==0,"blocked exit remains in pit lane")
 check(is_equal_approx(float(exit_car.pit_merge_hold_s),.2) and exit_car.pit_extra_elapsed==0,"merge delay separate from incident")
 PitLane.advance(host,exit_car,.2,.2,.4,.6,true)
 check(exit_car.pit_stage=="done" and exit_car.pit_left==0 and host.records==1,"release once when safe")
 check(is_equal_approx(float(exit_car.pit_last_total),10.2) and exit_car.pit_last_extra==0,"real merge delay included in total")
 # 035: no stop/start dry straight-hold policy in low grip.
 check(Space.straight_hold_allowed(.08,.1,false,false,0,1.0,0.0,true),"dry hold retained")
 check(Space.straight_hold_allowed(.08,.1,false,false,0,1.0,.6,false),"034 wet hold historical")
 check(not Space.straight_hold_allowed(.08,.1,true,false,0,1.0,.6,true),"035 continuous wet line")
 var draft_car=car(24,.2,0)
 draft_car["racecraft_memory"]={"target":25,"stable":2.0,"observed":.3}
 var draft_leader=car(25,.21,.3)
 var draft_intent={"state":"closing","defending":-1,"goal":0.0}
 check(Decision.decide(draft_car,draft_intent,draft_leader,10.0,0,1.0,.05,.05,.5,.2,true).mode=="DRAFT","legacy wet draft acquisition")
 check(Decision.decide(draft_car,draft_intent,draft_leader,10.0,0,1.0,.05,.05,.5,.2,false).mode=="FOLLOW","wet own line without lateral draft")
 var pair=[car(0,.21,0),car(1,.2,0)]
 var metrics={0:{"target":100.0,"decision_pace":100.0,"line_ratio":0.0,"line_load":0.0,"ahead_load":0.0},1:{"target":100.0,"decision_pace":100.0,"line_ratio":0.0,"line_load":0.0,"ahead_load":0.0}}
 var track={"lap_km":5.0,"race_width_m":8.8,"overtake_zones":[]};var shape={"length":1000.0}
 var old=Space.plan(pair,metrics,.2,track,shape,{},false,false,false,false,40.0,true,true,true,true,true,false)
 var new=Space.plan(pair,metrics,.2,track,shape,{},false,false,false,false,40.0,true,true,true,true,true,true)
 check(new[1].states.aero_wake_032.source_id==0 and new[1].progress>old[1].progress,"actual sporting tow")
 check(new[1].states.race_lane==old[1].states.race_lane and new[0].progress==old[0].progress,"no steering or leader speed change")
 check(Space.plan(pair,metrics,.2,track,shape,{},false,false,false,false,12.0,true,true,true,true,true,true)==Space.plan(pair,metrics,.2,track,shape,{},false,false,false,false,12.0,true,true,true,true,true,false),"launch unchanged")
 print("AERO_WAKE_FIXTURE ",JSON.stringify({"close":close,"far":far,"corner":corner,"wet":wet,"sporting_old":old[1].progress,"sporting_new":new[1].progress}))
func drive(data:Dictionary,track:Dictionary,revision:int,climate:String,ticks:int,seed:int=42)->Dictionary:
 var race=Race.new(data.teams,"Ferrari",seed,{},track,{})
 race.aero_wake_enabled=revision>=32;race.aero_wake_corrected=revision>=33;race.aero_wake_stability=revision>=34;race.aero_wet_line_stability=revision>=35;race.tactical_coordination_enabled=revision>=36;race.corner_battle_enabled=revision>=37;race.traffic_intelligence_enabled=revision>=38;race.traffic_pack_enabled=revision>=39;race.configure_weather(climate);race.running=true
 var corner_reasons:Dictionary={}
 var pack_modes:Dictionary={}
 var steering_examples:Array=[]
 var previous_steering:Dictionary={}
 var tow:=0;var dirty:=0;var max_tow:=0.0;var max_dirty:=0.0;var side:=0;var reverse_steer:=0;var stops:=0;var overlaps:=0;var reverse:=0;var passes:=0;var changed:=0;var last_sign:Dictionary={};var initial:Dictionary={};var start:=Time.get_ticks_usec()
 for c in race.cars:initial[c.id]=int(c.grid)
 var by_driver:Dictionary={};var last_active_tick:Dictionary={};var rapid_by_driver:Dictionary={};var engine_us:int=0;var actual_ticks:int=0;var peak_memory:float=0.0;var pits:int=0;var classification:Array=[];var wet_min:float=1.0;var wet_max:float=0.0;var release_overlaps:int=0;var examples:Array=[]
 for tick in range(ticks):
  if race.finished:break
  var before:Dictionary={}
  for c in race.cars:before[c.id]=c.duplicate(false)
  var step_start:=Time.get_ticks_usec()
  race.step(.2)
  engine_us+=Time.get_ticks_usec()-step_start
  actual_ticks+=1
  var wet_now:float=float(race.weather_snapshot().get("wetness_factor",0.0))
  wet_min=minf(wet_min,wet_now);wet_max=maxf(wet_max,wet_now)
  if tick%100==0:peak_memory=maxf(peak_memory,Performance.get_monitor(Performance.MEMORY_STATIC))
  for c in race.cars:
   if float(c.pit_left)>0 and float(before[c.id].pit_left)<=0:pits+=1
  if race.clock<24:continue
  var active:Array=[]
  var all_active:Array=[]
  for c in race.cars:
   if Space.active(c):all_active.append(c)
  for i in range(all_active.size()):
   for j in range(i+1,all_active.size()):
    var a:Dictionary=all_active[i];var b:Dictionary=all_active[j]
    if Space.active(before[a.id]) and Space.active(before[b.id]):continue
    var release_gap:float=absf(Merge.relative_gap(float(a.progress),float(b.progress),float(race.space_profile.length)))
    if release_gap<6.39999 and absf(float(a.race_lane)-float(b.race_lane))<2.94999:
     release_overlaps+=1
     if examples.size()<12:examples.append({"kind":"pit_release_overlap","tick":tick,"a":a.id,"b":b.id,"gap":release_gap})
  for c in race.cars:
   if not Space.active(c) or not Space.active(before[c.id]):
    last_sign.erase(c.id);last_active_tick.erase(c.id);continue
   active.append(c)
   var delta:float=float(c.progress)-float(before[c.id].progress)
   if delta<=1e-8:
    stops+=1
    if examples.size()<12:examples.append({"kind":"stationary","tick":tick,"id":c.id,"progress":c.progress,"lane":c.race_lane,"state":c.combat_state,"blocked":c.race_space_blocked})
   if delta< -1e-8:reverse+=1
   var pack_mode:String=str(c.get("traffic_pack_09201",{}).get("mode",""))
   if not pack_mode.is_empty():pack_modes[pack_mode]=int(pack_modes.get(pack_mode,0))+1
   var reason:String=str(c.get("racecraft_memory",{}).get("corner_reason",""))
   if not reason.is_empty():corner_reasons[reason]=int(corner_reasons.get(reason,0))+1
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
      if steering_examples.size()<120:
       steering_examples.append({"tick":tick,"id":c.id,"progress":c.progress,"previous":previous_steering.get(c.id,{}),"lane_before":before[c.id].race_lane,"lane_after":c.race_lane,"load":line.load,"memory_before":before[c.id].get("racecraft_memory",{}),"memory_after":c.get("racecraft_memory",{})})
      if tick-int(last_active_tick.get(c.id,-100))<=10:
       rapid_by_driver[c.id]=int(rapid_by_driver.get(c.id,0))+1
     last_active_tick[c.id]=tick
     last_sign[c.id]=sign_d
     previous_steering[c.id]={"tick":tick,"lane":c.race_lane,"progress":c.progress,"load":line.load,"mode":c.get("racecraft_memory",{}).get("mode","")}
   else:
    last_sign.erase(c.id);last_active_tick.erase(c.id)
  for i in range(active.size()):
   for j in range(i+1,active.size()):
    var gap:float=absf(Merge.relative_gap(float(active[i].progress),float(active[j].progress),float(race.space_profile.length)))
    var lane:float=absf(float(active[i].race_lane)-float(active[j].race_lane))
    if gap<6.39999 and lane<2.94999:
     overlaps+=1
     if examples.size()<12:examples.append({"kind":"overlap","tick":tick,"a":active[i].id,"b":active[j].id,"gap":gap,"lane":lane})
    if gap<7.4 and lane>=2.94:side+=1
 var sorted:Array=race.get_sorted()
 for i in range(sorted.size()):
  classification.append({"id":sorted[i].id,"position":sorted[i].position,"laps":sorted[i].get("finish_laps",0),"finished":sorted[i].finished})
  passes+=int(sorted[i].combat_passes)
  if int(initial[sorted[i].id])!=i+1:changed+=1
 return {"pack_modes":pack_modes,"steering_examples":steering_examples,"corner_reasons":corner_reasons,"hash":Codec.sporting_hash(race,{}),"tow_samples":tow,"dirty_samples":dirty,"max_tow":max_tow,"max_dirty":max_dirty,"stopped":stops,"reversals":reverse,"overlaps":overlaps,"straight_reversals":reverse_steer,"side":side,"passes":passes,"changed_grid":changed,"elapsed_us":Time.get_ticks_usec()-start,"engine_us":engine_us,"ticks":actual_ticks,"peak_static_bytes_sampled":peak_memory,"pits":pits,"finished":race.finished,"leader_finished":race.first_finish_at>=0.0,"classification":classification,"driver_reversals":by_driver,"rapid_driver_reversals":rapid_by_driver,"release_overlaps":release_overlaps,"examples":examples,"wet_min":wet_min,"wet_max":wet_max,"engine_us_per_tick":float(engine_us)/maxi(1,actual_ticks)}
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
 var mega:bool=OS.get_environment("APEX_TRAFFIC_MEGA")=="1"
 var traffic:bool=OS.get_environment("APEX_DRIVER_TRAFFIC")=="1" and not mega
 var corner:bool=OS.get_environment("APEX_CORNER_BATTLE")=="1" and not traffic and not mega
 var coordinated:bool=OS.get_environment("APEX_COORDINATION")=="1" and not corner and not traffic and not mega
 var old=drive(data,track,38 if mega else (37 if traffic else (36 if corner else (35 if coordinated else 31))),climate,ticks,seed)
 var new=drive(data,track,39 if mega else (38 if traffic else (37 if corner else (36 if coordinated else 35))),climate,ticks,seed)
 print("AERO_WAKE_AB ",JSON.stringify({"track":code,"climate":climate,"ticks":ticks,"seed":seed,"full":full,"old":old,"new":new}))
 check(new.tow_samples>0 and new.dirty_samples>0,"both effects exercised")
 if mega:check(not new.pack_modes.is_empty() and old.pack_modes.is_empty(),"039 traffic states actually exercised")
 check(new.max_tow<=Aero.TOW_FRACTION and new.max_dirty<=Aero.DIRTY_FRACTION,"bounded modifiers")
 check(new.overlaps<=old.overlaps and new.stopped<=old.stopped and new.reversals==0,"no safety regression")
 check(new.release_overlaps==0,"no overlap on pit rejoin")
 check(new.straight_reversals<=old.straight_reversals+maxi(2,ceili(old.straight_reversals*.10)),"aggregate steering regression <=10% (two-event floor)")
 for id in new.driver_reversals:
  var baseline:int=int(old.driver_reversals.get(id,0))
  check(int(new.driver_reversals[id])<=baseline+maxi(3,ceili(baseline*.10)),"individual steering regression id="+str(id))
 for id in new.rapid_driver_reversals:
  var baseline:int=int(old.rapid_driver_reversals.get(id,0))
  check(int(new.rapid_driver_reversals[id])<=baseline+maxi(2,ceili(baseline*.10)),"rapid steering reversals id="+str(id))
 if full and climate=="Variável":
  check(new.wet_max-new.wet_min>.10,"variable weather exercised")
 if full:
  check(old.finished and new.finished and old.leader_finished and new.leader_finished,"both GPs reach chequered flag and finish")
  check(new.classification.size()==24 and new.pits>0,"classification and actual pit entries")
  var ids:Dictionary={};var ranks:Dictionary={}
  for entry in new.classification:
   ids[entry.id]=true;ranks[entry.position]=true
   check(entry.finished,"classified car finished id="+str(entry.id))
  check(ids.size()==24 and ranks.size()==24,"unique final classification")
 if code=="ITA" and climate=="Seco" and seed==42:
  if ticks==600 and not coordinated and not corner and not traffic and not mega:check(old.hash=="4f2d91a2a34de0c8e0bcf04fef7f84858fdc4aafbfcc2230909b5524a54b8514","independent 031 reference")
  if ticks==1800 and coordinated:
   check(old.hash=="067ec801e8bef03f137cfcadd229f2662cc400f8ccdbbe17f8ed45ffa1fc9e85","historical CI 035 hash")
  if ticks==1800 and mega:
   check(old.hash=="9190524493e933da0ce1268ebaaeea89d601f1ba6c1136dd1247643d684b440d","historical CI 038 hash")
  if ticks==1800 and traffic:
   check(old.hash=="9190524493e933da0ce1268ebaaeea89d601f1ba6c1136dd1247643d684b440d","historical CI 037 hash")
  if ticks==1800 and corner:
   check(old.hash=="e3eeb1189ffb049d65706b8c189dcc3e3b67111e42efed3383c7ec665de0ff53","historical CI 036 hash")
  if ticks==1800 and not coordinated and not corner and not traffic and not mega:
   check(old.hash=="0174f579e29d197c24df060340a95147407eb8bcaecc90f0e56ca0f3f265dab9","historical CI 031 hash")
   var historical=drive(data,track,32,climate,ticks,seed)
   check(historical.hash=="7d40eff8b5285682a7aa5165d96fb91b0f4dc7366c0ff17b9d367baa6e4bcbc9","historical CI 032 hash")
   print("AERO_WAKE_HISTORICAL_032 ",JSON.stringify(historical))
   var historical_034=drive(data,track,34,climate,ticks,seed)
   check(historical_034.hash=="067ec801e8bef03f137cfcadd229f2662cc400f8ccdbbe17f8ed45ffa1fc9e85","historical CI 034 hash")
  var again=drive(data,track,39 if mega else (38 if traffic else (37 if corner else (36 if coordinated else 35))),climate,ticks,seed)
  check(new.hash==again.hash,"deterministic selected revision")
  for rev in [Replay.PRE_AERO_WAKE_SIMULATION_REVISION,Replay.PRE_WAKE_SOURCE_SIMULATION_REVISION,Replay.PRE_WAKE_STABILITY_SIMULATION_REVISION,Replay.PRE_WET_LINE_SIMULATION_REVISION,Replay.PRE_COORDINATION_SIMULATION_REVISION,Replay.PRE_CORNER_BATTLE_SIMULATION_REVISION,Replay.PRE_DRIVER_TRAFFIC_SIMULATION_REVISION,Replay.PRE_TRAFFIC_PACK_SIMULATION_REVISION,Replay.SIMULATION_REVISION]:
   var rec=Replay.new();rec.attach(Race.new(data.teams,"Ferrari",42,{},track,{}));rec.recorded_simulation_revision=rev
   for i in range(350):check(rec.step_tick(),"record tick")
   var play=Replay.new()
   check(play.load_data(rec.export_data()) and play.seek(350) and play.first_divergence<0,"archive "+rev)
   check(play.seek(170) and play.seek(350),"seek "+rev)
 print("AERO_WAKE_REPORT ",JSON.stringify({"checks":checks,"failures":failures}))
 if failures.is_empty():print("AERO_WAKE_091711_PASS")
 quit(0 if failures.is_empty() else 1)
