extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const BASELINE_HASHES = {"GBR":"7bca12f99088048b747f7ac3626b635133628cb0ae57de15db4fdf072be64837", "BEL":"33c7c2d71e34779fb7e74f359f2663e0bea34074aaf4c655dc678f3b97fd8c0e", "ITA":"5d4c508a64dce8d1c481a3661f56c6bdf97a2a7a7bab37a5e290be5e54188592", "SIN":"48085a06fed3d7761a58206673c03685043645d813ea809e0b76c968e94439c9"}
# The historical short-race baseline uses the original replay_0660_gp.gd fixture.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var code: String = OS.get_environment("APEX_TRACK")
	if code.is_empty(): code = "GBR"
	var mode: String = OS.get_environment("APEX_WEATHER")
	if mode.is_empty(): mode = "Seco"
	var full: bool = OS.get_environment("APEX_FULL") == "1"
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for entry in data.tracks:
		if entry.code == code: track = entry.duplicate(true)
	assert(not track.is_empty())
	if not full: track.laps = 3
	var engine = Race.new(data.teams, "Ferrari", 660, {}, track, {})
	engine.configure_weather(mode)
	var id: int = engine.player_cars()[0].id
	var other: int = engine.player_cars()[1].id
	engine.pit_incident_test_overrides[id] = {"service_fault":"Porca travada", "service_delay":4.0, "release_delay":4.5}
	var s = Replay.new()
	s.attach(engine, {id:"Assistido", other:"Automático"}, {"Engenheiro":2,"Estrategista":2})
	var compound: String = "Chuva" if mode == "Chuva intensa" else engine.available_pit_compounds()[0]
	assert(s.enqueue("order_pit", [id,compound], 3))
	assert(s.enqueue("order_pit", [other,compound], 3))
	var start: int = Time.get_ticks_msec()
	var seen: Dictionary = {}
	while not engine.finished and s.tick < (160000 if full else 60000):
		assert(s.step_tick(), s.error)
		for car in engine.player_cars():
			var phase: String = str(car.get("pit_stage", ""))
			if float(car.pit_left) > 0.0: seen[phase] = true
	assert(engine.finished, "Race must reach chequered flag")
	var live_ms: int = Time.get_ticks_msec() - start
	var report: Dictionary = s.racecraft_report()
	assert(int(report.end_tick) == s.tick and int(report.start_tick) == 0)
	assert(int(report.counts.confirmed_passes) <= int(report.counts.attack_signals) + 24, "Pass diagnostics not unbounded")
	var final_hash: String = s.hashes[-1]
	var old_sha: String = BASELINE_HASHES.get(code, "")
	# Check historical strict hashes for short races. No historical baseline for full GP.
	if not full: assert(final_hash == old_sha, "Regression: changed sporting hashes from 0661")
	var finished_count: int = 0
	var positions: Dictionary = {}
	for car in engine.get_sorted():
		if bool(car.finished): finished_count += 1
		assert(not positions.has(int(car.position)))
		positions[int(car.position)] = true
	assert(finished_count == 24 and engine.pit_history.size() >= 2)
	var recorder_data: Dictionary = s.export_data()
	var r = Replay.new()
	assert(r.load_data(recorder_data), r.error)
	# Rewind to initial checkpoint to validate the full event sequence and audit counts.
	r.checkpoints = [r.checkpoints[0]]
	start = Time.get_ticks_msec()
	assert(r.seek(s.tick), r.error)
	var replay_ms: int = Time.get_ticks_msec() - start
	assert(Codec.sporting_hash(engine,s.policy) == Codec.sporting_hash(r.race,r.policy))
	assert(r.racecraft_report().counts == report.counts)
	assert(r.racecraft_report().drivers == report.drivers)
	var out: Dictionary = {"track":code,"weather":mode,"full_distance":full,"laps":track.laps,"ticks":s.tick,
		"live_ms":live_ms,"replay_ms":replay_ms,"hash":final_hash,"matches_0661_short_baseline": not full,
		"pit_phases":seen.keys(),"pit_stops":engine.pit_history.size(),"audit":report,"passed":true}
	var suffix: String = "full" if full else "short"
	var filepath: String = "res://qa/replay_fast_seek_0666/gp_%s_%s_%s.json" % [code,mode,suffix]
	var f = FileAccess.open(filepath, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	f.close()
	print("RACECRAFT_0666_GP_PASS ", {"track":code,"laps":track.laps,"ticks":s.tick,"hash":final_hash,"live_ms":live_ms,"replay_ms":replay_ms,"counts":report.counts})
	quit()
