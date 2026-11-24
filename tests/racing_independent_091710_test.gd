extends SceneTree
const Space=preload("res://scripts/core/race_space_0655.gd")
const Decision=preload("res://scripts/core/race_independent_racecraft_091710.gd")
const Race=preload("res://scripts/race_engine.gd")
const Replay=preload("res://scripts/core/race_replay_0660.gd")
const Codec=preload("res://scripts/core/race_state_codec_0660.gd")
const Merge=preload("res://scripts/core/race_merge_traffic_0669174.gd")
var failures:Array[String]=[]
var checks:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);printerr("INDEPENDENT_FAIL ",label)
func fixture():
 var travel:Array=[]
 for modern in [false,true]:
  var cars:Array=[];var metrics:Dictionary={}
  for i in range(6):
   cars.append({"id":i,"progress":0.5-i*.014,"race_lane":0.0})
   metrics[i]={"target":100.0,"decision_pace":100.0,"line_ratio":0.0,"line_load":0.0,"ahead_load":0.0}
  var sum:=0.0
  var leader_travel:=0.0
  for t in range(100):
   metrics[0].line_ratio=1.0 if (t/10)%2==0 else -1.0
   # External lead-car intent, in a wide straight; no active attack.
   var plan:Dictionary=Space.plan(cars,metrics,.2,{"race_width_m":8.8,"overtake_zones":[]},{"length":1000.0},{},false,false,false,false,40.0,true,true,true,true,modern)
   for c in cars:
    if c.id>0:sum+=absf(float(c.race_lane)-float(plan[c.id].states.race_lane))
    else:leader_travel+=absf(float(c.race_lane)-float(plan[c.id].states.race_lane))
    check(float(plan[c.id].progress)>=float(c.progress),"non-reversing")
    c.progress=plan[c.id].progress;c.merge(plan[c.id].states,true)
  check(leader_travel>5.0,"lead actually changes lanes")
  travel.append(sum)
 check(travel[1]<travel[0]*0.30,"no chain copying")
 print("INDEPENDENT_CHAIN ",JSON.stringify({"legacy_travel":travel[0],"new_travel":travel[1]}))
 check(Decision.longitudinal(100,12,0,0,0)<100,"straight wake")
 check(Decision.longitudinal(100,12,0,0,1)>Decision.longitudinal(100,12,0,0,0),"wet wake weaker")
 check(Decision.longitudinal(100,12,0,.8,0)>100,"dirty air")
 check(Decision.longitudinal(100,12,2.0,.8,0)==100,"no effect outside wake")
 check(Decision.longitudinal(100,7.0,0,0,1)>100,"wet close following caution")
 var car={"id":1,"race_lane":0.0};var lead={"id":0,"race_lane":0.4};var intent={"state":"closing","goal":2.95,"defending":-1}
 for t in range(12):
  var d:Dictionary=Decision.decide(car,intent,lead,15,0,2.95,0,0,0,.2)
  car.racecraft_memory=d;car.race_lane=d.wanted
 check(car.racecraft_memory.mode=="DRAFT" and absf(float(car.racecraft_memory.aim))<=.45,"stable wake limited")
 var corner:Dictionary=Decision.decide(car,intent,lead,15,-1.0,2.95,.7,.7,0,.2)
 check(corner.mode=="FOLLOW" and corner.aim==-1.0,"independent curve line")
