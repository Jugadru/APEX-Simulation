extends SceneTree
# Headless, fixed-seed, same replay path for pre/post performance measurements.
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const Perf = preload("res://scripts/debug/apex_perf_trace_0657.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var code: String = OS.get_environment("APEX_TRACK")
	if code.is_empty(): code = "ITA"
	var target: int = int(OS.get_environment("APEX_TEST_TICKS"))
	if target < 1: target = 2500
	var full: bool = OS.get_environment("APEX_FULL") == "1"
	var seed: int = int(OS.get_environment("APEX_SEED"))
	if seed < 1: seed = 660
	var mode: String = OS.get_environment("APEX_WEATHER")
	if mode.is_empty(): mode = "Seco"
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for t in data.tracks:
		if str(t.code) == code: track = t.duplicate(true)
	assert(not track.is_empty())
	if not full: track.laps = 3
	var engine = Race.new(data.teams, "Ferrari", seed, {}, track, {})
	engine.configure_weather(mode)
	var ids: Array = engine.player_cars()
	var id: int = int(ids[0].id)
	var other: int = int(ids[1].id)
	engine.pit_incident_test_overrides[id] = {"service_fault":"Porca travada","service_delay":4.0,"release_delay":4.5}
	var s = Replay.new()
	s.attach(engine,{id:"Assistido",other:"Automático"},{"Engenheiro":2,"Estrategista":2})
	var compound: String = "Chuva" if mode == "Chuva intensa" else engine.available_pit_compounds()[0]
	assert(s.enqueue("order_pit",[id,compound],3))
	assert(s.enqueue("order_pit",[other,compound],3))
	if OS.get_environment("APEX_BENCH_PROFILE") == "1":
		Perf.set_enabled(true)
		Perf.reset({"scenario":"long_race_0663","track":code,"full":full,"seed":seed})
	var started: int = Time.get_ticks_usec()
	var samples: Array = []
	var memory_peak: int = 0
	var min_ticks: int = mini(target, 100000)
	while not engine.finished and s.tick < min_ticks:
		assert(s.step_tick(),s.error)
		if s.tick % 500 == 0:
			var elapsed: float = float(Time.get_ticks_usec()-started) / 1000000.0
			samples.append({"tick":s.tick,"seconds":elapsed,"clock":engine.clock,"laps":int(engine.lap),"checkpoint_count":s.checkpoints.size(),"events":engine.events.size(),"telemetry_positions":engine.telemetry.position_history.size()})
			print("LRP_PROGRESS ", JSON.stringify(samples[-1]))
	var duration: float = float(Time.get_ticks_usec()-started)/1000000.0
	var perf: Dictionary = Perf.snapshot()
	var output: Dictionary = {"track":code,"seed":seed,"mode":mode,"laps":track.laps,"full_distance":full,"ticks":s.tick,
		"finished":engine.finished,"duration_seconds":duration,"last_hash":s.hashes[-1] if s.hashes.size()>0 else "",
		"checkpoints":s.checkpoints.size(),"hashes":s.hashes.size(),"events":engine.events.size(),
		"telemetry":engine.telemetry.summary(),"samples":samples,
		"performance":perf}
	var path: String = OS.get_environment("APEX_BENCH_OUTPUT")
	if not path.is_empty():
		var f = FileAccess.open(path,FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(output,"  "))
			f.close()
	print("LRP_BENCH_DONE ",JSON.stringify({"ticks":s.tick,"finished":engine.finished,"duration_s":duration,"hash":output.last_hash}))
	quit()
