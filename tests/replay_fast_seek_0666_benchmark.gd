extends SceneTree
# 0666: isolated navigation benchmark, same 0665 serialized Monza snapshot.
# Measures cold seek, nearby forward/backward seeks, persistent anchors and hashes.
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const FIXTURE := "res://qa/replay_fast_seek_0666/fixture_monza3200_0665.apexreplay"
const HISTORICAL_HASH := "f771fab5025055653075f853b4a06370097d5af74843d2deea4cc8dc17be9b90"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var player = Replay.new()
	assert(player.load_file(FIXTURE), player.error)
	assert(player.end_tick == 3200)
	assert(player.hashes[-1] == HISTORICAL_HASH)
	var targets: Array = [750, 780, 760, 775, 750, 800, 780, 750, 1050, 1075, 1050, 1500, 1530, 1500, 2800, 2830, 2800, 3200]
	var durations: Array = []
	var hashes: Array = []
	var audit_reports: Array = []
	for target in targets:
		var start: int = Time.get_ticks_usec()
		assert(player.seek(target), player.error)
		durations.append(float(Time.get_ticks_usec() - start) / 1000000.0)
		assert(player.tick == target)
		var current_hash: String = Codec.sporting_hash(player.race, player.policy)
		assert(current_hash == player.hashes[target - 1], "Invalid hash tick %d" % target)
		hashes.append(current_hash)
		var report: Dictionary = player.racecraft_report()
		audit_reports.append({"start_tick": report.start_tick, "end_tick": report.end_tick,
			"counts": report.counts, "drivers": report.drivers,
			"weather_and_risk": report.weather_and_risk})
	if OS.get_environment("APEX_0666_MODE") == "candidate":
		assert(player.hot_seek_checkpoints.size() <= 4)
	var hot_bytes: int = 0
	if OS.get_environment("APEX_0666_MODE") == "candidate":
		for cp in player.hot_seek_checkpoints:
			hot_bytes += cp.packed_state.size()
	assert(hot_bytes <= 12*1024*1024)
	# Cold and repeated same-position seek must produce the same detailed observer.
	var check = Replay.new()
	assert(check.load_file(FIXTURE), check.error)
	assert(check.seek(750), check.error)
	var expected_report: Dictionary = check.racecraft_report()
	assert(player.seek(750), player.error)
	var cached_report: Dictionary = player.racecraft_report()
	assert(cached_report.start_tick == expected_report.start_tick)
	assert(cached_report.counts == expected_report.counts)
	assert(cached_report.drivers == expected_report.drivers)
	assert(cached_report.weather_and_risk == expected_report.weather_and_risk)
	var old=Replay.new()
	assert(old.load_file("res://qa/long_race_0663/replay_0662_650.apexreplay"), old.error)
	assert(old.seek(650), old.error)
	var result: Dictionary = {"version": OS.get_environment("APEX_0666_MODE"),
		"targets": targets, "seconds":durations, "hashes":hashes,
		"racecraft_audits":audit_reports,
		"total_seek_seconds":_sum(durations),
		"hot_anchors":(player.hot_seek_checkpoints.size() if OS.get_environment("APEX_0666_MODE") == "candidate" else 0),
		"hot_bytes":hot_bytes,
		"legacy_replay_0662_ok":true,
		"sporting_hash_3200":HISTORICAL_HASH,
		"file_format":"APEX_REPLAY_0660",
		"godot_static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC))}
	var out: String=OS.get_environment("APEX_0666_BENCH_OUT")
	if not out.is_empty():
		var f=FileAccess.open(out,FileAccess.WRITE)
		assert(f != null)
		f.store_string(JSON.stringify(result,"  "))
		f.close()
	print("FAST_SEEK_0666_BENCH_PASS ",JSON.stringify(result))
	quit()
func _sum(v: Array) -> float:
	var total := 0.0
	for item in v: total += float(item)
	return total
