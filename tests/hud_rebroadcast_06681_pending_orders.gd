extends SceneTree
## v0.6.6.8.1 regression: queued != confirmed; all observations must be read-only.
const Hud = preload("res://scripts/apex_hud_rebroadcast_0668.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var checks := 0
var errors: Array[String] = []
func check(ok: bool, description: String) -> void:
 checks += 1
 if not ok:
  errors.append(description)
  printerr("HUD_06681_FAIL ", description)
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
 var host = load("res://scenes/main.tscn").instantiate()
 root.add_child(host)
 await process_frame
 host.set_process(false)
 host.seed_picker.value=660
 for i in range(host.season_tracks.size()):
  if str(host.season_tracks[i].get("code", "")) == "BEL":
   host.selected_track_index=i
   break
 for i in range(host.weather_mode_picker.item_count):
  if host.weather_mode_picker.get_item_text(i)=="Chuva intensa":
   host.weather_mode_picker.select(i)
   break
 host._start_race()
 var race = host.race
 var replay = host.replay_session
 var hud = host.race_hud_0620
 var id: int = int(race.player_cars()[0].get("id", -1))
 var compound: String = race.available_pit_compounds()[0]
 var state_before: Dictionary = Codec.capture(race)
 var hash_before: String = Codec.sporting_hash(race, replay.policy)
 check(Hud.pending_pit_by_driver(null).is_empty(), "empty queue without session")
 check(race.schedule_pit(id,compound,21), "manual schedule enqueue accepted")
 check(int(race.player_cars()[0].get("pit_scheduled_lap",0))==0, "queued does not prematurely apply sports")
 check(Codec.sporting_hash(race,replay.policy)==hash_before, "enqueue does not change sporting hash")
 hud.refresh_hud()
 var sorted: Array = race.get_sorted()
 var row_index := -1
 for j in range(sorted.size()):
  if int(sorted[j].get("id",-1))==id:
   row_index=j
   break
 check(row_index>=0, "car in classification")
 if row_index>=0:
  var row: Dictionary = hud.standing_rows[row_index]
  check(row["state"].text=="P21", "pending V21 clearly differs from confirmed V21")
  check("PENDENTE" in row["driver"].tooltip_text, "pending command tooltip")
 check(bool(hud.race_card_panels[0]["quick"].disabled), "quick pit disabled while command queued")
 check("PENDENTE" in hud.race_card_panels[0]["secondary"].text, "driver card pending status")
 check(Codec.sporting_hash(race,replay.policy)==hash_before, "HUD does not mutate sporting hash")
 check(Codec.capture(race)==state_before, "HUD queue projection does not mutate engine snapshot")
 check(replay.step_tick(), "apply queue at next tick")
 hud.refresh_hud()
 check(int(race.player_cars()[0].get("pit_scheduled_lap",0))==21, "manual V21 becomes confirmed")
 if row_index>=0:
  check(hud.standing_rows[row_index]["state"].text=="V21", "confirmed V21 displayed")
 check(race.cancel_scheduled_pit(id), "cancel order queued")
 hud.refresh_hud()
 if row_index>=0:
  check(hud.standing_rows[row_index]["state"].text=="CANC", "cancel remains pending until tick")
 check(replay.step_tick(), "cancel applied at tick")
 hud.refresh_hud()
 check(int(race.player_cars()[0].get("pit_scheduled_lap",0))==0, "cancel took effect")
 if row_index>=0:
  check(hud.standing_rows[row_index]["state"].text=="", "obsolete pending marker removed")
 # Exercise the live quick-action button as well as the backend enqueue path.
 hud._quick_box(0)
 var queued: Dictionary = Hud.pending_pit_by_driver(replay).get(id, {})
 check(str(queued.get("type", "")) == "order_pit", "quick box routes into validated queue")
 if row_index>=0:
  check(hud.standing_rows[row_index]["state"].text=="PBOX", "immediate box pending displayed")
 check(bool(hud.race_card_panels[0]["quick"].disabled), "cannot click quick box again while pending")
 check(replay.step_tick(), "immediate command applied at correct tick")
 hud.refresh_hud()
 check(bool(race.player_cars()[0].get("pit_request", false)), "immediate box confirmed by engine")
 if row_index>=0:
  check(hud.standing_rows[row_index]["state"].text=="BOX", "confirmed immediate box displayed")
 check(Hud._order_status({"finished":true})=="FIN", "finished status projected")
 check(Hud._order_status({"disqualified":true,"finished":true})=="DSQ", "DSQ precedence")
 check(Hud.pending_label({"type":"order_pit"})=="PBOX", "immediate order pending label")
 check(Hud.pending_label({"type":"cancel_scheduled_pit"})=="CANC", "cancellation pending label")
 check(Hud.pending_pit_by_driver(replay).is_empty(), "no stale commands after cursor")
 print("HUD_06681_PENDING_ORDERS ",JSON.stringify({"status":"PASS" if errors.is_empty() else "FAIL", "checks":checks,"issues":errors}))
 quit(0 if errors.is_empty() else 1)
