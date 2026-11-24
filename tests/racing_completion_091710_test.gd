extends SceneTree
const Race=preload("res://scripts/race_engine.gd")
const Space=preload("res://scripts/core/race_space_0655.gd")
const Merge=preload("res://scripts/core/race_merge_traffic_0669174.gd")
const Completion=preload("res://scripts/core/race_pass_completion_091710.gd")
const Replay=preload("res://scripts/core/race_replay_0660.gd")
const Codec=preload("res://scripts/core/race_state_codec_0660.gd")
var failures:Array[String]=[]
var checks:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:
  failures.append(label)
  printerr("COMPLETION_091710_FAIL ",label)
func fixture():
 var a={"id":0,"progress":0.19,"race_lane":-2.95};var b={"id":1,"progress":0.20,"race_lane":2.95}
 var old:Array=[a.duplicate(true),b.duplicate(true)]
 a.progress=0.201
 check(Completion.observe(old,[a,b],1000.0,.2).is_empty(),"nose crossing not a completed pass")
 old=[a.duplicate(true),b.duplicate(true)];a.progress=0.199
 check(Completion.observe(old,[a,b],1000.0,.2).is_empty() and not a.has("pass_confirmation_pairs"),"recross clears candidate")
 old=[a.duplicate(true),b.duplicate(true)];a.progress=0.201
 Completion.observe(old,[a,b],1000.0,.2)
 a.progress=0.207
 for i in range(4):
  check(Completion.observe([a.duplicate(true),b.duplicate(true)],[a,b],1000.0,.2).is_empty(),"clearance must persist")
 check(Completion.observe([a.duplicate(true),b.duplicate(true)],[a,b],1000.0,.2).get(0,0)==1,"one clearance-confirmed pass")
 check(Completion.observe([a.duplicate(true),b.duplicate(true)],[a,b],1000.0,.2).is_empty(),"no recount")
 a.progress=0.19;old=[a.duplicate(true),b.duplicate(true)];a.progress=0.21;a.pit_left=1.0
 check(Completion.observe(old,[a,b],1000.0,.2).is_empty(),"pit is not pass")
func drive(data:Dictionary,track:Dictionary,modern:bool,production:bool,climate:String,seed_value:int,ticks:int,dt:float)->Dictionary:
 var race=Race.new(data.teams,"Ferrari",seed_value,{},track,{})
 race.pass_completion_enabled=modern
 race.independent_racecraft_enabled=false
 race.merge_traffic_enabled=production
 race.configure_weather(climate);race.running=true
 var pairs:Dictionary={};var pending:Dictionary={};var cleared:=0;var raw:=0;var overlap:=0;var stopped:=0;var reversals:=0;var side:=0;var aligned:=0;var near:=0;var field_stop:=0;var initial:Dictionary={}
 for c in race.cars:initial[c.id]=int(c.grid)
 for tick in range(ticks):
  var before:Dictionary={}
  for c in race.cars:before[c.id]=c.duplicate(false)
  race.step(dt)
  if race.clock<24.0:continue
  var active:Array=[];var moving:=0
  for c in race.cars:
   if not Space.active(c) or not Space.active(before[c.id]):continue
   active.append(c)
   var delta:float=float(c.progress)-float(before[c.id].progress)
   if delta<=1e-8:stopped+=1
   else:moving+=1
   if delta< -1e-8:reversals+=1
  if not active.is_empty() and moving==0:field_stop+=1
  var sorted:Array=race.get_sorted()
  for i in range(1,sorted.size()):
   var a:Dictionary=sorted[i];var b:Dictionary=sorted[i-1]
   if not Space.active(a) or not Space.active(b):continue
   var gap:float=(float(b.progress)-float(a.progress))*race.space_profile.length
   var lane:float=absf(float(a.race_lane)-float(b.race_lane))
   if gap<=38.0:
    near+=1
    if lane<=0.8 and gap>=6.4:aligned+=1
   if gap<7.4 and lane>=2.94:side+=1
  for i in range(active.size()):
   var a:Dictionary=active[i]
   for j in range(i+1,active.size()):
    var b:Dictionary=active[j]
    var gap:float=(float(a.progress)-float(b.progress))*race.space_profile.length
    var prev:float=(float(before[a.id].progress)-float(before[b.id].progress))*race.space_profile.length
    var key:String="%d/%d"%[mini(a.id,b.id),maxi(a.id,b.id)]
    if absf(Merge.relative_gap(float(a.progress),float(b.progress),float(race.space_profile.length)))<6.39999 and absf(float(a.race_lane)-float(b.race_lane))<2.94999:overlap+=1
    if gap*prev<0.0:
     raw+=1;pairs[key]=int(pairs.get(key,0))+1;pending[key]=1 if gap>0 else -1
    if pending.has(key) and gap*int(pending[key])>=6.4:
     cleared+=1;pending.erase(key)
 var passes:=0;var changed:=0;var repeat:=0
 var final:Array=race.get_sorted()
 for i in range(final.size()):
  passes+=int(final[i].combat_passes)
  if int(initial[final[i].id])!=i+1:changed+=1
 for count in pairs.values():repeat+=maxi(0,int(count)-1)
 return {"raw_crossings":raw,"unique_pairs":pairs.size(),"repeat_crossings":repeat,"clearances":cleared,"confirmed_passes":passes,"changed_grid":changed,"side":side,"aligned":aligned,"near":near,"stopped":stopped,"reversals":reversals,"overlap":overlap,"field_stop":field_stop,"hash":Codec.sporting_hash(race,{})}