func drive(data:Dictionary,track:Dictionary,modern:bool,climate:String,ticks:int)->Dictionary:
 var race=Race.new(data.teams,"Ferrari",42,{},track,{})
 race.independent_racecraft_enabled=modern;race.configure_weather(climate);race.running=true
 var travel:=0.0;var straight_travel:=0.0;var reverse_steer:=0;var side:=0;var aligned:=0;var near:=0;var overlaps:=0;var stopped:=0;var last_sign:Dictionary={};var initial:Dictionary={};var modes:Dictionary={};var max_step:=0.0
 for c in race.cars:initial[c.id]=int(c.grid)
 for tick in range(ticks):
  var before:Dictionary={}
  for c in race.cars:before[c.id]=c.duplicate(false)
  race.step(.2)
  if race.clock<24.0:continue
  var active:Array=[]
  for c in race.cars:
   if not Space.active(c) or not Space.active(before[c.id]):continue
   active.append(c)
   var old:Dictionary=before[c.id]
   var d:float=float(c.race_lane)-float(old.race_lane)
   travel+=absf(d);max_step=maxf(max_step,absf(d))
   if float(c.progress)-float(old.progress)<=1e-8:stopped+=1
   var line:Dictionary=race.RacingLine.sample(race.racing_line_profile,float(c.progress),0,80)
   if float(line.load)<.12 and str(c.combat_state) not in Decision.ATTACK and int(c.race_defending_against)<0:
    straight_travel+=absf(d)
    if absf(d)>.025:
     var sign_d:float=signf(d)
     if last_sign.has(c.id) and last_sign[c.id]!=sign_d:reverse_steer+=1
     last_sign[c.id]=sign_d
   else:last_sign.erase(c.id)
   var mode:String=str(c.get("racecraft_memory",{}).get("mode","LEGACY"));modes[mode]=int(modes.get(mode,0))+1
  var sorted:Array=race.get_sorted()
  for i in range(1,sorted.size()):
   var a:Dictionary=sorted[i];var b:Dictionary=sorted[i-1]
   if not Space.active(a) or not Space.active(b):continue
   var gap:float=(float(b.progress)-float(a.progress))*race.space_profile.length
   var lane:float=absf(float(a.race_lane)-float(b.race_lane))
   if gap<=38:near+=1
   if gap<=38 and gap>=6.4 and lane<=.8:aligned+=1
   if gap<7.4 and lane>=2.94:side+=1
  for i in range(active.size()):
   for j in range(i+1,active.size()):
    if absf(Merge.relative_gap(float(active[i].progress),float(active[j].progress),float(race.space_profile.length)))<6.39999 and absf(float(active[i].race_lane)-float(active[j].race_lane))<2.94999:overlaps+=1
 var changed:=0;var passes:=0;var final:Array=race.get_sorted()
 for i in range(final.size()):
  if int(initial[final[i].id])!=i+1:changed+=1
  passes+=int(final[i].combat_passes)
 return {"hash":Codec.sporting_hash(race,{}),"travel":travel,"straight_travel":straight_travel,"straight_reversals":reverse_steer,"side":side,"near":near,"aligned":aligned,"stopped":stopped,"overlaps":overlaps,"changed_grid":changed,"passes":passes,"max_step":max_step,"modes":modes}
func run():
 fixture()
 if "--fixture-only" in OS.get_cmdline_user_args():
  print("INDEPENDENT_REPORT ",JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1);return
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
 var code:String=OS.get_environment("APEX_INDEPENDENT_TRACK") if OS.has_environment("APEX_INDEPENDENT_TRACK") else "ITA"
 var climate:String=OS.get_environment("APEX_INDEPENDENT_CLIMATE") if OS.has_environment("APEX_INDEPENDENT_CLIMATE") else "Seco"
 var ticks:int=int(OS.get_environment("APEX_INDEPENDENT_TICKS")) if OS.has_environment("APEX_INDEPENDENT_TICKS") else 600
 var track:Dictionary={}
 for t in data.tracks:
  if t.code==code:track=t;break
 var old:Dictionary=drive(data,track,false,climate,ticks)
 var new:Dictionary=drive(data,track,true,climate,ticks)
 print("INDEPENDENT_AB ",JSON.stringify({"track":code,"climate":climate,"ticks":ticks,"old":old,"new":new}))
 check(new.overlaps<=old.overlaps and new.stopped<=old.stopped,"no safety regression")
 check(new.straight_travel<old.straight_travel,"less unnecessary steering on straights")
 check(new.straight_reversals<=old.straight_reversals,"no steering reversal regression")
 check(new.hash!=old.hash,"new behavior exercised")
 if code=="ITA" and climate=="Seco":
  for rev in [Replay.PRE_INDEPENDENT_SIMULATION_REVISION,Replay.SIMULATION_REVISION]:
   var rec=Replay.new();rec.attach(Race.new(data.teams,"Ferrari",42,{},track,{}));rec.recorded_simulation_revision=rev
   for i in range(350):check(rec.step_tick(),"replay record")
   var play=Replay.new()
   check(play.load_data(rec.export_data()) and play.seek(350) and play.first_divergence<0,"archive "+rev)
   check(play.seek(170) and play.seek(350),"seek "+rev)
 print("INDEPENDENT_REPORT ",JSON.stringify({"checks":checks,"failures":failures}))
 if failures.is_empty():print("INDEPENDENT_091710_PASS")
 quit(0 if failures.is_empty() else 1)
