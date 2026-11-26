extends SceneTree
## APEX v9.15: bounded HUD-only track-catalog cache, live evidence and sport parity.
const Knowledge = preload("res://scripts/core/race_setup_track_knowledge_066914.gd")
const TrackDynamics = preload("res://scripts/core/race_track_dynamics.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("PERFORMANCE_POLISH_066915_FAIL " + label)

func _run() -> void:
	var input: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not input is Dictionary:
		check(false, "official season data available")
		_finish()
		return
	var season: Dictionary = input
	var tracks: Array = season.get("tracks", [])
	check(tracks.size() == 20, "complete 20-circuit season")
	var original_stats: Dictionary = Knowledge.cache_stats()
	check(int(original_stats.get("catalog_loads", -1)) == 0,
		"fresh test process starts without preloaded UI catalog")

	# Exact source parity with legacy profile_for() for every known circuit.
	# No changes are made to RaceTrackDynamics, AI, physics or saved catalogue.
	var codes: Array[String] = []
	for t in tracks:
		var code: String = str(t.get("code", ""))
		codes.append(code)
		var original: Dictionary = TrackDynamics.profile_for(code)
		var accelerated: Dictionary = Knowledge._profile_cached(code)
		check(not original.is_empty() and original == accelerated,
			"cached factors match existing TrackDynamics for " + code)
	check(Knowledge.cache_stats().get("catalog_loads") == 1
		and Knowledge.cache_stats().get("profiles") == 20,
		"20 circuit queries require one catalog load, bounded to 20 profiles")

	var gbr: Dictionary = {}
	var ita: Dictionary = {}
	for t in tracks:
		if t.get("code") == "GBR":
			gbr = t
		elif t.get("code") == "ITA":
			ita = t
	check(not gbr.is_empty() and not ita.is_empty(), "GBR and ITA in real calendar")
	var dry: Dictionary = {"wetness_factor":0.02, "track_c":29.0}
	var storm: Dictionary = {"wetness_factor":0.83, "track_c":18.0}
	var booked: Dictionary = {"id":1, "wear":40.0, "tire":"Médio",
		"pit_scheduled_lap":21, "pit_request":false}
	var before: PackedByteArray = var_to_bytes([ita, dry, storm, booked])
	var calm: Dictionary = Knowledge.assess(ita,dry,booked,{"Engenheiro":3})
	var wet: Dictionary = Knowledge.assess(ita,storm,booked,{"Engenheiro":3})
	check(calm.get("setup_aero") == "BAIXA CARGA" and
		wet.get("setup_aero") == calm.get("setup_aero"),
		"baseline setup still uses same authoritative track profile")
	check(str(wet.get("wet_note","")).contains("83") and
		not str(calm.get("wet_note","")).contains("83"),
		"weather changes remain live after a cached circuit lookup")
	check(str(wet.get("car_note","")).contains("BOX V21") and
		not bool(wet.get("can_apply",true)),
		"scheduled V21 is always protected")
	var wear_changed: Dictionary = booked.duplicate(true)
	wear_changed["wear"] = 96.0
	var high_wear: Dictionary = Knowledge.assess(ita,storm,wear_changed)
	check(str(high_wear.get("car_note","")).contains("96%") and
		str(wet.get("car_note","")).contains("40%"),
		"driver wear never cached across calls or cars")
	check(wet.get("track_factors", {}) == TrackDynamics.profile_for("ITA"),
		"returned factors identical to uncached profile")
	var exposed_factors: Dictionary = wet["track_factors"]
	exposed_factors["abrasion"] = 9999.0
	check(float(Knowledge.assess(ita,storm).track_factors.abrasion) < 2.0,
		"mutating a result never corrupts the cached catalog")
	check(Knowledge._profile_cached("NOT_2012").is_empty() and
		Knowledge._profile_cached("").is_empty(),
		"missing circuits fail closed with no fabricated values")
	check(Knowledge.cache_stats().get("profiles") == 20,
		"invalid lookup does not grow cache")
	check(before == var_to_bytes([ita, dry, storm, booked]),
		"advice never mutates inputs")

	# Observed diagnostic: uncached JSON parse vs cached profile fetch for the
	# SAME queries. Do not gate machine-dependent timing or claim GPU/FPS gain.
	var repetitions: int = 600
	var start_uncached: int = Time.get_ticks_usec()
	for i in range(repetitions):
		TrackDynamics.profile_for(codes[i % codes.size()])
	var uncached_us: int = Time.get_ticks_usec() - start_uncached
	var start_cached: int = Time.get_ticks_usec()
	for i in range(repetitions):
		Knowledge._profile_cached(codes[i % codes.size()])
	var cached_us: int = Time.get_ticks_usec() - start_cached
	check(uncached_us > 0 and cached_us > 0, "benchmark measured both code paths")
	check(Knowledge.cache_stats().get("catalog_loads") == 1,
		"600 additional HUD-equivalent queries still consume zero catalog parses")
	print("PERFORMANCE_POLISH_066915_BENCH ", JSON.stringify({
		"iterations":repetitions,"uncached_us":uncached_us,
		"cached_us":cached_us,"ratio_observed":float(uncached_us) / maxf(1.0,float(cached_us)),
		"note":"Headless local CPU microbenchmark only; no guarantee of measured FPS improvement."}))

	var race = Race.new(season.teams,"Ferrari",6615,{},gbr,{})
	check(race.cars.size() == 24, "real grid of 24 drivers")
	var car: Dictionary = race.player_cars()[0]
	var car_id: int = int(car.get("id",-1))
	check(race.schedule_pit(car_id,str(race.available_pit_compounds()[1]),21),
		"real engine accepts manual V21")
	race.configure_weather("Chuva intensa")
	var snapshot_before: PackedByteArray = var_to_bytes(race.get_state_snapshot())
	var rng_before: int = race.rng.state
	for i in range(48):
		Knowledge.assess(race.track, race.weather_snapshot(),car,
			{"Engenheiro":i % 4})
	check(rng_before == race.rng.state
		and snapshot_before == var_to_bytes(race.get_state_snapshot()),
		"repeated advisor reads preserve live racing snapshot and RNG")
	check(int(car.get("pit_scheduled_lap",0)) == 21,
		"real engine's manual V21 protected across repeated advice")
	check(Knowledge.cache_stats().get("catalog_loads") == 1,
		"two different circuits share exactly one catalog load")
	check(Replay.SIMULATION_REVISION in ["023_overtaking_intelligence_v1", "024_race_start_spatial_v1", "025_competitive_grid_start_v1", "026_competitive_traffic_v1", "027_race_traffic_hotfix_v1", "028_racing_line_v1", "029_racing_line_following_v1", "030_racing_line_completion_v1", "031_independent_racecraft_v1", "032_aero_wake_v1", "033_aero_wake_source_v2", "034_aero_traffic_stability_v1", "035_aero_wet_line_v1", "036_tactical_coordination_v1", "037_corner_battle_v1", "038_driver_traffic_v2", "039_traffic_pack_v1", "040_driver_error_recovery_v1", "041_longitudinal_physics_v1"]
		and Replay.PRE_START20_SIMULATION_REVISION == "023_overtaking_intelligence_v1",
		"9.15 performance-only logic preserves 023 after 9.17 revision")

	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._start_race()
	await process_frame
	var hud = game.race_hud_0620
	hud._open_window("engineer")
	await process_frame
	hud._update_engineer_reports()
	check(hud.engineer_cards.size() == 2, "two native engineer HUD cards")
	var initial_loads: int = int(Knowledge.cache_stats().catalog_loads)
	for frame in range(30):
		hud._update_engineer_reports()
	check(int(Knowledge.cache_stats().catalog_loads) == initial_loads,
		"30 real HUD updates do not reread the 2012 JSON")
	for card in hud.engineer_cards:
		check(card.has("ask_track")
			and str(card.evidence.text).contains("SETUP 9.14"),
			"setup question and track assessment remain in existing HUD")
	var ui_car: Dictionary = game.race.player_cars()[0]
	var ui_id: int = int(ui_car["id"])
	var ui_rng: int = game.race.rng.state
	var ui_pit: int = int(ui_car.get("pit_scheduled_lap",0))
	hud._engineer_ask(ui_id, "setup")
	check(str(hud.engineer_radio_answers.get(ui_id,"")).contains("SETUP/PISTA 9.14"),
		"original setup question text and behavior unchanged")
	check(game.race.rng.state == ui_rng and
		int(ui_car.get("pit_scheduled_lap",0)) == ui_pit,
		"UI cannot cause sporting commands through profile cache")
	game.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("PERFORMANCE_POLISH_066915_PASS checks=%d catalog_loads=%d" % [
			checks,int(Knowledge.cache_stats().catalog_loads)])
	else:
		for error in failures:
			printerr("FAIL " + error)
	quit(0 if failures.is_empty() else 1)
