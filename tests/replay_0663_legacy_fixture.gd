extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var path: String = OS.get_environment("APEX_LEGACY_PATH")
	var mode: String = OS.get_environment("APEX_LEGACY_MODE")
	var replay = Replay.new()
	var ticks: int = int(OS.get_environment("APEX_LEGACY_TICKS"))
	if ticks <= 0: ticks = 250
	if mode == "record":
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
		var track: Dictionary = {}
		for t in data.tracks:
			if str(t.code) == "ITA": track = t.duplicate(true)
		track.laps = 3
		var engine = Race.new(data.teams, "Ferrari", 660, {}, track, {})
		engine.configure_weather("Seco")
		var id: int = int(engine.player_cars()[0].id)
		replay.attach(engine, {id:"Assistido"}, {"Engenheiro":2,"Estrategista":2})
		assert(replay.enqueue("set_pace",[id,"Atacar"],10))
		for i in range(ticks):
			assert(replay.step_tick(),replay.error)
		assert(replay.save_file(path),replay.error)
		print("LEGACY_RECORD_PASS ",replay.hashes[-1]," ",replay.end_tick)
	else:
		assert(replay.load_file(path), replay.error)
		assert(replay.end_tick == ticks)
		if ticks >= 620:
			assert(replay.seek(620),replay.error)
		replay.checkpoints = [replay.checkpoints[0]]
		assert(replay.seek(ticks),replay.error)
		assert(Codec.sporting_hash(replay.race,replay.policy) == replay.hashes[-1])
		print("LEGACY_REPLAY_PASS ",replay.hashes[-1]," ",replay.end_tick)
	quit()
