extends SceneTree
# 0665 full-distance sporting integrity and sparse checkpoint seek.
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const EXPECTED := "2a7e27179177858b8754a0c65666b325499e4aa13d423de060181b11d9ae1c4b"
func _initialize() -> void: call_deferred("run")
func write_result(result: Dictionary) -> void:
	var fp := FileAccess.open("res://qa/replay_checkpoints_0665/monza_53_validation.json",FileAccess.WRITE)
	assert(fp != null)
	fp.store_string(JSON.stringify(result,"  "))
	fp.close()
func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for entry in data.tracks:
		if str(entry.code) == "ITA": track = entry.duplicate(true)
	assert(int(track.laps) == 53)
	var engine=Race.new(data.teams,"Ferrari",660,{},track,{})
	engine.configure_weather("Seco")
	var id:int=int(engine.player_cars()[0].id)
	var other:int=int(engine.player_cars()[1].id)
	engine.pit_incident_test_overrides[id]={"service_fault":"Porca travada","service_delay":4.0,"release_delay":4.5}
	var s=Replay.new()
	s.attach(engine,{id:"Assistido",other:"Automático"},{"Engenheiro":2,"Estrategista":2})
	var compound:String=engine.available_pit_compounds()[0]
	assert(s.enqueue("order_pit",[id,compound],3))
	assert(s.enqueue("order_pit",[other,compound],3))
	var started:int=Time.get_ticks_usec()
	var report: Dictionary={"track":"ITA","laps":53,"weather":"Seco","seed":660,
		"passed":false,"mode":"record full GP; seek historic positions; archival compatibility",
		"expected_sport_hash":EXPECTED}
	while not engine.finished and s.tick < 160000:
		assert(s.step_tick(),s.error)
		if s.tick%4000==0:
			print("CHECKPOINT_0665_FULL_PROGRESS ",JSON.stringify({"tick":s.tick,
				"leader_lap":engine.lap,"elapsed_seconds":float(Time.get_ticks_usec()-started)/1000000.0,
				"checkpoints":s.checkpoints.size()}))
	report.record_seconds=float(Time.get_ticks_usec()-started)/1000000.0
	report.ticks=s.tick
	report.finished=engine.finished
	report.hash=str(s.hashes[-1])
	report.pit_stops=engine.pit_history.size()
	report.racecraft=s.racecraft_report()
	var positions: Dictionary={}
	var classified:int=0
	for car in engine.get_sorted():
		if bool(car.finished):classified+=1
		positions[int(car.position)]=true
	report.classified=classified
	report.unique_positions=positions.size()
	var anchors:Array=[]
	for cp in s.checkpoints:anchors.append(int(cp.tick))
	report.checkpoints=anchors
	report.checkpoint_limit=len(s.checkpoints)<=9
	write_result(report)
	assert(s.tick == 24431 and engine.finished and report.hash==EXPECTED)
	assert(classified==24 and positions.size()==24 and s.checkpoints.size()<=9)
	assert(anchors[0] == 0 and anchors[-1] == 24300)
	var max_gap: int = 0
	for j in range(1, anchors.size()):
		max_gap = maxi(max_gap, int(anchors[j]) - int(anchors[j-1]))
	report.maximum_checkpoint_gap_ticks = max_gap
	assert(max_gap <= 4800)
	var replay=Replay.new()
	assert(replay.load_live_session(s),replay.error)
	var seeks: Array=[]
	for wanted in [10000,20000,24431]:
		started=Time.get_ticks_usec()
		assert(replay.seek(wanted),replay.error)
		assert(Codec.sporting_hash(replay.race,replay.policy)==s.hashes[wanted-1])
		seeks.append({"tick":wanted,"seconds":float(Time.get_ticks_usec()-started)/1000000.0,
			"hash_match":true})
	report.seeks=seeks
	var path: String="user://APEX_0665_MONZA53.apexreplay"
	started=Time.get_ticks_usec()
	assert(s.save_file(path),s.error)
	report.save_seconds=float(Time.get_ticks_usec()-started)/1000000.0
	var f=FileAccess.open(path,FileAccess.READ)
	assert(f != null)
	report.archive_bytes=f.get_length()
	f.close()
	started=Time.get_ticks_usec()
	var old_reader=Replay.new()
	assert(old_reader.load_file(path),old_reader.error)
	report.load_seconds=float(Time.get_ticks_usec()-started)/1000000.0
	assert(old_reader.seek(24431),old_reader.error)
	assert(Codec.sporting_hash(old_reader.race,old_reader.policy)==report.hash)
	report.full_replay_tick_by_tick="NÃO EXECUTADO (seek validado nos alvos e hash final)"
	report.passed=true
	write_result(report)
	print("CHECKPOINT_0665_FULL_PASS ",JSON.stringify({"ticks":s.tick,"hash":report.hash,
		"checkpoints":anchors,"seeks":seeks,"archive_bytes":report.archive_bytes,
		"save_s":report.save_seconds,"load_s":report.load_seconds}))
	quit()
