extends SceneTree
const Race=preload("res://scripts/race_engine.gd")
const Replay=preload("res://scripts/core/race_replay_0660.gd")
const Codec=preload("res://scripts/core/race_state_codec_0660.gd")
func _initialize()->void:call_deferred("run")
func make_session():
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track:Dictionary=data.tracks[0].duplicate(true)
	if OS.get_environment("APEX_FAST_LAB") == "1":
		# Automatic FAST executes replay sporting ticks on the synthetic lab.
		var lab:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/apex_lab_track.json"))
		assert(lab is Dictionary and str(lab.get("code",""))=="LAB","FAST requires the real lab fixture")
		track=lab.duplicate(true)
	else:
		# Explicit on-demand FULL preserves the real Silverstone scenario.
		for t in data.tracks:
			if t.code=="GBR":track=t.duplicate(true)
	track.laps=3
	var race=Race.new(data.teams,"Ferrari",660,{},track,{})
	race.configure_weather("Chuva intensa")
	var replay=Replay.new();replay.attach(race)
	return replay
func run()->void:
	var s=make_session()
	var id:int=s.race.player_cars()[0].id
	var other:int=s.race.player_cars()[1].id
	assert(s.enqueue("set_pace",[id,"Atacar"],3))
	assert(s.enqueue("schedule_pit",[id,"Chuva",2],4))
	assert(s.enqueue("order_pit",[other,"Chuva"],5))
	assert(not s.enqueue("set_pace",[9999,"Atacar"]))
	assert(not s.enqueue("set_pace",[id,"INVALID"]))
	var start:=Time.get_ticks_usec()
	for i in range(200):assert(s.step_tick())
	var cp:Dictionary=s.checkpoint()
	var restored=Codec.restore(cp.state)
	assert(restored!=null)
	assert(Codec.digest(Codec.capture(restored))==Codec.digest(cp.state),"exact checkpoint roundtrip")
	assert(restored.rng.state==s.race.rng.state)
	restored.cars[0].wear=0
	assert(s.race.cars[0].wear!=0,"detached snapshot")
	var r=Replay.new();assert(r.load_data(s.export_data()),r.error)
	assert(r.seek(200),r.error)
	assert(Codec.sporting_hash(r.race,r.policy)==s.hashes[-1])
	assert(Codec.digest(Codec.fields(r.race.telemetry))==Codec.digest(Codec.fields(s.race.telemetry)))
	assert(r.seek(0));assert(r.seek(77));assert(r.seek(200))
	assert(s.save_file("user://test.apexreplay"))
	var loaded=Replay.new();assert(loaded.load_file("user://test.apexreplay"),loaded.error);assert(loaded.seek(200),loaded.error)
	var corrupt:Dictionary=s.export_data();corrupt.format="bad";assert(not Replay.new().load_data(corrupt))
	corrupt=s.export_data();corrupt.hashes[17]="tampered"
	var diverged=Replay.new();assert(diverged.load_data(corrupt));assert(not diverged.seek(30));assert(diverged.first_divergence==18)
	# Same ticks and commands across FPS/speeds, including pause and retained backlog.
	var expected_km: Array = []
	for speed in [1.0,2.0,5.0,16.0,32.0]:
		var a=make_session();a.commands=s.commands.duplicate(true)
		var inventory: Dictionary = {"parts":{"one":{"status":"installed","car":1,"km":0.0,"history":[]},"two":{"status":"installed","car":2,"km":0.0,"history":[]}},"sessions":{}}
		var observations: Array = [0]
		var observe: Callable = func(engine):
			observations[0]+=1
			preload("res://scripts/core/component_inventory_0651.gd").observe(inventory,"fixture",engine,{})
		var frames:=0
		while a.tick<200:
			a.race.running=true
			var dt:float=[1.0/30,1.0/60,1.0/144,0.003][frames%4]
			dt=minf(dt,(200-a.tick)*Replay.STEP/speed-a.accumulator/speed)
			a.advance(maxf(0,dt),speed,observe)
			if frames%17==0:
				a.race.running=false;var tick:int=a.tick;a.advance(2,32);assert(a.tick==tick)
			frames+=1;assert(frames<10000)
		assert(a.hashes==s.hashes,"FPS/speed deterministic")
		assert(observations[0]==200)
		var km:Array=[inventory.parts.one.km,inventory.parts.two.km,inventory.parts.one.history[-1].km,inventory.parts.two.history[-1].km]
		if expected_km.is_empty():expected_km=km
		else:assert(km==expected_km,"inventory distances independent of FPS/speed")
	var backlog=make_session();backlog.race.running=true;backlog.advance(1,32)
	assert(backlog.tick==16 and backlog.accumulator>20)
	while backlog.accumulator>=Replay.STEP-0.00000001:backlog.advance(0,1)
	assert(backlog.tick==160)
	var output:Dictionary={"pass":true,"ticks":200,"speeds":[1,2,5,16,32],"wall_s":(Time.get_ticks_usec()-start)/1000000.0,"checkpoint_bytes":var_to_bytes(cp).size(),"replay_bytes":var_to_bytes(s.export_data()).size()}
	FileAccess.open("res://qa/replay_0660/unit.json",FileAccess.WRITE).store_string(JSON.stringify(output))
	print("REPLAY_UNIT_PASS ",output)
	quit()
