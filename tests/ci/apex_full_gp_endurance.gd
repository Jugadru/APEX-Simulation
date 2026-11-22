extends SceneTree
## Endurance-only fixture: complete 2012 GP with RaceEngine's tested 4s stepping.
## This is deliberately NOT a 0.2s-per-tick replay; that is checked separately.
const Race = preload("res://scripts/race_engine.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")

const STEP_SECONDS := 4.0
const MAX_STEPS := 5000

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var code: String = OS.get_environment("APEX_TRACK")
	var weather: String = OS.get_environment("APEX_WEATHER")
	var seed: int = int(OS.get_environment("APEX_SEED"))
	if code.is_empty(): code = "ITA"
	if weather.is_empty(): weather = "Seco"
	if seed < 1: seed = 660
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not (source is Dictionary):
		printerr("APEX_FULL_GP_ERROR missing season 2012 JSON")
		quit(1)
		return

	var track: Dictionary = {}
	for candidate in source["tracks"]:
		if str(candidate.get("code", "")) == code:
			track = candidate.duplicate(true)
			break
	if track.is_empty():
		printerr("APEX_FULL_GP_ERROR unknown track ", code)
		quit(1)
		return

	var race = Race.new(source["teams"], "Ferrari", seed, {}, track, {})
	race.configure_weather(weather)
	if race.cars.size() != 24 or race.lap_count != int(track.get("laps", 0)):
		printerr("APEX_FULL_GP_ERROR invalid grid or lap count")
		quit(1)
		return

	race.running = true
	# Read-only weather observations for Quality 9.9 full-distance diagnostics.
	var initial_wetness: float = float(race.weather_snapshot().get("wetness_factor", 0.0))
	var min_wetness: float = initial_wetness
	var max_wetness: float = initial_wetness
	var start_usec: int = Time.get_ticks_usec()
	var steps: int = 0
	var player_pit_orders: int = 0
	var ordered: bool = false
	var observations: Array = []
	for _n in range(MAX_STEPS):
		if race.finished:
			break
		# Deterministic manual orders in the middle of a real full-distance GP.
		if not ordered and race.lap >= 20:
			var compound: String = "Chuva" if weather == "Chuva intensa" else "Duro"
			for player in race.player_cars():
				race.order_pit(int(player.id), compound)
				if bool(player.get("pit_request", false)) and str(player.get("pit_target", "")) == compound:
					player_pit_orders += 1
			ordered = true
		race.step(STEP_SECONDS)
		var wetness: float = float(race.weather_snapshot().get("wetness_factor", 0.0))
		min_wetness = minf(min_wetness, wetness)
		max_wetness = maxf(max_wetness, wetness)
		steps += 1
		if steps % 100 == 0:
			observations.append({
				"step": steps, "clock": race.clock, "leader_lap": race.lap,
				"memory_static_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
				"events": race.events.size(),
				"telemetry_events": race.telemetry.event_history.size()
			})

	var finished_cars: int = 0
	for car in race.cars:
		if bool(car.finished): finished_cars += 1
	var elapsed: float = float(Time.get_ticks_usec() - start_usec) / 1000000.0
	var hash: String = Codec.sporting_hash(race, {})
	var final: Dictionary = {
		"track": code, "mode": weather, "seed": seed,
		"full_distance": true, "laps": race.lap_count,
		"finished": race.finished, "finished_cars": finished_cars,
		"ticks": steps, "clock": race.clock, "time_seconds": elapsed,
		"step_sim_seconds": STEP_SECONDS, "last_hash": hash,
		"min_wetness": snappedf(min_wetness, 0.000001),
		"max_wetness": snappedf(max_wetness, 0.000001),
		"checkpoints": 0, "events": race.events.size(),
		"pit_history": race.get_pit_history().size(),
		"manual_pit_orders": player_pit_orders,
		"samples": observations
	}
	var target_path: String = OS.get_environment("APEX_BENCH_OUTPUT")
	if target_path.is_empty():
		printerr("APEX_FULL_GP_ERROR APEX_BENCH_OUTPUT is required")
		quit(1)
		return
	var output: FileAccess = FileAccess.open(target_path, FileAccess.WRITE)
	if output == null:
		printerr("APEX_FULL_GP_ERROR cannot write JSON: ", target_path)
		quit(1)
		return
	output.store_string(JSON.stringify(final, "  "))
	output.close()
	print("APEX_FULL_GP_DONE ", JSON.stringify({
		"track": code, "weather": weather, "seed": seed,
		"ticks": steps, "laps": race.lap,
		"finished": race.finished, "finished_cars": finished_cars,
		"manual_pit_orders": player_pit_orders, "hash": hash
	}))
	var valid: bool = race.finished and finished_cars == 24 and player_pit_orders == 2
	quit(0 if valid else 1)
