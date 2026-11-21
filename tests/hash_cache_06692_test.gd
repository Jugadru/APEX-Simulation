extends SceneTree
## 06692 — byte-compatible sporting hashes with cached *property names*.
## Compare against the unmodified v0.6.6.9.1 field-reflection algorithm.
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const CASES = [{"track":"ITA","weather":"Seco","seed":660}, {"track":"BEL","weather":"Chuva intensa","seed":661}]
const TICKS := 1200

func _initialize() -> void:
	call_deferred("_run")

func _reference_hash(race, policy: Dictionary) -> String:
	var e: Dictionary = Codec.fields(race, Codec.EXCLUDED, false)
	e.erase("running")
	return Codec.digest([e, race.rng.seed, race.rng.state,
		Codec.fields(race.weather, [], false),
		Codec.fields(race.track_dynamics, [], false), policy])

func _fail(reason: String) -> void:
	printerr("APEX_HASH_CACHE_06692_FAIL ", reason)
	quit(1)

func _run() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not data is Dictionary:
		_fail("Invalid season data")
		return
	var results: Array = []
	for case in CASES:
		var track: Dictionary = {}
		for item in data["tracks"]:
			if str(item.get("code", "")) == str(case["track"]):
				track = item.duplicate(true)
				break
		if track.is_empty():
			_fail("Unknown circuit")
			return
		var engine = Race.new(data["teams"], "Ferrari", int(case["seed"]), {}, track, {})
		engine.configure_weather(str(case["weather"]))
		var replay = Replay.new()
		replay.attach(engine)
		engine.running = true
		if engine.cars.size() != 24:
			_fail("Expected 24 cars")
			return
		var start_us: int = Time.get_ticks_usec()
		for i in range(TICKS):
			if not replay.step_tick():
				_fail("Recorded tick failure at " + str(i+1) + ": " + replay.error)
				return
			var reference: String = _reference_hash(engine, replay.policy)
			var actual: String = Codec.sporting_hash(engine, replay.policy)
			if reference != actual or replay.hashes[-1] != reference:
				_fail("Hash divergence at " + str(case["track"]) + " tick " + str(replay.tick))
				return
		if replay.tick != TICKS or replay.first_divergence >= 0:
			_fail("Incomplete deterministic run")
			return
		results.append({"track":case["track"],"weather":case["weather"],"ticks":TICKS,
			"final_hash":replay.hashes[-1],
			"total_wall_seconds_including_double_hash_checks":float(Time.get_ticks_usec()-start_us)/1000000.0})
	print("APEX_HASH_CACHE_06692_PASS ",JSON.stringify({"cases":results.size(),"verified_ticks":results.size()*TICKS,"results":results}))
	quit(0)