func run():
 fixture()
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
 var code:=OS.get_environment("APEX_COMPLETION_TRACK") if OS.has_environment("APEX_COMPLETION_TRACK") else "GBR"
 var climate:=OS.get_environment("APEX_COMPLETION_CLIMATE") if OS.has_environment("APEX_COMPLETION_CLIMATE") else "Seco"
 var production:=OS.get_environment("APEX_COMPLETION_PRODUCTION")!="0"
 var ticks:=int(OS.get_environment("APEX_COMPLETION_TICKS")) if OS.has_environment("APEX_COMPLETION_TICKS") else (600 if production else 240)
 var seed_value:=42 if production else 6617
 var dt:=0.2 if production else 0.5
 var track:Dictionary={}
 for item in data.tracks:
  if item.code==code:track=item;break
 var old=drive(data,track,false,production,climate,seed_value,ticks,dt)
 var new=drive(data,track,true,production,climate,seed_value,ticks,dt)
 print("COMPLETION_AB ",JSON.stringify({"track":code,"climate":climate,"production":production,"ticks":ticks,"old":old,"new":new}))
 # Independent REV2 references protect old sporting paths from accidental changes.
 var expected:Dictionary={"GBR":"283d1ee3f91082aad02f6c58a9df51325a81d33ac20ec7da63cd6239fab161d5","ITA":"095c6ad1e1c2e0fdb67564c1e452de53e88086c7eef9e9ca57855f953a5fdd3a","MON":"32e9dde5ac2f942c98b8e09e6b39535adc477e10ab90f2569663b4aa77b0a07e","ITA_WET":"ccfe25eaeee59feea2d82799c99ac155d4112065cbca420d0bf63c417a34597e"}
 if production and ticks==1800:
  var key:String=code+"_WET" if climate=="Chuva intensa" else code
  if expected.has(key):check(old.hash==expected[key],"independent 029 reference")
 check(new.overlap<=old.overlap and new.reversals==0 and new.field_stop==0,"safety")
 check(new.stopped<=old.stopped,"no stationary regression")
 if not production:
  check(new.changed_grid>=old.changed_grid,"classification diversity not reduced in reproduced defect")
  check(new.repeat_crossings<old.repeat_crossings and new.clearances>=old.clearances,"real swaps improve, clearance not lost")
  check(new.confirmed_passes<=24,"original pass ceiling respected")
 if production:
  check(new.side<=old.side*1.20+100,"no material side-by-side regression vs 029")
  check(float(new.aligned)/maxf(1.0,float(new.near))>=float(old.aligned)/maxf(1.0,float(old.near))-0.05,"wake alignment retained")
 if code=="GBR" and production and climate=="Seco":
  for revision in [Replay.PRE_COMPLETION_SIMULATION_REVISION,Replay.PRE_INDEPENDENT_SIMULATION_REVISION]:
   var rec=Replay.new();rec.attach(Race.new(data.teams,"Ferrari",42,{},track,{}));rec.recorded_simulation_revision=revision
   for i in range(600):check(rec.step_tick(),"record tick")
   var player=Replay.new()
   check(player.load_data(rec.export_data()) and player.seek(600) and player.first_divergence<0,"archive "+revision)
   check(player.seek(200) and player.seek(600),"seek "+revision)
 print("COMPLETION_REPORT ",JSON.stringify({"checks":checks,"failures":failures}))
 if failures.is_empty():print("COMPLETION_091710_PASS")
 quit(0 if failures.is_empty() else 1)
