extends SceneTree
const ErrorModel=preload("res://scripts/core/race_driver_error_0921.gd")
const Race=preload("res://scripts/race_engine.gd")
const Replay=preload("res://scripts/core/race_replay_0660.gd")
const Codec=preload("res://scripts/core/race_state_codec_0660.gd")
const Line=preload("res://scripts/core/race_racing_line_091710.gd")
var checks:int=0
var failures:Array[String]=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);printerr("DRIVER_ERROR_0921_FAIL ",label)
func car()->Dictionary:
 return {"id":12,"skill":85,"spatial_awareness":85,"risk_tolerance":55,"pace":"Normal","tire":"Médio","wear":15.0,"tyre_surface_c":96.0,"progress":.4,"driver_soul":{"focus":.85,"confidence":.6,"pressure":.15}}
func run():
 var dry={"wetness_factor":0.0,"grip_factor":1.0}
 var rain={"wetness_factor":.85,"grip_factor":.7}
 var entry={"line_load":.3,"ahead_load":.7}
 var exit={"line_load":.7,"ahead_load":.3}
 var base=car()
 var ctx=ErrorModel.context(base,entry,dry,.2)
 check(ctx.phase=="ENTRY" and ctx.hazard>0,"entry hazard")
 check(ErrorModel.context(base,exit,dry,.2).phase=="EXIT","exit classification")
 check(ErrorModel.context(base,{},dry,.2).hazard==0.0,"straight no random error")
 check(ErrorModel.context(base,entry,rain,.2).hazard>ctx.hazard,"wet mismatch risk")
 var pushing=base.duplicate(true);pushing.pace="Atacar"
 var saving=base.duplicate(true);saving.pace="Conservar"
 check(ErrorModel.context(pushing,entry,dry,.2).hazard>ctx.hazard and ErrorModel.context(saving,entry,dry,.2).hazard<ctx.hazard,"pace risk")
 var worn=base.duplicate(true);worn.wear=95.0;worn.tyre_surface_c=130.0
 check(ErrorModel.context(worn,entry,dry,.2).hazard>ctx.hazard,"wear temperature")
 var pressured=base.duplicate(true);pressured["traffic_pack_09201"]={"rear_s":.2};pressured["combat_state"]="duel"
 check(ErrorModel.context(pressured,entry,dry,3.5).pressure>ctx.pressure,"sustained rear pressure")
 var expert=base.duplicate(true);expert["consistency"]=99;expert["rain_skill"]=99
 var novice=base.duplicate(true);novice["consistency"]=40;novice["rain_skill"]=40
 check(ErrorModel.context(expert,entry,rain,.2).hazard<ErrorModel.context(novice,entry,rain,.2).hazard,"personality risk")
 var counts:Dictionary={}
 for i in range(10000):
  var u:float=ErrorModel.sample(42,12,i,2)
  check(u>=0 and u<1 and u==ErrorModel.sample(42,12,i,2),"deterministic bounded sample")
  var kind:String=ErrorModel.classify(ctx,u)
  counts[kind]=int(counts.get(kind,0))+1
 check(counts.size()==6 and int(counts.SPIN)<int(counts.LOCK_UP),"all six types, rare spin")
 for kind in ErrorModel.TYPES:
  var model=car()
  var state=ErrorModel.begin({},kind,ctx,.7)
  var planned:float=float(state.planned_loss)
  var spec:Array=ErrorModel.SPECS[kind]
  check(planned>=float(spec[0]) and planned<=float(spec[1]),"severity bounds "+kind)
  model[ErrorModel.KEY]=state
  var elapsed:float=0.0
  var seen:Dictionary={}
  for i in range(500):
   var next=ErrorModel.advance(model,entry,dry,.2,42,i,40.0+i*.2)
   seen[str(next.mode)]=true
   check(float(next.speed_fraction)>=.45 and float(next.speed_fraction)<=1.0,"positive speed")
   model[ErrorModel.KEY]=next
   elapsed+=.2
   if str(next.mode)=="NORMAL":break
  check(seen.has("RECOVERY") and seen.has("REBUILD") and seen.has("NORMAL"),"recovery phases "+kind)
  check(absf(float(model[ErrorModel.KEY].total_loss)-planned)<.000001,"integrated nominal loss "+kind)
  check(model[ErrorModel.KEY].count==1,"no chained error "+kind)
 var interrupted=car();interrupted[ErrorModel.KEY]=ErrorModel.begin({}, "SPIN",ctx,.5)
 check(ErrorModel.pit_reset(interrupted).interrupted_count==1 and ErrorModel.pit_reset(interrupted).speed_fraction==1.0,"pit interruption")
 var soul_car=car();var state=ErrorModel.begin({}, "LOCK_UP",ctx,.5)
 state["confidence_delta"]=-float(state.confidence_hit)
 ErrorModel.apply_soul(soul_car,state)
 var hit:float=float(soul_car.driver_soul.confidence)
 check(hit<.6,"confidence hit")
 state.mode="REBUILD";state.started=false;soul_car[ErrorModel.KEY]=state
 var rebuild=ErrorModel.advance(soul_car,entry,dry,.2,42,0,40.0)
 ErrorModel.apply_soul(soul_car,rebuild)
 check(float(soul_car.driver_soul.confidence)>hit and float(soul_car.driver_soul.confidence)<.6,"gradual partial confidence rebuild")
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
 var race=Race.new(data.teams,"Ferrari",42,{},data.tracks[0],{})
 var old=Race.new(data.teams,"Ferrari",42,{},data.tracks[0],{})
 old.driver_error_enabled=false
 race.configure_weather("Seco");old.configure_weather("Seco")
 race.running=true;old.running=true;race.clock=40.0;old.clock=40.0
 for i in range(24):
  race.cars[i].progress=2.04+i*.039;old.cars[i].progress=race.cars[i].progress
  race.cars[i].laps_done=2;old.cars[i].laps_done=2
 var player:Dictionary=race.player_cars()[0]
 var reference:Dictionary={}
 for item in old.cars:
  if int(item.id)==int(player.id):reference=item;break
 player["pit_scheduled_lap"]=21;reference["pit_scheduled_lap"]=21
 player[ErrorModel.KEY]=ErrorModel.begin({},"LOCK_UP",ctx,.8)
 var seed_state:int=race.rng.state
 var start:float=float(player.progress)
 race.step(.2);old.step(.2)
 check(float(player.progress)>start and float(player.progress)<float(reference.progress),"actual solver loss not stop")
 check(race.rng.state==old.rng.state and seed_state==race.rng.state,"isolated RNG on error tick")
 check(int(player.pit_scheduled_lap)==21,"manual pit protected")
 check(not reference.has(ErrorModel.KEY),"039 no state")
 var old_hash:String=Codec.sporting_hash(old,{})
 for i in range(80):race.step(.2)
 check(float(player[ErrorModel.KEY].total_loss)>0.0 and int(player[ErrorModel.KEY].count)>=1,"native recovery")
 var observed:bool=false
 for item in race.telemetry.position_history:
  if item.has("error_mode"):observed=true;break
 check(observed,"native error telemetry")
 # A natural deterministic trigger in the real engine: select a loaded
 # corner and counter sample, without a test hook in production code.
 var natural=Race.new(data.teams,"Ferrari",42,{},data.tracks[0],{})
 natural.configure_weather("Seco");natural.running=true;natural.clock=40.0
 var chosen:Dictionary=natural.player_cars()[0]
 var fraction:float=.25
 for i in range(1,100):
  var candidate:float=float(i)/100.0
  var profile:Dictionary=Line.sample(natural.racing_line_profile,candidate,0.0,float(chosen.skill))
  if float(profile.load)>.4:fraction=candidate;break
 var index:int=1
 for item in natural.cars:
  if int(item.id)==int(chosen.id):item.progress=2.0+fraction
  else:
   item.progress=2.0+fposmod(fraction+float(index)/24.0,1.0)
   index+=1
  item.laps_done=2
 var trigger:int=-1
 for i in range(1000000):
  if ErrorModel.sample(42,int(chosen.id),i,1)<.00001:trigger=i;break
 check(trigger>=0,"deterministic natural trigger found")
 if trigger>=0:
  natural.tick_counter=trigger
  chosen["pit_scheduled_lap"]=21
  natural.step(.2)
  check(int(chosen.get(ErrorModel.KEY,{}).get("count",0))==1,"natural engine error starts")
  check(bool(chosen.get(ErrorModel.KEY,{}).get("radio_announced",false)),"natural player radio announced")
  var incident:bool=false;var reply:bool=false
  for event in natural.events:
   if int(event.driver_id)!=int(chosen.id):continue
   if str(event.type)=="incident":incident=true
   if str(event.type)=="engineer_reply":reply=true
  check(incident and reply,"actual incident and engineer event")
  check(int(chosen.pit_scheduled_lap)==21,"natural error retains BOX V21")
 var historical=Race.new(data.teams,"Ferrari",42,{},data.tracks[0],{})
 historical.following_enabled=false
 check(not historical._driver_error_active(),"historical flag chain")
 var rec=Replay.new();rec.attach(Race.new(data.teams,"Ferrari",42,{},data.tracks[0],{}))
 for i in range(200):check(rec.step_tick(),"record 040")
 var play=Replay.new()
 check(play.load_data(rec.export_data()) and play.seek(200) and play.first_divergence<0,"040 replay")
 check(play.seek(100) and play.seek(200),"040 seek")
 print("DRIVER_ERROR_REPORT ",JSON.stringify({"checks":checks,"failures":failures,"classification":counts,"native_loss":player[ErrorModel.KEY].total_loss,"old_hash":old_hash}))
 if failures.is_empty():print("DRIVER_ERROR_0921_PASS")
 quit(0 if failures.is_empty() else 1)
