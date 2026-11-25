extends SceneTree
const Setup=preload("res://scripts/core/race_weather_setup_15.gd")
const Wet=preload("res://scripts/core/race_wet_setup_0918.gd")
const Race=preload("res://scripts/race_engine.gd")
const Replay=preload("res://scripts/core/race_replay_0660.gd")
const Codec=preload("res://scripts/core/race_state_codec_0660.gd")
var checks:int=0
var failures:Array[String]=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);printerr("WET_SETUPS_FAIL ",label)
func run():
 var dry={"wetness_factor":0.0,"surface_lateral_load":1.0,"surface_traction":1.0,"grip_factor":1.0}
 var rain=dry.duplicate(true);rain.wetness_factor=.85;rain.grip_factor=.74
 for i in range(4):
  check(Setup.valid(Wet.settings(i)),"valid preset "+str(i))
 check(Wet.settings(-1).is_empty() and Wet.settings(4).is_empty(),"invalid preset rejected")
 var changed=Wet.settings(3);changed.wing=-1.0
 check(Wet.settings(3).wing==.85,"preset copies isolated")
 check(Wet.comparison(0,dry).pace_delta_s==0.0 and Wet.comparison(0,rain).wear_scale==1.0,"neutral exact")
 check(Wet.comparison(1,dry).pace_delta_s<Wet.comparison(3,dry).pace_delta_s,"dry precision faster in dry")
 check(Wet.comparison(3,rain).pace_delta_s<Wet.comparison(1,rain).pace_delta_s,"wet setup faster in wet")
 check(Wet.comparison(3,rain).wear_scale<Wet.comparison(1,rain).wear_scale,"wet suspension tyre benefit")
 check(Wet.comparison(3,dry).pace_delta_s>0.0,"wet setup costs pace when dry")
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
 for code in ["ITA","GBR","MON"]:
  var track:Dictionary={}
  for candidate in data.tracks:
   if candidate.code==code:track=candidate;break
  check(not track.is_empty(),"track "+code)
  for climate in ["Seco","Chuva intensa","Variável"]:
   var a=Race.new(data.teams,"Ferrari",42,{},track,{})
   var b=Race.new(data.teams,"Ferrari",42,{},track,{})
   a.configure_weather(climate);b.configure_weather(climate)
   var before=Codec.sporting_hash(a,{})
   check(Wet.apply(a,[0,0]) and Codec.sporting_hash(a,{})==before,"neutral unchanged "+code+climate)
   var rng_before:int=b.rng.state
   var players:Array=Wet.roster(b)
   var original:Dictionary=players[0].race_setup_15.duplicate(true)
   check(not Wet.apply(b,[3,99]) and players[0].race_setup_15==original,"invalid pair atomic")
   var tyre_before:String=players[0].tire
   var pit_before:int=players[0].pit_scheduled_lap
   check(Wet.apply(b,[3,1]),"two distinct presets")
   check(players[0].race_setup_15==Wet.settings(3) and players[1].race_setup_15==Wet.settings(1),"stable roster mapping")
   check(b.rng.state==rng_before and players[0].tire==tyre_before and players[0].pit_scheduled_lap==pit_before,"no RNG tyre or pit mutation")
   for car in b.cars:
    if car.team!="Ferrari":check(car.race_setup_15==Setup.neutral(),"rival remains neutral")
   a.running=true;b.running=true
   check(not Wet.apply(b,[0,0]),"locked after start")
   var initial:Dictionary={}
   for car in b.cars:initial[car.id]=float(car.progress)
   for step in range(180):
    a.step(.2);b.step(.2)
   for car in b.cars:check(float(car.progress)>=float(initial[car.id]),"no net reverse")
   check(Codec.sporting_hash(a,{})!=Codec.sporting_hash(b,{}),"configured sporting state differs")
   var original_players:Array=Wet.roster(a)
   check(absf(float(original_players[0].progress)-float(players[0].progress))>1e-9 or absf(float(original_players[0].wear)-float(players[0].wear))>1e-9,"setup actually affects movement or wear")
 var race=Race.new(data.teams,"Ferrari",42,{},data.tracks[0],{})
 race.configure_weather("Chuva intensa")
 check(Wet.apply(race,[3,2]),"apply before recording")
 var rec=Replay.new();rec.attach(race)
 for i in range(350):check(rec.step_tick(),"record tick")
 var playback=Replay.new()
 check(playback.load_data(rec.export_data()) and playback.seek(350) and playback.first_divergence<0,"configured replay deterministic")
 check(Wet.roster(playback.race)[0].race_setup_15==Wet.settings(3),"replay restores setup")
 check(playback.seek(170) and playback.seek(350),"configured replay seek")
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 check(game.wet_setup_pickers.size()==2,"both native controls")
 if game.wet_setup_pickers.size()==2:
  game.wet_setup_pickers[0].select(3)
  var previous_team:String=game.selected_team
  var alternative:int=1 if game.team_picker.selected==0 else 0
  game._on_team_selected(alternative)
  check(game.wet_setup_pickers[0].selected==0 and game.wet_setup_pickers[1].selected==0,"new team does not inherit another pair setup")
  for i in range(game.teams.size()):
   if str(game.teams[i].name)==previous_team:game._on_team_selected(i);break
  game.wet_setup_pickers[0].select(3)
  game.wet_setup_pickers[1].select(2)
  game._start_race()
  await process_frame
  var native:Array=Wet.roster(game.race)
  check(native.size()==2 and native[0].race_setup_15==Wet.settings(3) and native[1].race_setup_15==Wet.settings(2),"native launch applies selected setup")
 game.queue_free()
 await process_frame
 print("WET_SETUPS_REPORT ",JSON.stringify({"checks":checks,"failures":failures}))
 if failures.is_empty():print("WET_SETUPS_0918_PASS")
 quit(0 if failures.is_empty() else 1)
