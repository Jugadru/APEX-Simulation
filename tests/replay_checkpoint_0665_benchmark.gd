extends SceneTree
# APEX 0665 controlled A/B: same 2012 Monza sporting run, external archive,
# retained checkpoints and repeatable early/mid-race seek timing.
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for item in raw.tracks:
		if str(item.code) == "ITA": track = item.duplicate(true)
	assert(int(track.laps) == 53)
	var engine = Race.new(raw.teams, "Ferrari", 660, {}, track, {})
	engine.configure_weather("Seco")
	var players: Array = engine.player_cars()
	var id: int = int(players[0].id)
	var other: int = int(players[1].id)
	engine.pit_incident_test_overrides[id] = {"service_fault":"Porca travada", "service_delay":4.0, "release_delay":4.5}
	var session = Replay.new()
	session.attach(engine, {id:"Assistido", other:"Automático"}, {"Engenheiro":2,"Estrategista":2})
	var compound: String = engine.available_pit_compounds()[0]
	assert(session.enqueue("order_pit", [id,compound], 3))
	assert(session.enqueue("order_pit", [other,compound], 3))
	var start: int = Time.get_ticks_usec()
	while session.tick < 3200 and not engine.finished:
		assert(session.step_tick(), session.error)
	var record_s: float = float(Time.get_ticks_usec()-start)/1000000.0
	assert(session.tick == 3200)
	var final_hash: String = str(session.hashes[-1])
	assert(final_hash == "f771fab5025055653075f853b4a06370097d5af74843d2deea4cc8dc17be9b90")
	var checkpoint_ticks: Array = []
	for cp in session.checkpoints:
		checkpoint_ticks.append(int(cp.tick))
	assert(checkpoint_ticks.size() <= 9)
	var player=Replay.new()
	assert(player.load_live_session(session), player.error)
	var seek_targets: Array = [750, 1500, 2800]
	var seek_durations: Array = []
	for target in seek_targets:
		start = Time.get_ticks_usec()
		assert(player.seek(int(target)),player.error)
		seek_durations.append(float(Time.get_ticks_usec()-start)/1000000.0)
		assert(Codec.sporting_hash(player.race,player.policy) == session.hashes[target-1])
	assert(player.seek(3200),player.error)
	assert(Codec.sporting_hash(player.race,player.policy) == final_hash)
	var archive_path: String = "user://apex_0665_benchmark.apexreplay"
	start=Time.get_ticks_usec()
	assert(session.save_file(archive_path), session.error)
	var save_s: float = float(Time.get_ticks_usec()-start)/1000000.0
	var file = FileAccess.open(archive_path,FileAccess.READ)
	assert(file != null)
	var file_size: int = file.get_length()
	file.close()
	start=Time.get_ticks_usec()
	var imported=Replay.new()
	assert(imported.load_file(archive_path),imported.error)
	var load_s: float = float(Time.get_ticks_usec()-start)/1000000.0
	assert(imported.seek(1500),imported.error)
	assert(imported.seek(3200),imported.error)
	assert(Codec.sporting_hash(imported.race,imported.policy) == final_hash)
	var earlier=Replay.new()
	assert(earlier.load_file("res://qa/long_race_0663/replay_0662_650.apexreplay"), earlier.error)
	assert(earlier.seek(650), earlier.error)
	var result: Dictionary = {"mode":OS.get_environment("APEX_0665_MODE"),
		"ticks":session.tick,"seed":660,"track":"ITA","weather":"Seco",
		"hash":final_hash,"checkpoints":checkpoint_ticks,
		"record_s":record_s, "seek_targets":seek_targets,
		"seek_seconds":seek_durations,"save_seconds":save_s,
		"load_seconds":load_s,"archive_bytes":file_size,
		"legacy_v0662_read":true, "replay_sport_identical":true,
		"replay_format":"APEX_REPLAY_0660",
		"godot_static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC))}
	var out: String=OS.get_environment("APEX_0665_BENCH_OUT")
	if not out.is_empty():
		var f=FileAccess.open(out,FileAccess.WRITE)
		assert(f != null)
		f.store_string(JSON.stringify(result,"  "))
		f.close()
	print("CHECKPOINT_0665_BENCH_PASS ",JSON.stringify(result))
	await create_timer(1.0).timeout
	quit()
