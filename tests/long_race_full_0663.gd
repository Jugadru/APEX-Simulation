extends SceneTree
# APEX 0663: full-distance performance + integral deterministic replay.
# Uses the same seed/commands/track as the 0662 full-distance fixture.
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const MAX_TICKS := 160000

func _initialize() -> void:
	call_deferred("run")

func write_report(data: Dictionary) -> void:
	var path: String = OS.get_environment("APEX_FULL_REPORT")
	if path.is_empty(): path = "res://qa/long_race_0663/monza_53.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data, "  "))
		f.close()

func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for t in data.tracks:
		if str(t.code) == "ITA": track = t.duplicate(true)
	assert(not track.is_empty() and int(track.laps) == 53, "Official Monza fixture required")
	var engine = Race.new(data.teams, "Ferrari", 660, {}, track, {})
	engine.configure_weather("Seco")
	var id: int = engine.player_cars()[0].id
	var other: int = engine.player_cars()[1].id
	engine.pit_incident_test_overrides[id] = {"service_fault":"Porca travada", "service_delay":4.0, "release_delay":4.5}
	var s = Replay.new()
	s.attach(engine,{id:"Assistido",other:"Automático"},{"Engenheiro":2,"Estrategista":2})
	var compound: String = engine.available_pit_compounds()[0]
	assert(s.enqueue("order_pit",[id,compound],3))
	assert(s.enqueue("order_pit",[other,compound],3))
	var start: int = Time.get_ticks_usec()
	# 06692: per-window wall/CPU throughput across a real full-distance GP.
	# Times observe completed ticks only; this code never changes race state.
	var block_start_tick: int = 0
	var block_start_us: int = start
	var live_cpu_windows: Array = []
	var report: Dictionary = {"scenario":"Monza 53 laps","track":"ITA","seed":660,"weather":"Seco","scheduled_laps":53,"recording_format":Replay.SIMULATION_REVISION,
		"full_live_finished":false,"full_replay_verified":false,"sport_hash":""}
	var seen: Dictionary = {}
	while not engine.finished and s.tick < MAX_TICKS:
		if not s.step_tick():
			report.error = "Recording tick failed: "+s.error
			break
		for car in engine.player_cars():
			if float(car.pit_left)>0.0: seen[str(car.get("pit_stage",""))] = true
		if s.tick%2000==0:
			var now_us: int = Time.get_ticks_usec()
			var ticks_in_window: int = s.tick - block_start_tick
			var elapsed_us: int = now_us - block_start_us
			live_cpu_windows.append({
				"start_tick": block_start_tick, "end_tick": s.tick,
				"cpu_ms_per_tick": float(elapsed_us)/1000.0/maxi(1,ticks_in_window),
				"simulated_per_wall_second": float(ticks_in_window)*Replay.STEP/maxf(0.000001,float(elapsed_us)/1000000.0),
				"leader_lap": engine.lap,
				"telemetry_positions": engine.telemetry.position_history.size(),
				"checkpoints": s.checkpoints.size(),
				"godot_static_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC))
			})
			block_start_tick = s.tick
			block_start_us = now_us
			print("LRP_FULL_LIVE ",JSON.stringify({"ticks":s.tick,"leader_lap":engine.lap,"sim_seconds":engine.clock,
				"wall_seconds":float(now_us-start)/1000000.0,
				"positions_sampled":engine.telemetry.position_history.size(),"checkpoints":s.checkpoints.size()}))
	if s.tick > block_start_tick:
		var final_elapsed_us: int = Time.get_ticks_usec() - block_start_us
		var final_ticks: int = s.tick - block_start_tick
		live_cpu_windows.append({
			"start_tick": block_start_tick, "end_tick": s.tick,
			"cpu_ms_per_tick": float(final_elapsed_us)/1000.0/maxi(1,final_ticks),
			"simulated_per_wall_second": float(final_ticks)*Replay.STEP/maxf(0.000001,float(final_elapsed_us)/1000000.0),
			"leader_lap": engine.lap, "telemetry_positions": engine.telemetry.position_history.size(),
			"checkpoints": s.checkpoints.size(),
			"godot_static_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC))
		})
	report.live_cpu_windows_06692 = live_cpu_windows
	report.live_seconds=float(Time.get_ticks_usec()-start)/1000000.0
	report.live_ticks=s.tick
	report.full_live_finished=bool(engine.finished)
	report.pit_stops=engine.pit_history.size()
	report.pit_phases=seen.keys()
	report.telemetry_summary=engine.telemetry.summary()
	report.racecraft_audit=s.racecraft_report()
	var positions: Dictionary = {}
	var finished_count: int = 0
	var classification: Array = []
	for car in engine.get_sorted():
		if bool(car.finished): finished_count+=1
		positions[int(car.position)]=true
		classification.append({"id":int(car.id),"name":str(car.name),"position":int(car.position),"finish_time":float(car.get("finish_time",-1.0)),"laps":int(car.laps_done)})
	report.finished_cars=finished_count
	report.unique_positions=positions.size()
	report.classification=classification
	if s.hashes.size()>0: report.sport_hash=s.hashes[-1]
	write_report(report)
	print("LRP_FULL_LIVE_END ",JSON.stringify({"finished":engine.finished,"ticks":s.tick,"seconds":report.live_seconds,
		"hash":report.sport_hash,"finished_cars":finished_count,"unique_positions":positions.size()}))
	if not engine.finished or finished_count != 24 or positions.size() != 24:
		print("LRP_FULL_INCOMPLETE: engine did not classify all 24 cars")
		quit(1)
		return
	start=Time.get_ticks_usec()
	var exported: Dictionary=s.export_data()
	if exported.is_empty():
		report.error="Checkpoint export failed"
		write_report(report)
		quit(1)
		return
	var r=Replay.new()
	if not r.load_data(exported):
		report.error="Legacy-compatible replay import failed: "+r.error
		write_report(report)
		quit(1)
		return
	r.checkpoints=[r.checkpoints[0]]
	if not r.seek(0):
		report.error="Replay initial checkpoint cannot be restored: "+r.error
		write_report(report)
		quit(1)
		return
	while r.tick < s.tick:
		if not r.step_tick():
			report.error="Divergence: "+r.error
			break
		if r.tick%2000==0:
			print("LRP_FULL_REPLAY ",JSON.stringify({"ticks":r.tick,"target_ticks":s.tick,
				"elapsed_seconds":float(Time.get_ticks_usec()-start)/1000000.0}))
	report.replay_seconds=float(Time.get_ticks_usec()-start)/1000000.0
	report.replay_ticks=r.tick
	report.full_replay_verified=(r.tick==s.tick and r.first_divergence<0 and
		Codec.sporting_hash(engine,s.policy)==Codec.sporting_hash(r.race,r.policy) and
		r.racecraft_report().counts == report.racecraft_audit.counts and
		r.racecraft_report().drivers == report.racecraft_audit.drivers and
		Codec.digest(Codec.fields(engine.telemetry)) == Codec.digest(Codec.fields(r.race.telemetry)))
	write_report(report)
	print("LRP_FULL_REPLAY_END ",JSON.stringify({"verified":report.full_replay_verified,"ticks":r.tick,
		"seconds":report.replay_seconds,"hash":report.sport_hash,"error":str(report.get("error",""))}))
	quit(0 if report.full_replay_verified else 1)
