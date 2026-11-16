extends SceneTree
const Race=preload("res://scripts/race_engine.gd")
const R=preload("res://scripts/core/race_replay_0660.gd")
const C=preload("res://scripts/core/race_state_codec_0660.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track:Dictionary=data.tracks[0].duplicate(true);track.laps=52
	var engine=Race.new(data.teams,"Ferrari",660,{},track,{})
	engine.configure_weather("Chuva intensa")
	for car in engine.cars:car.progress=3.7;car.laps_done=3
	engine.lap=4
	var id:int=engine.player_cars()[0].id
	var s=R.new();s.attach(engine,{id:"Automático"})
	assert(s.enqueue("schedule_pit",[id,"Chuva",21],1))
	assert(s.enqueue("set_pace",[id,"Atacar"],5))
	assert(s.enqueue("set_pace",[id,"Conservar"],5))
	for i in range(350):assert(s.step_tick())
	var player:Dictionary=engine.player_cars()[0]
	assert(player.pit_scheduled_lap==21 and not player.pit_request and player.stops==0,"manual V21 cannot become V4 rain call")
	var r=R.new();assert(r.load_data(s.export_data()));assert(r.seek(350),r.error)
	var cases:Array=[]
	var bad:Dictionary=s.export_data();bad.checkpoints[0].state.rng={};cases.append(bad)
	bad=s.export_data();bad.commands[0].payload=[];cases.append(bad)
	bad=s.export_data();bad.commands[0].payload[0]="wrong";cases.append(bad)
	bad=s.export_data();bad.checkpoints[0].cursor=1;cases.append(bad)
	bad=s.export_data();bad.checkpoints[0].state.engine.cars=[];cases.append(bad)
	bad=s.export_data();bad.step=.5;cases.append(bad)
	bad=s.export_data();bad.checkpoints[0].policy.staff="bad";cases.append(bad)
	for c in cases:
		var invalid=R.new();assert(not invalid.load_data(c));assert(invalid.race==null)
	# Checkpoint validation, including exact seek to a corrupted checkpoint.
	bad=s.export_data();bad.checkpoints[-1].state.engine.cars[0].wear+=1.0
	var corrupt=R.new();assert(corrupt.load_data(bad));assert(not corrupt.seek(300))
	assert(C.digest(C.canonical({"b":2,"a":1}))==C.digest(C.canonical({"a":1,"b":2})))
	print("REPLAY_BOUNDARIES_PASS V21/rain V4, same-tick ordering, invalid data and checkpoint integrity")
	quit()
