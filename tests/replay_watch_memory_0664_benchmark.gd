extends SceneTree
# 0664 real recording -> live replay peak-memory benchmark.
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var mode: String = OS.get_environment("APEX_WATCH_MODE")
	if mode.is_empty(): mode = "legacy"
	var n: int = int(OS.get_environment("APEX_WATCH_TICKS"))
	if n <= 0: n = 3200
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for t in data.tracks:
		if str(t.code) == "ITA": track = t.duplicate(true)
	assert(track.laps == 53)
	var e = Race.new(data.teams,"Ferrari",660,{},track,{})
	e.configure_weather("Seco")
	var id: int = e.player_cars()[0].id
	var other: int = e.player_cars()[1].id
	e.pit_incident_test_overrides[id]={"service_fault":"Porca travada","service_delay":4.0,"release_delay":4.5}
	var s=Replay.new()
	s.attach(e,{id:"Assistido",other:"Automático"},{"Engenheiro":2,"Estrategista":2})
	var compound: String=e.available_pit_compounds()[0]
	assert(s.enqueue("order_pit",[id,compound],3))
	assert(s.enqueue("order_pit",[other,compound],3))
	var start:=Time.get_ticks_usec()
	while s.tick<n and not e.finished:
		assert(s.step_tick(),s.error)
		if s.tick%1000==0:print("WATCH_BENCH_RACE ",JSON.stringify({"ticks":s.tick,"clock":e.clock}))
	var recording_s:=float(Time.get_ticks_usec()-start)/1000000.0
	print("WATCH_BENCH_BEFORE_FORK ",JSON.stringify({"ticks":s.tick,"hash":s.hashes[-1],
		"clock":e.clock,"recording_seconds":recording_s,
		"mem_static":int(Performance.get_monitor(Performance.MEMORY_STATIC))}))
	var replay=Replay.new()
	var elapsed:=Time.get_ticks_usec()
	var result: bool=false
	if mode=="direct":
		result=replay.load_live_session(s)
	else:
		result=replay.load_data(s.export_data())
	var fork_s:=float(Time.get_ticks_usec()-elapsed)/1000000.0
	assert(result,replay.error)
	assert(replay.tick==0 and replay.playback and replay.end_tick==s.tick)
	# Validate checkpoint-seek parity and independently verify the final hash.
	var midpoint: int=mini(640,s.tick)
	assert(replay.seek(midpoint),replay.error)
	assert(replay.seek(0),replay.error)
	assert(replay.hashes==s.hashes)
	var match_hash: String=s.hashes[-1]
	var output: Dictionary={"mode":mode,"ticks":s.tick,"seed":660,
		"record_seconds":recording_s,"fork_seconds":fork_s,
		"hash":match_hash,"checkpoint_count":replay.checkpoints.size(),
		"godot_static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"replay_ready":true}
	var path: String=OS.get_environment("APEX_WATCH_OUTPUT")
	if not path.is_empty():
		var f=FileAccess.open(path,FileAccess.WRITE)
		assert(f != null)
		f.store_string(JSON.stringify(output,"  "))
		f.close()
	print("WATCH_BENCH_FORK_PASS ",JSON.stringify(output))
	# Hold process, allowing external RSS sampler to see retained working set.
	await create_timer(1.5).timeout
	quit()
