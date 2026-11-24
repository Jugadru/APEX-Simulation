extends SceneTree
## v0.6.6.9.8 — imperfect wet forecast, safety and sporting replay revisions.
const Wet = preload("res://scripts/core/race_wet_strategy_intelligence_06698.gd")
const Weather = preload("res://scripts/core/race_weather.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")

var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		printerr("WET_STRATEGY_06698_FAIL " + description)

func _run() -> void:
	# This historical regression must remain valid on later Core 2 builds:
	# verify a coherent build name/description without freezing version labels.
	var app_name: String = str(ProjectSettings.get_setting("application/config/name", ""))
	var app_description: String = str(ProjectSettings.get_setting("application/config/description", ""))
	var prefix: String = "APEX Motorsport Manager v0.6.6.9."
	var suffix: String = " — Core 2"
	var minor: String = ""
	if app_name.begins_with(prefix) and app_name.ends_with(suffix):
		minor = app_name.trim_prefix(prefix).trim_suffix(suffix)
	# Keep the 9.8 minimum while accepting patch identities like 9.17.2.
	var version_parts: PackedStringArray = minor.split(".")
	var valid_name: bool = version_parts.size() >= 1 and version_parts.size() <= 2
	for part in version_parts:
		valid_name = valid_name and part.is_valid_int()
	if valid_name:
		valid_name = int(version_parts[0]) >= 8
	check(valid_name, "supported Core 2 v9.8+ naming convention")
	var identity_version: String = "v0.6.6.9." + minor if valid_name else ""
	check(valid_name and app_description.begins_with(identity_version + ":"),
		"project description must match the Core 2 build identity")
	var sample: Dictionary = {
		"water_mm":1.12, "off_line_water_mm":1.40,
		"surface_moisture":0.43, "rain_intensity":0.21,
		"air_c":22.0, "wind":7.0, "climate_risk":42, "mode":"Variável",
		"wetness_factor":0.23}
	var unchanged: PackedByteArray = var_to_bytes(sample)
	var predicted: Dictionary = Wet.forecast(sample, 420.0, "GBR", 2)
	var repeated: Dictionary = Wet.forecast(sample, 420.0, "GBR", 2)
	check(predicted == repeated, "same observations give identical forecasts")
	check(unchanged == var_to_bytes(sample), "forecast cannot mutate weather observations")
	check(str(predicted["forecast_source"]) == "observacoes_atual"
		and float(predicted["wetness_min"]) <= float(predicted["wetness_factor"])
		and float(predicted["wetness_factor"]) <= float(predicted["wetness_max"]),
		"uncertainty band accompanies central nowcast")
	var high_skill: Dictionary = Wet.forecast(sample, 420.0, "GBR", 3)
	var low_skill: Dictionary = Wet.forecast(sample, 420.0, "GBR", 0)
	check(is_equal_approx(float(high_skill["wetness_factor"]), float(low_skill["wetness_factor"]))
		and float(high_skill["uncertainty"]) < float(low_skill["uncertainty"]),
		"strategist skill narrows uncertainty but cannot reveal future weather")
	var heavy: Dictionary = sample.duplicate(true)
	heavy["rain_intensity"] = 0.9
	var no_rain: Dictionary = sample.duplicate(true)
	no_rain["rain_intensity"] = 0.0
	check(float(Wet.forecast(heavy, 300.0, "GBR")["wetness_factor"]) >
		float(Wet.forecast(no_rain, 300.0, "GBR")["wetness_factor"]),
		"present rain can increase future water without future event access")
	check(float(Wet.forecast(sample, 300.0, "BEL")["wetness_factor"]) <
		float(Wet.forecast(sample, 300.0, "MAL")["wetness_factor"]),
		"observed water responds to track drainage")
	var car: Dictionary = {"tire":"Médio", "wear":25.0}
	var plan: Dictionary = {"pit_now":true, "compound":"Intermediário",
		"critical":false, "life_laps":6.0, "status":"BOX RECOMENDADO AGORA"}
	var uncertain: Dictionary = {"wetness_min":0.12, "wetness_max":0.25,
		"confidence":"MODERADA"}
	var observed: Dictionary = {"wetness_factor":0.16}
	var original_plan: PackedByteArray = var_to_bytes(plan)
	var reviewed: Dictionary = Wet.review_plan(car, plan, observed, uncertain, uncertain)
	check(not bool(reviewed["pit_now"]) and bool(reviewed["deferred"])
		and bool(reviewed["wet_strategy"].get("deferred_crossover", false)),
		"marginal wet transition deferred when uncertainty crosses threshold")
	check(original_plan == var_to_bytes(plan), "review never mutates original AI proposal")
	var urgent: Dictionary = plan.duplicate(true)
	urgent["critical"] = true
	check(bool(Wet.review_plan(car, urgent, observed, uncertain, uncertain)["pit_now"]),
		"critical tyre state cannot be blocked")
	var unsafe: Dictionary = {"wetness_factor":0.58}
	check(bool(Wet.review_plan(car, plan, unsafe, uncertain, uncertain)["pit_now"]),
		"dangerously wet slicks do not wait for forecast confidence")
	var clear: Dictionary = {"wetness_min":0.19, "wetness_max":0.35}
	check(bool(Wet.review_plan(car, plan, observed, clear, clear)["pit_now"]),
		"clear crossover evidence permits existing AI decision")
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = season["tracks"][0]
	var wx_a = Weather.new()
	var wx_b = Weather.new()
	wx_a.setup(track, 551, "Variável")
	wx_b.setup(track, 551, "Variável")
	var same_snapshot: Dictionary = wx_a.snapshot()
	wx_b.rain_events.clear()
	wx_b.rain_events.append({"start":240.0, "duration":900.0, "power":0.95})
	check(Wet.forecast(same_snapshot, 540.0, str(track["code"])) ==
		Wet.forecast(wx_b.snapshot(), 540.0, str(track["code"])),
		"future hidden rain schedule cannot change identical observed forecast")
	var latest = Race.new(season["teams"], "Ferrari", 201298, {}, track, {})
	var prior = Race.new(season["teams"], "Ferrari", 201298, {}, track, {})
	prior.wet_strategy_intelligence_enabled = false
	check(not Codec.capture(latest)["engine"].has("wet_strategy_intelligence_enabled")
		and Codec.restore(Codec.capture(latest)) != null,
		"session revision excluded from the unchanged save schema")
	var a_id: int = int(latest.player_cars()[0]["id"])
	var tire: String = str(latest.available_pit_compounds()[0])
	latest.configure_weather("Chuva intensa")
	check(latest.schedule_pit(a_id, tire, 21), "rainy player manual V21 is accepted")
	latest.player_cars()[0]["progress"] = 3.94
	latest.running = true
	for tick in range(36):
		latest.step(0.2)
	check(int(latest.player_cars()[0]["pit_scheduled_lap"]) == 21
		and not bool(latest.player_cars()[0]["pit_request"])
		and int(latest.player_cars()[0]["stops"]) == 0,
		"manual V21 never becomes V4 even during heavy rain")
	check(bool(latest._build_strategy_plan(latest.player_cars()[0]).has("wet_strategy"))
		and not bool(prior._build_strategy_plan(prior.player_cars()[0]).has("wet_strategy")),
		"020 observation-only strategy is opt-in per sporting revision")
	var alpha = Race.new(season["teams"], "Ferrari", 2098, {}, track, {})
	var beta = Race.new(season["teams"], "Ferrari", 2098, {}, track, {})
	alpha.configure_weather("Variável")
	beta.configure_weather("Variável")
	alpha.running = true
	beta.running = true
	for tick in range(450):
		alpha.step(0.2)
		beta.step(0.2)
		if tick % 31 == 0:
			alpha.get_engineer_advice(int(alpha.player_cars()[0]["id"]))
	check(Codec.sporting_hash(alpha, {}) == Codec.sporting_hash(beta, {}),
		"read-only forecast and HUD observations do not affect sporting hash")
	var recorded = Replay.new()
	var old_race = Race.new(season["teams"], "Ferrari", 9981, {}, track, {})
	recorded.attach(old_race)
	recorded.recorded_simulation_revision = Replay.PRE_WET_SIMULATION_REVISION
	recorded.legacy_wet_strategy = true
	recorded.legacy_start_intelligence = true
	recorded.race.wet_strategy_intelligence_enabled = false
	recorded.race.race_start_intelligence_enabled = false
	for tick in range(30):
		check(recorded.step_tick(), "019 archive tick")
	var old_archive: Dictionary = recorded.export_data()
	var historical = Replay.new()
	check(historical.load_data(old_archive)
		and bool(historical.legacy_wet_strategy)
		and not bool(historical.race.wet_strategy_intelligence_enabled),
		"019 historical archive keeps previous seeded forecast algorithm")
	check(historical.seek(30) and historical.first_divergence < 0,
		"019 historical replay remains hash compatible")
	var new_recorded = Replay.new()
	new_recorded.attach(Race.new(season["teams"], "Ferrari", 9981, {}, track, {}))
	for tick in range(30):
		check(new_recorded.step_tick(), "020 archive tick")
	var new_archive: Dictionary = new_recorded.export_data()
	var new_playback = Replay.new()
	check(str(new_archive["simulation_revision"]) == Replay.SIMULATION_REVISION
		and new_playback.load_data(new_archive)
		and bool(new_playback.race.wet_strategy_intelligence_enabled),
		"new 020 replay records strategy revision")
	check(new_playback.seek(30) and new_playback.first_divergence < 0,
		"020 replay reconstructs all sporting ticks")
	if failures.is_empty():
		print("WET_STRATEGY_06698_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)
