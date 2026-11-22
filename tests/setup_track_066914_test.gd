extends SceneTree
## v9.14 — real 20-circuit catalog, setup recommendations, immutable race state/HUD.
const Knowledge = preload("res://scripts/core/race_setup_track_knowledge_066914.gd")
const TrackDynamics = preload("res://scripts/core/race_track_dynamics.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
var count: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	count += 1
	if not value:
		failures.append(label)
		printerr("SETUP_TRACK_066914_FAIL " + label)

func _find(tracks: Array, code: String) -> Dictionary:
	for track in tracks:
		if str(track.get("code", "")) == code:
			return track
	return {}

func _run() -> void:
	var season_v: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not season_v is Dictionary:
		check(false, "real 2012 season catalog exists")
		_finish()
		return
	var season: Dictionary = season_v
	var tracks: Array = season.get("tracks", [])
	check(tracks.size() == 20, "20 official 2012 season rounds loaded in game")
	var profiles: Dictionary = TrackDynamics.catalog().get("tracks", {})
	check(profiles.size() == 20, "20 existing physics profiles available")
	for track in tracks:
		var code: String = str(track.get("code", ""))
		var profile: Dictionary = Knowledge.assess(track, {"wetness_factor":0.0})
		check(bool(profile.get("available", false)) and profile.get("track_code") == code,
			"one traceable profile for " + code)
		check(not bool(profile.get("can_apply", true)) and bool(profile.get("read_only", false)),
			"all circuit setup insights are consultation-only " + code)
	var gbr: Dictionary = _find(tracks,"GBR")
	var ita: Dictionary = _find(tracks,"ITA")
	var mon: Dictionary = _find(tracks,"MON")
	var bhr: Dictionary = _find(tracks,"BHR")
	var can: Dictionary = _find(tracks,"CAN")
	var gb_report: Dictionary = Knowledge.assess(gbr, {"wetness_factor":0.03})
	var it_report: Dictionary = Knowledge.assess(ita, {"wetness_factor":0.03})
	var mo_report: Dictionary = Knowledge.assess(mon, {"wetness_factor":0.03})
	check(gb_report.get("setup_aero") == "ALTA CARGA",
		"Silverstone lateral load supports qualitative high-downforce assessment")
	check(it_report.get("setup_aero") == "BAIXA CARGA",
		"Monza low lateral load supports lower-downforce assessment")
	check(mo_report.get("setup_aero") == "ALTA CARGA"
		and mo_report.get("setup_mechanical") == "FOCO EM TRAÇÃO",
		"Monaco traction is differentiated from Monza")
	check(Knowledge.assess(bhr, {}).get("tyre_priority") == "POUPAR PNEUS",
		"Bahrain high abrasion raises tyre-conservation recommendation")
	check(Knowledge.assess(can, {}).get("setup_aero") == "BAIXA CARGA",
		"Canada low lateral demand uses measured profile without invented setup")
	var empty: Dictionary = Knowledge.assess({"code":"MISSING"}, {})
	check(not bool(empty.get("available", true)) and not bool(empty.get("can_apply", true)),
		"unknown circuit fails closed, no invented catalog factors")
	var storm: Dictionary = {"wetness_factor":0.83, "track_c":24.0}
	var wet_mon: Dictionary = Knowledge.assess(mon,storm)
	check(str(wet_mon.get("wet_note", "")).contains("Drenagem")
		and str(wet_mon.get("wet_note", "")).contains("83"),
		"wet low-drainage circuit triggers observed weather caution")
	var before: PackedByteArray = var_to_bytes([mon,storm])
	var check_again: Dictionary = Knowledge.assess(mon,storm)
	check(check_again == wet_mon and before == var_to_bytes([mon,storm]),
		"static circuit advice deterministic, input dictionaries unchanged")
	var car: Dictionary = {"id":1, "tire":"Médio", "wear":59.0,
		"pit_scheduled_lap":21, "pit_request":false}
	var car_copy: PackedByteArray = var_to_bytes(car)
	var staff_low: Dictionary = Knowledge.assess(mon,storm,car,{"Engenheiro":0})
	var staff_high: Dictionary = Knowledge.assess(mon,storm,car,{"Engenheiro":3})
	check(str(staff_high.get("briefing","")).contains("BOX V21")
		and not bool(staff_high.get("can_apply",true)),
		"existing V21 remains informational in 83 percent rain")
	check(staff_low.get("setup_aero") == staff_high.get("setup_aero")
		and staff_low.get("setup_mechanical") == staff_high.get("setup_mechanical"),
		"staff level cannot change recommended core profile or race outcomes")
	check(str(staff_high.get("dimensions","")).contains("Grip-base")
		and not str(staff_low.get("dimensions","")).contains("Grip-base"),
		"higher engineer level increases explanation depth only")
	check(car_copy == var_to_bytes(car), "car state never modified")

	var race = Race.new(season.teams,"Ferrari",6614,{},ita,{})
	var native_car: Dictionary = race.player_cars()[0]
	var id: int = int(native_car.get("id",-1))
	check(race.cars.size() == 24, "actual 24-car grid supports track knowledge")
	check(race.schedule_pit(id,str(race.available_pit_compounds()[1]),21),
		"manual V21 accepted in native engine")
	race.configure_weather("Chuva intensa")
	var rng_before: int = race.rng.state
	var sport_before: PackedByteArray = var_to_bytes(race.get_state_snapshot())
	var native: Dictionary = Knowledge.assess(race.track,
		race.weather_snapshot(), native_car, {"Engenheiro":3})
	check(native.get("track_code") == "ITA"
		and str(native.get("briefing","")).contains("BOX V21"),
		"real Monza conditions and scheduled stop appear in advice")
	check(race.rng.state == rng_before
		and sport_before == var_to_bytes(race.get_state_snapshot())
		and int(native_car.get("pit_scheduled_lap",0)) == 21,
		"pure advisory does not consume RNG or affect sporting state")
	check(Replay.SIMULATION_REVISION == "023_overtaking_intelligence_v1",
		"no sporting revision change from 9.13")

	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._start_race()
	await process_frame
	var hud = game.race_hud_0620
	hud._open_window("engineer")
	await process_frame
	hud._update_engineer_reports()
	check(hud.engineer_cards.size() == 2, "HUD still shows both player drivers")
	for card in hud.engineer_cards:
		check(card.has("ask_track")
			and str(card["evidence"].text).contains("SETUP 9.14"),
			"read-only setup observation visible with button in native HUD")
	var gui_car: Dictionary = game.race.player_cars()[0]
	var gui_id: int = int(gui_car.get("id",-1))
	var gui_rng: int = game.race.rng.state
	var gui_before: int = int(gui_car.get("pit_scheduled_lap",0))
	var gui_request: bool = bool(gui_car.get("pit_request",false))
	hud._engineer_ask(gui_id,"setup")
	check(str(hud.engineer_radio_answers.get(gui_id,"")).contains("SETUP/PISTA 9.14"),
		"setup request reads observed circuit and returns non-executable advice")
	check(game.race.rng.state == gui_rng
		and int(gui_car.get("pit_scheduled_lap",0)) == gui_before
		and bool(gui_car.get("pit_request",false)) == gui_request,
		"UI setup question causes no hidden pit commands or RNG consumption")
	game.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("SETUP_TRACK_066914_PASS checks=%d read_only=true circuits=20" % count)
	else:
		for item in failures:
			printerr("FAIL " + item)
	quit(0 if failures.is_empty() else 1)
