extends SceneTree
## v0.6.6.9.0 — read-only Performance Baseline 2.0.
## Synthetic 60 Hz input, NOT a visual FPS measurement or a real-time scheduler test.
## Uses the official Core 2, replay and existing profiler without altering sport state.
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Perf = preload("res://scripts/debug/apex_perf_trace_0657.gd")
const FRAME_DELTA := 1.0 / 60.0
const FRAME_BUDGET_US := 16667

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	printerr("APEX_BASELINE_06690_FAIL ", message)
	quit(1)

func _percentile_ms(values: Array[int], fraction: float) -> float:
	if values.is_empty():
		return 0.0
	var ordered: Array[int] = values.duplicate()
	ordered.sort()
	var index: int = clampi(int(ceil(float(ordered.size()) * fraction)) - 1, 0, ordered.size() - 1)
	return float(ordered[index]) / 1000.0

func _run() -> void:
	var speed: int = int(OS.get_environment("APEX_BASELINE_SPEED"))
	if speed == 0:
		speed = 1
	if speed not in [1, 10, 16, 32]:
		_fail("APEX_BASELINE_SPEED must be 1, 10, 16 or 32")
		return
	var target_ticks: int = int(OS.get_environment("APEX_BASELINE_TICKS"))
	if target_ticks <= 0:
		target_ticks = 180
	if target_ticks > 2000:
		_fail("Limit APEX_BASELINE_TICKS to 2000 for this diagnostic")
		return
	var code: String = OS.get_environment("APEX_BASELINE_TRACK")
	if code.is_empty():
		code = "ITA"
	var weather: String = OS.get_environment("APEX_BASELINE_WEATHER")
	if weather.is_empty():
		weather = "Seco"
	var seed: int = int(OS.get_environment("APEX_BASELINE_SEED"))
	if seed <= 0:
		seed = 660
	var trace_enabled: bool = OS.get_environment("APEX_BASELINE_PROFILE") != "0"
	var output_path: String = OS.get_environment("APEX_BASELINE_OUTPUT")
	if output_path.is_empty():
		output_path = "user://performance_baseline_06690.json"

	# Record data parsing and session construction separately from sporting ticks.
	var load_started: int = Time.get_ticks_usec()
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not (source is Dictionary):
		_fail("Cannot load season_2012.json")
		return
	var track: Dictionary = {}
	for item in source["tracks"]:
		if str(item.get("code", "")) == code:
			track = item.duplicate(true)
			break
	if track.is_empty():
		_fail("Unknown track: " + code)
		return
	var parse_ms: float = float(Time.get_ticks_usec() - load_started) / 1000.0
	var setup_started: int = Time.get_ticks_usec()
	var race = Race.new(source["teams"], "Ferrari", seed, {}, track, {})
	race.configure_weather(weather)
	if race.cars.size() != 24:
		_fail("Expected 24 official cars, got %d" % race.cars.size())
		return
	var replay = Replay.new()
	replay.attach(race)
	race.running = true
	var session_setup_ms: float = float(Time.get_ticks_usec() - setup_started) / 1000.0

	Perf.set_enabled(false)
	Perf.reset({"benchmark": "06690", "track": code, "weather": weather, "seed": seed, "cars": 24, "speed": speed, "synthetic_input_hz": 60})
	Perf.set_enabled(trace_enabled)
	var loop_started: int = Time.get_ticks_usec()
	var frame_us: Array[int] = []
	var samples: Array = []
	var frames: int = 0
	var frames_over_cpu_budget: int = 0
	var no_progress_frames: int = 0
	var observed_cpu_limited_frames: int = 0
	var max_frames: int = target_ticks * 16 + 120
	var next_sample_tick: int = 40
	while replay.tick < target_ticks and not race.finished and frames < max_frames:
		var before_tick: int = replay.tick
		var frame_started: int = Time.get_ticks_usec()
		replay.advance(FRAME_DELTA, float(speed))
		var elapsed_us: int = Time.get_ticks_usec() - frame_started
		frame_us.append(elapsed_us)
		frames += 1
		if replay.tick == before_tick:
			no_progress_frames += 1
		if elapsed_us > FRAME_BUDGET_US:
			frames_over_cpu_budget += 1
		if replay.cpu_limited:
			observed_cpu_limited_frames += 1
		if replay.tick >= next_sample_tick:
			samples.append({
				"tick": replay.tick,
				"frame": frames,
				"clock": race.clock,
				"godot_static_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
				"events": race.events.size(),
				"telemetry_positions": race.telemetry.position_history.size(),
				"telemetry_events": race.telemetry.event_history.size(),
				"telemetry_laps": race.telemetry.lap_history.size(),
				"checkpoints": replay.checkpoints.size()
			})
			next_sample_tick += 40
	var measured_us: int = Time.get_ticks_usec() - loop_started
	Perf.set_enabled(false)
	var trace: Dictionary = Perf.snapshot()
	if replay.tick < target_ticks and not race.finished:
		_fail("Benchmark stopped without reaching target ticks")
		return
	if replay.first_divergence >= 0 or not replay.error.is_empty() or replay.hashes.is_empty():
		_fail("Recording failed: " + replay.error)
		return

	# Independent, unprofiled run at exactly the same tick count.
	# Never use a comparison with a different simulated duration.
	var verify_started: int = Time.get_ticks_usec()
	var reference_race = Race.new(source["teams"], "Ferrari", seed, {}, track.duplicate(true), {})
	reference_race.configure_weather(weather)
	var reference = Replay.new()
	reference.attach(reference_race)
	reference_race.running = true
	for i in range(replay.tick):
		if not reference.step_tick():
			_fail("Independent replay failed at tick %d: %s" % [i + 1, reference.error])
			return
	var hash_value: String = replay.hashes[replay.hashes.size() - 1]
	var reference_hash: String = reference.hashes[reference.hashes.size() - 1] if not reference.hashes.is_empty() else ""
	var same_hash: bool = hash_value == reference_hash
	var verify_ms: float = float(Time.get_ticks_usec() - verify_started) / 1000.0
	var cpu_wall_seconds: float = float(measured_us) / 1000000.0
	var synthetic_input_seconds: float = float(frames) * FRAME_DELTA
	var report: Dictionary = {
		"schema": 1,
		"version": "0.6.6.9.0",
		"status": "PASS" if same_hash else "FAIL",
		"kind": "headless_synthetic_frame_input_not_native_fps",
		"config": {"track": code, "weather": weather, "seed": seed, "cars": 24, "laps": int(track.laps), "requested_speed_x": speed, "target_ticks": target_ticks, "trace_enabled": trace_enabled},
		"environment": {"godot": Engine.get_version_info().string, "os": OS.get_name(), "cpu": OS.get_processor_name(), "display": DisplayServer.get_name()},
		"load": {"season_json_parse_ms": parse_ms, "race_and_replay_setup_ms": session_setup_ms},
		"cpu": {"frames": frames, "frame_delta_input_seconds": FRAME_DELTA, "synthetic_input_seconds": synthetic_input_seconds, "wall_seconds": cpu_wall_seconds, "ticks": replay.tick, "simulated_seconds": replay.tick * Replay.STEP, "simulated_per_wall_second": float(replay.tick) * Replay.STEP / maxf(cpu_wall_seconds, 0.000001), "simulated_per_synthetic_input_second": float(replay.tick) * Replay.STEP / maxf(synthetic_input_seconds, 0.000001), "mean_tick_cpu_ms_including_runner": float(measured_us) / 1000.0 / maxf(1.0, float(replay.tick)), "frame_cpu_p50_ms": _percentile_ms(frame_us, 0.50), "frame_cpu_p95_ms": _percentile_ms(frame_us, 0.95), "frame_cpu_p99_ms": _percentile_ms(frame_us, 0.99), "frame_cpu_max_ms": _percentile_ms(frame_us, 1.0), "frames_exceeding_16_667ms_cpu": frames_over_cpu_budget, "frames_without_sport_tick": no_progress_frames, "scheduler_cpu_limited_frames": observed_cpu_limited_frames},
		"state": {"final_hash": hash_value, "independent_hash": reference_hash, "hash_equal": same_hash, "reference_run_ms": verify_ms, "finished_early": race.finished, "telemetry": race.telemetry.summary(), "checkpoints": replay.checkpoints.size(), "sampled_growth": samples},
		"profiler": trace,
		"limitations": [
			"No rendering, native FPS, GPU time, frame pacing, process CPU percent or RSS is measured here.",
			"60 Hz deltas are synthetic and are not paced to a real wall-clock display.",
			"advance() has no frame budget or backlog cap in this diagnostic; interactive scheduler limits require separate native testing.",
			"Profiler scopes are inclusive and may overlap; memory monitor is not process RSS.",
			"Wall measurements are machine- and build-dependent; use repeated matched runs."
		]
	}
	var file: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		_fail("Unable to write report " + output_path)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("APEX_BASELINE_06690_DONE ", JSON.stringify({"speed": speed, "track": code, "ticks": replay.tick, "frames": frames, "cpu_wall_s": cpu_wall_seconds, "hash_match": same_hash, "output": output_path}))
	quit(0 if same_hash else 1)
