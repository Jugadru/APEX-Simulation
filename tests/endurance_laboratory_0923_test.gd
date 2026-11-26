extends SceneTree
## Bounded FAST observation of existing replay, telemetry and recovery contracts.
## Synthetic LAB only; no full GP, no changed simulation state/schema or timing gate.
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const TICKS := 320
const ANNOTATIONS := 160
const ARCHIVE := "user://endurance_0923.apexreplay"
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("ENDURANCE_LAB_0923_FAIL ", label)
	return ok

func finish(report: Dictionary) -> void:
	report["checks"] = checks
	report["failures"] = failures
	report["scope"] = "bounded synthetic LAB; FULL NOT_RUN; timing advisory; not native 32x"
	print("ENDURANCE_LAB_0923_REPORT ", JSON.stringify(report))
	if failures.is_empty():
		print("ENDURANCE_LAB_0923_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)

func percentile(sorted_us: Array[int], q: float) -> float:
	return float(sorted_us[clampi(ceili(q * sorted_us.size()) - 1, 0, sorted_us.size() - 1)]) / 1000.0

func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/apex_lab_track.json"))
	if not verify(track.code == "LAB", "synthetic fixture only"):
		finish({}); return
	var e = Race.new(data.teams, "Ferrari", 92311, {}, track, {})
	e.configure_weather("Seco")
	var s = Replay.new()
	s.attach(e)
	var actor: int = int(e.player_cars()[0].id)
	for i in range(ANNOTATIONS):
		if not verify(s.enqueue("annotation", [actor, "engineer_question", "Endurance fixture %d" % i, 1], i + 1), "queued annotation"):
			finish({}); return
	if not verify(s.enqueue("set_pace", [actor, "Atacar"], 301), "command after checkpoint"):
		finish({}); return
	var times: Array[int] = []
	var samples: Array = []
	var max_recent: int = 0
	for i in range(TICKS):
		var started: int = Time.get_ticks_usec()
		if not verify(s.step_tick(), "record tick %d" % (i + 1)):
			finish({"tick":s.tick}); return
		times.append(Time.get_ticks_usec() - started)
		max_recent = maxi(max_recent, e.events.size())
		verify(e.events.size() <= 140, "recent radio ring bound")
		verify(s.checkpoints.size() <= Replay.MAX_CHECKPOINTS, "permanent checkpoint bound")
		if s.tick % 40 == 0:
			samples.append({"tick":s.tick, "static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),
				"radio_events":e.events.size(), "telemetry_events":e.telemetry.event_history.size(),
				"position_samples":e.telemetry.position_history.size(), "checkpoints":s.checkpoints.size()})
	verify(s.tick == TICKS and s.hashes.size() == TICKS, "every tick recorded")
	verify(max_recent == 140 and e.events.size() == 140, "ring actually saturated")
	var history: Array = e.telemetry.event_history
	verify(history.size() >= ANNOTATIONS and history.size() > e.events.size(), "complete telemetry is retained separately")
	var annotations: int = 0
	for item in history:
		if str(item.get("message", "")).begins_with("Endurance fixture "):
			annotations += 1
	verify(annotations == ANNOTATIONS, "no annotated events lost")
	for i in range(e.events.size()):
		verify(e.events[i] == history[history.size() - e.events.size() + i], "recent radio equals full-history tail")
	if not verify(s.checkpoints.size() == 2 and int(s.checkpoints[0].tick) == 0 and int(s.checkpoints[-1].tick) == 300, "real initial and periodic checkpoints"):
		finish({}); return
	var expected_hash: String = str(s.hashes[-1])
	var telemetry_hash: String = Codec.digest(Codec.fields(e.telemetry))
	var cp: Dictionary = s._checkpoint_state(s.checkpoints[-1])
	verify(not cp.is_empty() and s.checkpoints[-1].has("packed_state"), "compressed checkpoint decodes")
	var restored = Codec.restore(cp)
	verify(restored != null, "checkpoint restores")
	if restored != null:
		verify(Codec.digest(Codec.capture(restored)) == Codec.digest(cp), "exact checkpoint state")
	var fork = Replay.new()
	if not verify(fork.load_live_session(s), "fork live session"):
		finish({}); return
	var hot_max: int = 0
	var hot_bytes_max: int = 0
	for target in [40, 80, 120, 160, 200, 240, 300, 320, 80, 320]:
		if not verify(fork.seek(target), "seek %d: %s" % [target, fork.error]):
			finish({}); return
		verify(Codec.sporting_hash(fork.race, fork.policy) == s.hashes[target - 1], "seek hash %d" % target)
		var bytes: int = 0
		for anchor in fork.hot_seek_checkpoints:
			bytes += anchor.packed_state.size()
		hot_max = maxi(hot_max, fork.hot_seek_checkpoints.size())
		hot_bytes_max = maxi(hot_bytes_max, bytes)
		verify(fork.hot_seek_checkpoints.size() <= Replay.MAX_HOT_SEEK_CHECKPOINTS, "hot checkpoint count")
		verify(bytes <= Replay.MAX_HOT_SEEK_BYTES, "hot compressed byte budget")
	verify(hot_max == Replay.MAX_HOT_SEEK_CHECKPOINTS, "hot cache actually saturated")
	verify(s.tick == TICKS and Codec.sporting_hash(e, s.policy) == expected_hash, "fork does not mutate recorder")
	verify(Codec.digest(Codec.fields(fork.race.telemetry)) == telemetry_hash, "fork full telemetry equality")
	if not verify(s.save_file(ARCHIVE), "archive saved"):
		finish({}); return
	var f := FileAccess.open(ARCHIVE + ".tmp", FileAccess.WRITE)
	if not verify(f != null, "simulated interrupted temporary write"):
		finish({}); return
	f.store_string("interrupted write fixture")
	f.close()
	var loaded = Replay.new()
	if not verify(loaded.load_file(ARCHIVE), "valid primary survives stale temporary file"):
		finish({}); return
	if not verify(loaded.seek(TICKS), "archive seek final tick"):
		finish({}); return
	verify(Codec.sporting_hash(loaded.race, loaded.policy) == expected_hash, "recovered sporting hash")
	verify(Codec.digest(Codec.fields(loaded.race.telemetry)) == telemetry_hash, "recovered full telemetry")
	var damaged := FileAccess.open(ARCHIVE + ".bad", FileAccess.WRITE)
	if not verify(damaged != null, "corruption fixture opened"):
		finish({}); return
	damaged.store_var({"magic":"APEX_REPLAY_0660", "sha256":"invalid", "body":var_to_bytes(s.export_data())}, false)
	damaged.close()
	verify(not Replay.new().load_file(ARCHIVE + ".bad"), "checksum corruption rejected")
	for suffix in ["", ".tmp", ".bad"]:
		DirAccess.remove_absolute(ARCHIVE + suffix)
	times.sort()
	var elapsed_us: int = 0
	for value in times:
		elapsed_us += value
	finish({"ticks":s.tick, "seed":92311, "sporting_hash":expected_hash,
		"telemetry_events":history.size(), "recent_events_max":max_recent, "annotations_retained":annotations,
		"permanent_checkpoints":s.checkpoints.size(), "hot_checkpoints_max":hot_max,
		"hot_compressed_bytes_max":hot_bytes_max, "samples":samples,
		"tick_p50_ms":percentile(times, 0.50), "tick_p95_ms":percentile(times, 0.95),
		"tick_p99_ms":percentile(times, 0.99), "tick_mean_ms":float(elapsed_us) / times.size() / 1000.0,
		"headless_sim_seconds_per_tick_wall_second":TICKS * Replay.STEP * 1000000.0 / maxf(1.0, float(elapsed_us))})
