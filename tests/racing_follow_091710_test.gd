extends SceneTree
const Race=preload("res://scripts/race_engine.gd")
const Merge=preload("res://scripts/core/race_merge_traffic_0669174.gd")
const Space=preload("res://scripts/core/race_space_0655.gd")
const Replay=preload("res://scripts/core/race_replay_0660.gd")
const Codec=preload("res://scripts/core/race_state_codec_0660.gd")
var failures:Array[String]=[]
var checks:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:
  failures.append(label)
  printerr("FOLLOW_091710_FAIL ",label)
func fixture():
 var cars=[{"id":0,"progress":0.2,"race_lane":-2.95},{"id":1,"progress":0.198,"race_lane":2.95}]
 var track={"race_width_m":8.8,"overtake_zones":[]}
 var shape={"length":1000.0}
 var metrics={0:{"target":100.0,"decision_pace":100.0,"line_load":0.0},1:{"target":100.0,"decision_pace":100.0,"line_load":0.0}}
 for modern in [false,true]:
  var grid:Array=cars.duplicate(true)
  for tick in range(120):
   var p=Space.plan(grid,metrics,0.2,track,shape,{},false,false,false,false,30.0,true,true,modern)
   for c in grid:
    check(float(p[c.id].progress)>=float(c.progress),"no backwards")
    c.progress=p[c.id].progress
    c.merge(p[c.id].states,true)
   var gap:float=(float(grid[0].progress)-float(grid[1].progress))*1000.0
   check(gap>=6.4-0.00001 or absf(float(grid[0].race_lane)-float(grid[1].race_lane))>=2.95-0.00001,"safe separation")
  print("FOLLOW_FIXTURE ",JSON.stringify({"modern":modern,"gap":(grid[0].progress-grid[1].progress)*1000,"lanes":[grid[0].race_lane,grid[1].race_lane]}))
  if modern:check(absf(float(grid[0].race_lane)-float(grid[1].race_lane))<0.8,"passive car settles behind")
 var lead={"id":0,"progress":0.2,"race_lane":0.0};var follower={"id":1,"progress":0.19,"race_lane":0.0}
 var pair=[lead,follower]
 var dry=Space.plan(pair,metrics,0.2,track,shape,{},false,false,false,false,30.0,true,true,true)
 var old=Space.plan(pair,metrics,0.2,track,shape,{},false,false,false,false,30.0,true,true,false)
 var wet=Space.plan(pair,metrics,0.2,track,shape,{"wetness_factor":1.0},false,false,false,false,30.0,true,true,true)
 check(dry[1].progress>old[1].progress and wet[1].progress<dry[1].progress,"aligned dry wake, reduced wet gain")
 metrics[1].line_load=0.8
 var corner=Space.plan(pair,metrics,0.2,track,shape,{},false,false,false,false,30.0,true,true,true)
 check(corner[1].progress==old[1].progress,"no wake gain at apex")
 var fast_pair=[{"id":0,"progress":0.2,"race_lane":1.0},{"id":1,"progress":0.185,"race_lane":-2.95,"attack_charge":2.5,"combat_target_id":0,"skill":90.0}]
 var fast_metrics={0:{"target":100.0,"decision_pace":100.0},1:{"target":90.0,"decision_pace":90.0}}
 track.overtake_zones=[[0.0,1.0]]
 var attack=Space.plan(fast_pair,fast_metrics,0.2,track,shape,{},false,false,false,false,30.0,true,true,true)
 check(str(attack[1].states.combat_state) in ["attacking","preparing","duel"],"clear faster driver can attack")
 var aligned_pair=[{"id":0,"progress":0.2,"race_lane":1.1},{"id":1,"progress":0.19,"race_lane":1.1,"attack_charge":2.5,"combat_target_id":0,"skill":90.0}]
 var blocked_old=Space.plan(aligned_pair,fast_metrics,0.2,track,shape,{},false,false,false,false,30.0,true,true,false)
 var open_new=Space.plan(aligned_pair,fast_metrics,0.2,track,shape,{},false,false,false,false,30.0,true,true,true)
 check(str(blocked_old[1].states.combat_state)=="closing" and str(open_new[1].states.combat_state)=="preparing" and float(open_new[1].states.race_lane_goal)<0.0,"aligned pursuer can select opposite clear corridor")
 check(Space.plan(fast_pair,fast_metrics,0.2,track,shape,{},false,false,false,false,12.0,true,true,true)==Space.plan(fast_pair,fast_metrics,0.2,track,shape,{},false,false,false,false,12.0,true,true,false),"launch window unchanged")
