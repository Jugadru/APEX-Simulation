extends SceneTree
# Full 53-lap historical Monza archive is supplied by test runner via env.
# Avoids bundling an additional ~41.5 MB of duplicate user replay content.
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const HISTORICAL_HASH := "2a7e27179177858b8754a0c65666b325499e4aa13d423de060181b11d9ae1c4b"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var path: String = OS.get_environment("APEX_0666_MONZA_PATH")
	assert(not path.is_empty() and FileAccess.file_exists(path), "Set APEX_0666_MONZA_PATH to the 0665 Monza 53-lap replay")
	var player = Replay.new()
	assert(player.load_file(path), player.error)
	assert(player.end_tick == 24431)
	assert(player.hashes[24430] == HISTORICAL_HASH)
	var targets: Array = [10000, 10035, 10000, 20000, 20030, 20000, 24431, 24400, 24431]
	var durations: Array = []
	var detail: Array = []
	var first_report: Dictionary = {}
	for target in targets:
		var start: int = Time.get_ticks_usec()
		assert(player.seek(target), player.error)
		durations.append(float(Time.get_ticks_usec()-start)/1000000.0)
		assert(Codec.sporting_hash(player.race,player.policy)==player.hashes[target-1])
		var report: Dictionary = player.racecraft_report()
		if target==10000:
			if first_report.is_empty(): first_report=report.duplicate(true)
			else:
				assert(report.counts==first_report.counts)
				assert(report.drivers==first_report.drivers)
				assert(report.start_tick==first_report.start_tick)
		detail.append({"tick":target,"audit_start":report.start_tick,"audit_end":report.end_tick})
	var cars: Array = player.race.cars
	assert(cars.size()==24)
	var final_hash: String=Codec.sporting_hash(player.race,player.policy)
	assert(final_hash==HISTORICAL_HASH)
	var result: Dictionary={"source":"0665 Monza 53 lap archive (no new race simulation)",
		"ticks":player.end_tick,"cars":cars.size(), "sporting_hash":final_hash,
		"targets":targets,"seek_seconds":durations,"audit":detail,
		"all_targets_deterministic":true, "archive_size_bytes":FileAccess.open(path, FileAccess.READ).get_length(),
		"hot_count":player.hot_seek_checkpoints.size()}
	var out: String=OS.get_environment("APEX_0666_MONZA_OUT")
	if not out.is_empty():
		var f=FileAccess.open(out,FileAccess.WRITE)
		assert(f!=null)
		f.store_string(JSON.stringify(result,"  "))
		f.close()
	print("REPLAY_FAST_SEEK_0666_MONZA53_PASS ",JSON.stringify(result))
	quit()
