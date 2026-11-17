extends SceneTree
## Extended HUD/live-replay scenarios through at least three completed laps.
## No fake shortcuts to the grid or accelerated sporting ticks.
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const SCENARIOS = [
 {"code":"GBR","weather":"Seco","name":"Silverstone dry"},
 {"code":"BEL","weather":"Chuva intensa","name":"Spa heavy rain"},
 {"code":"ITA","weather":"Seco","name":"Monza dry"},
 {"code":"SIN","weather":"Chuva intensa","name":"Singapore heavy rain"}
]
var failed: Array[String]=[]
func _initialize()->void: call_deferred("_run")
func _run()->void:
 var results: Array=[]
 for scenario in SCENARIOS:
  var host=load("res://scenes/main.tscn").instantiate()
  root.add_child(host)
  await process_frame
  host.set_process(false)
  host.seed_picker.value=660
  var found := false
  for i in range(host.season_tracks.size()):
   if str(host.season_tracks[i].get("code",""))==str(scenario.code):
    host.selected_track_index=i
    found=true
    break
  var weather_found := false
  for i in range(host.weather_mode_picker.item_count):
   if host.weather_mode_picker.get_item_text(i)==str(scenario.weather):
    host.weather_mode_picker.select(i)
    weather_found=true
    break
  if not found or not weather_found:
   failed.append("setup: "+str(scenario.name))
   host.queue_free()
   await process_frame
   continue
  host._start_race()
  var race=host.race
  var replay=host.replay_session
  var hud=host.race_hud_0620
  var read_integrity := true
  var steps := 0
  var refreshing := 0
  var transitions := 0
  var timer := Time.get_ticks_msec()
  while int(race.lap)<4 and not race.finished and steps<6000:
   if not replay.step_tick():
    failed.append(str(scenario.name)+" replay tick failed: "+replay.error)
    break
   steps+=1
   if steps%40==0:
    var state_before: String=Codec.sporting_hash(race,replay.policy)
    var mode: int=int(steps/400)%3
    hud._change_hud_mode(mode)
    transitions+=1
    hud.refresh_hud()
    refreshing+=1
    if Codec.sporting_hash(race,replay.policy)!=state_before:
     read_integrity=false
     failed.append(str(scenario.name)+" HUD changed sporting hash")
     break
    if hud.standing_rows.size()!=24 or hud.race_card_panels.size()!=2:
     failed.append(str(scenario.name)+" HUD grid missing rows/cards")
     break
  var result: Dictionary={"name":scenario.name,"tick_count":steps,"lap_reached":int(race.lap),"frames_refreshed":refreshing,"mode_changes":transitions,"read_only":read_integrity,"seconds":float(Time.get_ticks_msec()-timer)/1000.0,"race_finished":bool(race.finished),"last_hash":str(replay.hashes[-1]) if replay.hashes.size()>0 else ""}
  if int(race.lap)<4 and not race.finished:
   failed.append(str(scenario.name)+" did not complete 3 laps")
  results.append(result)
  print("HUD_06681_SCENARIO ",JSON.stringify(result))
  host.queue_free()
  for _i in range(3): await process_frame
 print("HUD_06681_RACE_SCENARIOS ",JSON.stringify({"status":"PASS" if failed.is_empty() else "FAIL","scenarios":results,"errors":failed}))
 quit(0 if failed.is_empty() else 1)