func drive(data:Dictionary,track:Dictionary,modern:bool,climate:String,seed_value:int,ticks:int)->Dictionary:
 var race=Race.new(data.teams,"Ferrari",seed_value,{},track,{})
 race.following_enabled=modern
 race.pass_completion_enabled=false
 race.configure_weather(climate)
 race.running=true
 var side:=0;var aligned:=0;var near:=0;var longest:=0;var overlap:=0;var stopped:=0;var runs:Dictionary={};var passive_runs:Dictionary={};var passive_side:=0;var passive_longest:=0;var last:Dictionary={};var passes:=0;var reversals:=0;var initial:Dictionary={}
 for c in race.cars:
  last[c.id]=c.progress
  initial[c.id]=int(c.grid)
 for tick in range(ticks):
  race.step(.2)
  var sorted:Array=race.get_sorted()
  var active:Array=[];var current_runs:Dictionary={};var current_passive:Dictionary={}
  for i in range(sorted.size()):
   var a:Dictionary=sorted[i]
   var delta:float=float(a.progress)-float(last[a.id]);last[a.id]=a.progress
   if tick<120 or a.finished or a.pit_left>0:continue
   active.append(a)
   if delta<=1e-8:stopped+=1
   if delta< -1e-8:reversals+=1
   if i==0:continue
   var b:Dictionary=sorted[i-1]
   if b.finished or b.pit_left>0:continue
   var gap:float=(float(b.progress)-float(a.progress))*race.space_profile.length
   var lane:float=absf(float(a.race_lane)-float(b.race_lane))
   if gap<=38:
    near+=1
    if lane<=0.8 and gap>=6.4:aligned+=1
   var key:String=str(a.id)+":"+str(b.id)
   if gap<7.4 and lane>=2.94:
    side+=1;current_runs[key]=int(runs.get(key,0))+1;longest=maxi(longest,current_runs[key])
    if str(a.combat_state) not in ["preparing","attacking","duel"] and str(b.combat_state) not in ["preparing","attacking","duel"]:
     passive_side+=1;current_passive[key]=int(passive_runs.get(key,0))+1;passive_longest=maxi(passive_longest,current_passive[key])
  runs=current_runs;passive_runs=current_passive
  for i in range(active.size()):
   for j in range(i+1,active.size()):
    if absf(Merge.relative_gap(float(active[i].progress),float(active[j].progress),float(race.space_profile.length)))<6.39999 and absf(float(active[i].race_lane)-float(active[j].race_lane))<2.94999:overlap+=1
 var changed:=0
 var sorted_final:Array=race.get_sorted()
 for i in range(sorted_final.size()):
  var c:Dictionary=sorted_final[i]
  passes+=int(c.get("combat_passes",0))
  if int(initial[c.id])!=i+1:changed+=1
 return {"side":side,"passive_side":passive_side,"passive_longest_samples":passive_longest,"aligned":aligned,"near":near,"longest_samples":longest,"overlap":overlap,"stopped":stopped,"passes":passes,"changed_grid_positions":changed,"reversals":reversals,"hash":Codec.sporting_hash(race,{})}
func run():
 fixture()
 if "--fixture-only" in OS.get_cmdline_user_args():
  print("FOLLOW_REPORT ",JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1);return
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
 var code=OS.get_environment("APEX_FOLLOW_TRACK") if OS.has_environment("APEX_FOLLOW_TRACK") else "GBR"
 var climate=OS.get_environment("APEX_FOLLOW_CLIMATE") if OS.has_environment("APEX_FOLLOW_CLIMATE") else "Seco"
 var ticks:int=int(OS.get_environment("APEX_FOLLOW_TICKS")) if OS.has_environment("APEX_FOLLOW_TICKS") else 1800
 var track:Dictionary={}
 for t in data.tracks:
  if t.code==code: track=t;break
 var old=drive(data,track,false,climate,42,ticks)
 var now=drive(data,track,true,climate,42,ticks)
 print("FOLLOW_AB ",JSON.stringify({"track":code,"climate":climate,"ticks":ticks,"old":old,"new":now}))
 check(now.overlap<=old.overlap and now.reversals==0 and now.stopped<=old.stopped,"no safety regression")
 check(now.side<=old.side and now.longest_samples<=old.longest_samples,"no side-by-side regression")
 check(now.hash!=old.hash,"new rule exercised")
 if ticks==600 and code=="ITA" and climate=="Seco": check(old.hash=="38ba4791e4c08154d2e33006e4dd578f85218fda850e0233e26ecf94e34ca27d","independent 028 reference")
 check(float(now.aligned)/maxf(1.0,float(now.near))>=float(old.aligned)/maxf(1.0,float(old.near)),"alignment does not regress")
 if code=="ITA" and climate=="Seco": check(now.side<old.side and now.longest_samples<old.longest_samples,"reported Monza defect must improve")
 if code=="GBR" and climate=="Seco":
  var rec=Replay.new();rec.attach(Race.new(data.teams,"Ferrari",42,{},track,{}))
  rec.recorded_simulation_revision=Replay.PRE_COMPLETION_SIMULATION_REVISION
  for i in range(350): check(rec.step_tick(),"029 record tick")
  var player=Replay.new()
  check(player.load_data(rec.export_data()) and player.seek(350) and player.first_divergence<0,"029 replay and seek")
 print("FOLLOW_REPORT ",JSON.stringify({"checks":checks,"failures":failures}))
 if failures.is_empty():print("FOLLOW_091710_PASS")
 quit(0 if failures.is_empty() else 1)
