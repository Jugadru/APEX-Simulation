extends SceneTree
## Race Start Intelligence 1.0: physics, 24-car grid, replay 021/022 and V21.
const Start = preload("res://scripts/core/race_start_intelligence_066911.gd")
const Legacy = preload("res://scripts/core/race_launch_14.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")

var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures.append(reason)
		printerr("RACE_START_066911_FAIL " + reason)

func _track(season: Dictionary, code: String) -> Dictionary:
	for item in season["tracks"]:
		if str(item.get("code", "")) == code:
			return item
	return {}

func _run() -> void:
	var good: Dictionary = {
		"skill":96,"spatial_awareness":96,"risk_tolerance":50,
		"car_rating":90,"tire":"Médio","tyre_surface_c":89.0,
		"driver_soul":{"confidence":0.85}}
	var poor: Dictionary = {
		"skill":61,"spatial_awareness":62,"risk_tolerance":50,
		"car_rating":68,"tire":"Médio","tyre_surface_c":70.0,
		"driver_soul":{"confidence":0.30}}
	var aggressive: Dictionary = good.duplicate(true)
	aggressive["risk_tolerance"] = 95
	var good_bytes: PackedByteArray = var_to_bytes(good)
	var dry: Dictionary = {"wetness_factor":0.0,"grip_factor":1.0}
	var rain: Dictionary = {"wetness_factor":0.83,"grip_factor":0.74}
	var good_dry: float = Start.pace_cost(good, 0.0, dry)
	var poor_dry: float = Start.pace_cost(poor, 0.0, dry)
	check(is_finite(good_dry) and good_dry > 0.0 and poor_dry > good_dry,
		"reaction, awareness, car performance and cold tyres affect launch")
	check(Start.reaction_seconds(good) < Start.reaction_seconds(poor),
		"driver reaction is individually bounded and skill-sensitive")
	check(Start.reaction_seconds(aggressive) < Start.reaction_seconds(good)
		and Start.pace_cost(aggressive, 4.0, rain) > Start.pace_cost(good, 4.0, rain),
		"aggression trades reaction against wet traction")
	check(Start.pace_cost(poor, 0.0, rain) > poor_dry,
		"rain and available grip affect traction")
	check(Start.pace_cost(poor, 2.0, dry) > Start.pace_cost(poor, 6.0, dry),
		"launch cost decays continuously")
	check(Start.pace_cost(poor, 8.0, rain) == 0.0
		and Start.pace_cost(poor, 9.0, rain) == 0.0
		and Start.pace_cost(poor, -0.1, rain) == 0.0,
		"no launch influence outside first eight seconds")
	check(Start.pace_cost(good, 0.0, dry) == good_dry
		and var_to_bytes(good) == good_bytes,
		"stateless, read-only calculation")
	check(Legacy.pace_cost(good, 0.0, 0.83) > 0.0,
		"original launch physics remains available for old recordings")

	var season_data: Variant = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not season_data is Dictionary:
		check(false, "season JSON")
		_finish()
		return
	var season: Dictionary = season_data
	var silverstone: Dictionary = _track(season, "GBR")
	var monza: Dictionary = _track(season, "ITA")
	if silverstone.is_empty() or monza.is_empty():
		check(false, "2012 circuits")
		_finish()
		return
	var first = Race.new(season["teams"], "Ferrari", 6611, {}, silverstone, {})
	var second = Race.new(season["teams"], "Ferrari", 6611, {}, silverstone, {})
	check(first.cars.size() == 24 and second.cars.size() == 24,
		"real Core 2 grid uses 24 drivers")
	check(not Codec.capture(first)["engine"].has("race_start_intelligence_enabled")
		and Codec.restore(Codec.capture(first)) != null,
		"session-only start policy leaves save/replay checkpoint schema intact")
	var a = Replay.new()
	a.attach(first)
	var b = Replay.new()
	b.attach(second)
	check(str(a.recorded_simulation_revision) == Replay.SIMULATION_REVISION
		and bool(a.race.race_start_intelligence_enabled),
		"new 022 session enables intelligent starts")
	for i in range(52):
		if not a.step_tick() or not b.step_tick():
			check(false, "022 race tick")
			break
	check(Codec.sporting_hash(a.race, a.policy) == Codec.sporting_hash(b.race, b.policy),
		"022 identical seeds have identical sporting hashes")
	var playback = Replay.new()
	check(playback.load_data(a.export_data())
		and playback.seek(a.end_tick) and playback.first_divergence < 0,
		"022 archive imports and replays to its final tick")

	# Simulate a faithful PRE-START 021 recorder. Do not rewrite its hashes.
	var old = Replay.new()
	old.attach(Race.new(season["teams"], "Ferrari", 6611, {}, silverstone, {}))
	old.recorded_simulation_revision = Replay.PRE_START_SIMULATION_REVISION
	old.legacy_start_intelligence = true
	old.race.race_start_intelligence_enabled = false
	old.checkpoints = [old.checkpoint()]
	for i in range(52):
		if not old.step_tick():
			check(false, "legacy 021 tick")
			break
	var old_player = Replay.new()
	check(old_player.load_data(old.export_data())
		and old_player.legacy_start_intelligence
		and not old_player.legacy_staff_strategy
		and not bool(old_player.race.race_start_intelligence_enabled)
		and bool(old_player.race.strategy_staff_intelligence_enabled)
		and old_player.seek(old.end_tick) and old_player.first_divergence < 0,
		"021 hash parity and strategy staff intelligence preserved")

	# Rain and manual V21 must not trigger a premature pit at lap 4.
	var wet = Race.new(season["teams"], "Ferrari", 6612, {}, monza, {})
	wet.configure_weather("Chuva intensa")
	var player: Dictionary = wet.player_cars()[0]
	var car_id: int = int(player["id"])
	check(wet.schedule_pit(car_id, str(wet.available_pit_compounds()[1]), 21),
		"manual V21 is accepted")
	wet.running = true
	for i in range(45):
		wet.step(0.2)
	check(int(player.get("pit_scheduled_lap", 0)) == 21
		and not bool(player.get("pit_request", false))
		and int(player.get("stops", 0)) == 0,
		"heavy rain cannot advance manual V21")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("RACE_START_066911_PASS checks=%d" % checks)
	else:
		for message in failures:
			printerr("FAIL: " + message)
	quit(0 if failures.is_empty() else 1)
