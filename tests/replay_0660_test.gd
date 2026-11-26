extends SceneTree
const Race=preload("res://scripts/race_engine.gd")
const Replay=preload("res://scripts/core/race_replay_0660.gd")
const Codec=preload("res://scripts/core/race_state_codec_0660.gd")
const ViewController=preload("res://scripts/apex_race_view_controller.gd")

# Exercise the actual speed controller without creating a graphics viewport.
class SpeedHost:
	var race
	var replay_session
	var sim_speed: float = 32.0
	var effective_speed_x: float = 14.0
	var effective_speed_elapsed: float = 0.5
	var effective_speed_ticks: int = 35
	var visual_setting: int = 1
	var speed_picker = null

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
	# Both decoded and legacy checkpoint exports must be detached from the recorder.
	var packed: Dictionary=s._packed_checkpoint(cp)
	assert(packed.has("packed_state"))
	s.checkpoints.append(packed)
	var exported: Array=s._export_checkpoints()
	var expected: String=Codec.digest(cp.state)
	assert(Codec.digest(exported[-1].state)==expected)
	exported[-1].state.engine.cars[0].wear=-123.0
	exported[0].state.engine.cars[0].wear=-123.0
	assert(Codec.digest(s._checkpoint_state(packed))==expected)
	assert(float(s._checkpoint_state(s.checkpoints[0]).engine.cars[0].wear)!=-123.0)
	s.checkpoints.pop_back()
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
	for speed in [1.0,2.0,5.0,10.0,16.0,32.0]:
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
			var cap: int=Replay.interactive_backlog_steps(speed)
			a.advance(maxf(0,dt),speed,observe,0,cap)
			if frames%17==0:
				a.race.running=false;var tick:int=a.tick;a.advance(2,32);assert(a.tick==tick)
			frames+=1;assert(frames<10000)
		assert(a.hashes==s.hashes,"FPS/speed deterministic")
		assert(observations[0]==200)
		var km:Array=[inventory.parts.one.km,inventory.parts.two.km,inventory.parts.one.history[-1].km,inventory.parts.two.history[-1].km]
		if expected_km.is_empty():expected_km=km
		else:assert(km==expected_km,"inventory distances independent of FPS/speed")
	# Exercise saturation without relying on host wall-clock performance.
	for speed in [10.0,16.0,32.0]:
		var bounded=make_session()
		bounded.race.running=true
		var cap: int=Replay.interactive_backlog_steps(speed)
		assert(cap=={10.0:6,16.0:8,32.0:12}[speed])
		assert(bounded.advance(10.0,speed,Callable(),0,cap)==cap)
		assert(bounded.cpu_limited and bounded.accumulator<Replay.STEP)
		var reference=make_session()
		for i in range(cap):assert(reference.step_tick())
		assert(bounded.hashes==reference.hashes,"bounded scheduler cannot skip sporting ticks")
	var backlog=make_session();backlog.race.running=true;backlog.advance(1,32)
	assert(backlog.tick==16 and backlog.accumulator>20)
	while backlog.accumulator>=Replay.STEP-0.00000001:backlog.advance(0,1)
	assert(backlog.tick==160)
	# Explicit speed reduction must not spend old whole-tick wall-clock debt.
	# Set a deterministic saturated accumulator without depending on CPU speed.
	var transition=make_session()
	var reference=make_session()
	var actor:int=transition.race.player_cars()[0].id
	assert(transition.enqueue("schedule_pit",[actor,"Chuva",2],1))
	assert(reference.enqueue("schedule_pit",[actor,"Chuva",2],1))
	transition.race.running=true
	reference.race.running=true
	assert(transition.step_tick() and reference.step_tick())
	transition.accumulator=2.47
	transition.cpu_limited=true
	var host=SpeedHost.new()
	host.race=transition.race
	host.replay_session=transition
	var hash_before:String=Codec.sporting_hash(transition.race,transition.policy)
	var rng_before:int=transition.race.rng.state
	var tick_before:int=transition.tick
	var commands_before:Array=transition.commands.duplicate(true)
	var hashes_before:PackedStringArray=transition.hashes.duplicate()
	ViewController._change_speed(host,0)
	assert(host.sim_speed==1.0 and host.effective_speed_x==0.0)
	assert(is_equal_approx(transition.accumulator,0.07) and not transition.cpu_limited,"downshift rebases only old wall-clock debt")
	assert(transition.tick==tick_before and transition.race.rng.state==rng_before)
	assert(Codec.sporting_hash(transition.race,transition.policy)==hash_before and transition.commands==commands_before and transition.hashes==hashes_before)
	assert(transition.advance(0.0,1.0)==0,"no old accelerated ticks after downshift")
	assert(transition.advance(0.12,1.0)==0)
	assert(transition.advance(0.01,1.0)==1)
	assert(reference.step_tick())
	assert(transition.hashes==reference.hashes and transition.race.rng.state==reference.race.rng.state,"next sporting tick remains exact")
	# Re-select and upshift retain phase/backlog. Fast-to-fast reduction also rebases.
	transition.accumulator=1.25
	ViewController._change_speed(host,0)
	assert(is_equal_approx(transition.accumulator,1.25))
	ViewController._change_speed(host,5)
	assert(is_equal_approx(transition.accumulator,1.25))
	transition.race.running=false
	ViewController._change_speed(host,4)
	assert(is_equal_approx(transition.accumulator,0.05))
	assert(transition.advance(1.0,16.0)==0 and transition.tick==2,"paused change never advances race")
	transition.accumulator=0.6
	transition.rebase_interactive_speed(16.0,1.0)
	assert(is_zero_approx(transition.accumulator),"exact step boundary")
	var output:Dictionary={"pass":true,"ticks":200,"speeds":[1,2,5,10,16,32],"wall_s":(Time.get_ticks_usec()-start)/1000000.0,"checkpoint_bytes":var_to_bytes(cp).size(),"replay_bytes":var_to_bytes(s.export_data()).size()}
	FileAccess.open("res://qa/replay_0660/unit.json",FileAccess.WRITE).store_string(JSON.stringify(output))
	print("REPLAY_UNIT_PASS ",output)
	quit()
