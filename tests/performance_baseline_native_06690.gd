extends SceneTree
## v0.6.6.9.0 — live-window diagnostic, requires non-headless graphics.
## Displays actual APEX 2012 race, uses real elapsed frame delta, does not change race rules.
const Perf = preload("res://scripts/debug/apex_perf_trace_0657.gd")
const SPEED_OPTIONS: Array[int] = [0, 3, 4, 5]
const SPEED_VALUES: Array[int] = [1, 10, 16, 32]
const WARMUP_FRAMES := 16
const SAMPLE_FRAMES := 75

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	printerr("APEX_NATIVE_BASELINE_06690_FAIL ", message)
	quit(1)

func _percentile(values: Array[int], fraction: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values: Array[int] = values.duplicate()
	sorted_values.sort()
	var i: int = clampi(int(ceil(float(sorted_values.size()) * fraction)) - 1, 0, sorted_values.size() - 1)
	return float(sorted_values[i]) / 1000.0

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("Native graphical run is required")
		return
	var filename: String = OS.get_environment("APEX_NATIVE_BASELINE_OUTPUT")
	if filename.is_empty():
		filename = "user://native_baseline_06690.json"
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(6):
		await process_frame
	host.set_process(false)
	for i in range(host.season_tracks.size()):
		if str(host.season_tracks[i].get("code", "")) == "GBR":
			host.selected_track_index = i
			break
	host.seed_picker.value = 6557
	var results: Array = []
	for resolution in [Vector2i(1600, 900), Vector2i(1920, 1080)]:
		root.size = resolution
		host._layout_ui()
		for n in range(SPEED_OPTIONS.size()):
			var speed_index: int = SPEED_OPTIONS[n]
			var speed_value: int = SPEED_VALUES[n]
			host._start_race()
			host.set_process(false)
			host._change_speed(speed_index)
			host.race.running = true
			if host.race.cars.size() != 24:
				_fail("Grid is not the official 24 cars")
				return
			if host.visual_setting != 0:
				_fail("Expected automatic visual mode")
				return
			var expected_render_mode: int = 1 if speed_value < 10 else 0
			if host.render_mode != expected_render_mode:
				_fail("Incorrect 2D/3D automatic visual policy")
				return

			Perf.set_enabled(false)
			var last_started: int = Time.get_ticks_usec()
			for i in range(WARMUP_FRAMES):
				var now: int = Time.get_ticks_usec()
				var delta: float = clampf(float(now - last_started) / 1000000.0, 0.0001, 0.25)
				last_started = now
				host._process(delta)
				await RenderingServer.frame_post_draw

			Perf.reset({"version":"06690","track":"GBR","seed":6557,"resolution":str(resolution),"speed":speed_value,"render_mode":host.render_mode})
			Perf.set_enabled(true)
			var start_tick: int = host.replay_session.tick
			var start_us: int = Time.get_ticks_usec()
			last_started = start_us
			var intervals_us: Array[int] = []
			var cpu_us: Array[int] = []
			var cpu_limited_frames: int = 0
			for i in range(SAMPLE_FRAMES):
				var frame_started: int = Time.get_ticks_usec()
				var delta: float = clampf(float(frame_started - last_started) / 1000000.0, 0.0001, 0.25)
				last_started = frame_started
				host._process(delta)
				cpu_us.append(Time.get_ticks_usec() - frame_started)
				if host.replay_session.cpu_limited:
					cpu_limited_frames += 1
				await RenderingServer.frame_post_draw
				intervals_us.append(Time.get_ticks_usec() - frame_started)
			var end_us: int = Time.get_ticks_usec()
			Perf.set_enabled(false)
			var trace: Dictionary = Perf.snapshot()
			var end_tick: int = host.replay_session.tick
			var wall_s: float = float(end_us - start_us) / 1000000.0
			var ticks: int = end_tick - start_tick
			if ticks < 1 or host.replay_session.hashes.size() != end_tick or wall_s <= 0.0:
				_fail("No deterministic race progress or invalid recorded hashes")
				return
			results.append({
				"resolution": "%dx%d" % [resolution.x, resolution.y],
				"requested_speed_x": speed_value,
				"visual_mode": "3D" if host.render_mode == 1 else "strategic_2D",
				"rendering_method": RenderingServer.get_current_rendering_method(),
				"actual_window_size": "%dx%d" % [root.size.x, root.size.y],
				"frames": SAMPLE_FRAMES,
				"sport_ticks": ticks,
				"sim_seconds": float(ticks) * 0.20,
				"wall_seconds": wall_s,
				"observed_fps_including_render": float(SAMPLE_FRAMES) / wall_s,
				"achieved_sport_speed_x": float(ticks) * 0.20 / wall_s,
				"frame_interval_p50_ms": _percentile(intervals_us, 0.50),
				"frame_interval_p95_ms": _percentile(intervals_us, 0.95),
				"frame_interval_p99_ms": _percentile(intervals_us, 0.99),
				"frame_cpu_p95_ms": _percentile(cpu_us, 0.95),
				"scheduler_cpu_limited_frames": cpu_limited_frames,
				"godot_static_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
				"telemetry": host.race.telemetry.summary(),
				"profiler": trace
			})
			print("APEX_NATIVE_BASELINE_06690_SAMPLE ", JSON.stringify(results[-1]))
	var report: Dictionary = {
		"schema": 1, "version": "0.6.6.9.0",
		"kind": "windowed_rendered_frames_in_virtual_display",
		"track": "GBR", "seed": 6557, "cars": 24,
		"environment": {
			"os": OS.get_name(), "godot": Engine.get_version_info().string,
			"cpu": OS.get_processor_name(), "display": DisplayServer.get_name(),
			"gpu_adapter": RenderingServer.get_video_adapter_name(),
			"rendering_method": RenderingServer.get_current_rendering_method()
		},
		"cases": results,
		"limitations": [
			"Xvfb/llvmpipe software rendering is NOT a measurement of the user's physical GPU.",
			"Frame intervals include display, process scheduling and rendering waits; they are not isolated GPU times.",
			"Warmup and samples represent early race, not a whole GP or memory-leak evaluation.",
			"Each scenario restarts with the same seed, not a continuous racing session.",
			"Actual speed is measured as executed fixed 0.2s sporting ticks per wall second.",
			"Profiler is enabled, and its own CPU overhead is included."
		]
	}
	var file: FileAccess = FileAccess.open(filename, FileAccess.WRITE)
	if file == null:
		_fail("Cannot write native benchmark JSON: " + filename)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	if results.size() != 8:
		_fail("Expected eight graphical scenarios")
		return
	print("APEX_NATIVE_BASELINE_06690_PASS ", JSON.stringify({"cases":results.size(),"path":filename}))
	quit(0)
