extends SceneTree
## APEX v0.6.6.9.17 — pure spatial model + real Core 2/replay regressions.
const Start20 = preload("res://scripts/core/race_start_spatial_066917.gd")
const StartV1 = preload("res://scripts/core/race_start_intelligence_066911.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")

var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("RACE_START_066917_FAIL " + message)

func _track(season: Dictionary, code: String) -> Dictionary:
	for track in season.get("tracks", []):
		if str(track.get("code", "")) == code:
			return track
	return {}

func _run() -> void:
	var follower: Dictionary = {"id":11, "progress":0.014,
		"race_lane":0.0, "skill":86, "car_rating":83,
		"spatial_awareness":80.0, "risk_tolerance":55.0,
		"tyre_surface_c":84.0, "tire":"Médio",
		"driver_soul":{"confidence":0.68}}
	var leader: Dictionary = follower.duplicate(true)
	leader["id"] = 10
	leader["progress"] = 0.0205
	var grid: Array = [leader, follower]
	var dry: Dictionary = {"wetness_factor":0.0, "grip_factor":1.0}
	var wet: Dictionary = {"wetness_factor":0.82, "grip_factor":0.78}
	var original: PackedByteArray = var_to_bytes([grid, dry, wet])

	var wide: float = Start20.congestion_cost(follower, 1.0, dry, grid, 1000.0, 1.0)
	var narrow: float = Start20.congestion_cost(follower, 1.0, dry, grid, 1000.0, 0.0)
	var wet_congestion: float = Start20.congestion_cost(follower, 1.0, wet, grid, 1000.0, 0.0)
	check(wide > 0.0 and narrow > wide and wet_congestion > narrow,
		"real headway, narrow sector and rain produce increasing bounded cost")
	check(Start20.headway_units(follower, grid, 1000.0) > 6.0
		and Start20.headway_units(follower, grid, 1000.0) < 7.0,
		"headway uses frozen progress in schematic track units")
	var safe: Dictionary = leader.duplicate(true)
	safe["race_lane"] = 3.10
	check(Start20.congestion_cost(follower, 1.0, wet,
		[safe, follower], 1000.0, 0.0) == 0.0,
		"side-by-side cars occupying separate corridors do not create fake traffic")
	safe["race_lane"] = 0.0
	safe["progress"] = 0.10
	check(Start20.congestion_cost(follower, 1.0, dry,
		[safe, follower], 1000.0, 0.0) == 0.0,
		"faraway leader does not penalize a clear start")
	var careful: Dictionary = follower.duplicate(true)
	careful["spatial_awareness"] = 98.0
	var unaware: Dictionary = follower.duplicate(true)
	unaware["spatial_awareness"] = 50.0
	check(Start20.congestion_cost(careful, 1.0, wet, grid, 1000.0, 0.0)
		< Start20.congestion_cost(unaware, 1.0, wet, grid, 1000.0, 0.0),
		"awareness mitigates congestion without granting free speed")
	var risk: Dictionary = follower.duplicate(true)
	risk["risk_tolerance"] = 95.0
	check(Start20.congestion_cost(risk, 1.0, wet, grid, 1000.0, 0.0) > wet_congestion,
		"aggressive wet approach has a traction/safety tradeoff")
	check(Start20.congestion_cost(follower, -0.1, dry, grid, 1000.0, 0.0) == 0.0
		and Start20.congestion_cost(follower, 18.0, dry, grid, 1000.0, 0.0) == 0.0,
		"congestion never extends outside the initial 18s")
	var escaped: Dictionary = follower.duplicate(true)
	escaped["progress"] = 0.14
	check(Start20.congestion_cost(escaped, 3.0, dry, grid, 1000.0, 0.0) == 0.0,
		"cost ends immediately after the first-sector exit")
	check(Start20.pace_cost(follower, 0.2, dry, 1.0, [], 1000.0) ==
		StartV1.pace_cost(follower, 0.2, dry, 1.0),
		"v9.17 adds no penalty when the start corridor is clear")
	check(Start20.pace_cost(follower, 9.0, dry, 0.0, grid, 1000.0) > 0.0
		and StartV1.pace_cost(follower, 9.0, dry, 0.0) == 0.0,
		"9.17 models first-corner traffic beyond legacy eight-second traction")
	check(Start20.pace_cost(follower, 18.0, wet, 0.0, grid, 1000.0) == 0.0,
		"neither launch nor corner model changes the following race")
	check(var_to_bytes([grid, dry, wet]) == original
		and Start20.congestion_cost(follower, 1.0, wet, grid, 1000.0, 0.0) == wet_congestion,
		"pure model has no RNG and never mutates its inputs")

	var season_data: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not season_data is Dictionary:
		check(false, "2012 season JSON is readable")
		_finish()
		return
	var season: Dictionary = season_data
	var gbr: Dictionary = _track(season, "GBR")
	var mon: Dictionary = _track(season, "MON")
	if gbr.is_empty() or mon.is_empty():
		check(false, "Silverstone/Monaco available")
		_finish()
		return
	var first = Race.new(season["teams"], "Ferrari", 6617, {}, gbr, {})
	var second = Race.new(season["teams"], "Ferrari", 6617, {}, gbr, {})
	check(first.cars.size() == 24 and second.cars.size() == 24,
		"24-car 2012 grid is unchanged")
	check(not Codec.capture(first)["engine"].has("race_start20_enabled")
		and Codec.restore(Codec.capture(first)) != null,
		"start rule is session-only, excluded from save and sporting hash")
	var a = Replay.new()
	a.attach(first)
	var b = Replay.new()
	b.attach(second)
	check(a.recorded_simulation_revision == Replay.SIMULATION_REVISION
		and Replay.SIMULATION_REVISION == "025_competitive_grid_start_v1"
		and Replay.PRE_COMPETITIVE_START_SIMULATION_REVISION == "024_race_start_spatial_v1"
		and first.race_start20_enabled,
		"new recordings activate first-corner model and revision 024")
	var all_ticks_ok: bool = true
	for tick in range(90):
		if not a.step_tick() or not b.step_tick():
			all_ticks_ok = false
			break
	check(all_ticks_ok, "024 race advances 90 deterministic ticks")
	check(Codec.sporting_hash(first, a.policy) == Codec.sporting_hash(second, b.policy),
		"identical 24-car grids preserve deterministic sporting hash")
	var view = Replay.new()
	check(view.load_data(a.export_data()) and view.seek(a.end_tick)
		and view.first_divergence < 0,
		"024 replay import/seek maintains per-tick sporting hashes")

	# Archived 023 simulations retain the 9.11 launch and 9.12 overtaking
	# without accepting a new 9.17 congestion cost.
	var old = Replay.new()
	old.attach(Race.new(season["teams"], "Ferrari", 6617, {}, gbr, {}))
	old.recorded_simulation_revision = Replay.PRE_START20_SIMULATION_REVISION
	old.legacy_start20 = true
	old.race.race_start20_enabled = false
	old.checkpoints = [old.checkpoint()]
	for tick in range(90):
		if not old.step_tick():
			check(false, "023 historical race advances")
			break
	var older = Replay.new()
	check(older.load_data(old.export_data())
		and older.legacy_start20
		and not older.legacy_overtaking_intelligence
		and not older.legacy_start_intelligence
		and not older.race.race_start20_enabled
		and older.race.overtaking_intelligence_enabled
		and older.seek(old.end_tick) and older.first_divergence < 0,
		"023 recordings replay with the unchanged 9.11/9.12 sporting model")
	var fork = Replay.new()
	check(fork.load_live_session(old) and fork.legacy_start20
		and fork.seek(old.end_tick) and fork.first_divergence < 0,
		"live replay fork keeps historical start-revision policy")

	var rainy = Race.new(season["teams"], "Ferrari", 6618, {}, mon, {})
	rainy.configure_weather("Chuva intensa")
	var player: Dictionary = rainy.player_cars()[0]
	check(rainy.schedule_pit(int(player.id),
		str(rainy.available_pit_compounds()[1]), 21),
		"manual BOX V21 is valid in a rainy 9.17 race")
	rainy.running = true
	for tick in range(45):
		rainy.step(0.2)
	check(int(player.get("pit_scheduled_lap", 0)) == 21
		and not bool(player.get("pit_request", false))
		and int(player.get("stops", 0)) == 0,
		"rain cannot force scheduled V21 to execute on V4")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("RACE_START_066917_PASS checks=%d" % checks)
	else:
		for message in failures:
			printerr("FAIL: " + message)
	quit(0 if failures.is_empty() else 1)
