extends SceneTree
const Race=preload("res://scripts/race_engine.gd")
const R=preload("res://scripts/core/race_replay_0660.gd")
const C=preload("res://scripts/core/race_state_codec_0660.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var code:=OS.get_environment("APEX_TRACK");if code.is_empty():code="GBR"
	var mode:=OS.get_environment("APEX_WEATHER");if mode.is_empty():mode="Seco"
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track:Dictionary={}
	for t in data.tracks:
		if t.code==code:track=t.duplicate(true)
	if OS.get_environment("APEX_FULL")!="1":track.laps=3
	var engine=Race.new(data.teams,"Ferrari",660,{},track,{})
	engine.configure_weather(mode)
	# Explicit pit repair/queue fixture, real race from grid.
	var id:int=engine.player_cars()[0].id
	var other:int=engine.player_cars()[1].id
	engine.pit_incident_test_overrides[id]={"service_fault":"Porca travada","service_delay":4.0,"release_delay":4.5}
	var s=R.new();s.attach(engine,{id:"Assistido",other:"Automático"},{"Engenheiro":2,"Estrategista":2})
	var compound:String="Chuva" if mode=="Chuva intensa" else engine.available_pit_compounds()[0]
	assert(s.enqueue("order_pit",[id,compound],3));assert(s.enqueue("order_pit",[other,compound],3))
	var snapshots:Array=[];var seen:Dictionary={};var start:=Time.get_ticks_usec()
	while not engine.finished and s.tick<60000:
		assert(s.step_tick())
		for car in engine.player_cars():
			var phase:String=str(car.get("pit_stage",""))
			if float(car.pit_left)>0 and not seen.has(phase):seen[phase]=true;snapshots.append(s.checkpoint())
	assert(engine.finished)
	var order:Array=engine.get_sorted();var ranks:Dictionary={}
	for car in order:assert(car.finished and not ranks.has(car.position));ranks[car.position]=true
	assert(engine.pit_history.size()>=2)
	var live_ms:float=(Time.get_ticks_usec()-start)/1000.0
	var r=R.new();assert(r.load_data(s.export_data()),r.error)
	# Force replay from initial checkpoint to test every recorded tick, not just tail.
	r.checkpoints=[r.checkpoints[0]]
	start=Time.get_ticks_usec();assert(r.seek(s.tick),r.error)
	assert(C.sporting_hash(engine,s.policy)==C.sporting_hash(r.race,r.policy))
	assert(C.digest(C.fields(engine.telemetry))==C.digest(C.fields(r.race.telemetry)))
	var replay_ms:float=(Time.get_ticks_usec()-start)/1000.0
	for cp in snapshots:
		var branch=R.new();assert(branch.load_data(s.export_data()))
		branch.checkpoints=[branch.checkpoints[0],cp]
		assert(branch.seek(mini(s.tick,int(cp.tick)+50)),branch.error)
	var out:Dictionary={"track":code,"weather":mode,"laps":track.laps,"ticks":s.tick,"live_ms":live_ms,"replay_ms":replay_ms,"bytes":var_to_bytes(s.export_data()).size(),"pit_phases":seen.keys(),"pit_checkpoint_count":snapshots.size(),"hash":s.hashes[-1],"pass":true}
	FileAccess.open("res://qa/replay_0660/gp_"+code+"_"+mode+".json",FileAccess.WRITE).store_string(JSON.stringify(out))
	print("REPLAY_GP_PASS ",out);quit()
