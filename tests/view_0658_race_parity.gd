extends SceneTree
## Also runs against the uninstrumented base via --script /absolute/path/to/this.gd.
const Race = preload("res://scripts/race_engine.gd")
func _initialize()->void: call_deferred("run")
func run()->void:
	var weather_mode:=OS.get_environment("APEX_BENCH_WEATHER")
	if weather_mode.is_empty(): weather_mode="Seco"
	var enabled:=OS.get_environment("APEX_BENCH_ON")=="1"
	var profiler = load("res://scripts/debug/apex_perf_trace_0657.gd") if FileAccess.file_exists("res://scripts/debug/apex_perf_trace_0657.gd") else null
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track_code:=OS.get_environment("APEX_BENCH_TRACK")
	if track_code.is_empty():track_code="GBR"
	var track:Dictionary={}
	for t in data.tracks:
		if t.code==track_code:track=t.duplicate(true)
	track.laps=3
	var race=Race.new(data.teams,"Ferrari",6557,{},track,{})
	race.configure_weather(weather_mode)
	race.pit_incidents_enabled=false
	assert(race.cars.size()==24)
	for car in race.player_cars():race.order_pit(int(car.id),"Chuva" if weather_mode=="Chuva intensa" else race.available_pit_compounds()[0])
	race.running=true
	# Warm-up is identical in all modes, excluded from timings.
	race.step(4.0)
	race.step(4.0)
	if profiler!=null:
		profiler.set_enabled(enabled)
		profiler.reset({"seed":6557,"track":track_code,"laps":3,"weather":weather_mode,"cars":24,"warmup_sim_seconds":8})
	var start:=Time.get_ticks_usec()
	var previous:Dictionary={}
	var ticks:=0
	while not race.finished and ticks<700:
		for car in race.cars: previous[int(car.id)]=float(car.progress)
		race.step(4.0)
		for car in race.cars: assert(float(car.progress)>=float(previous[int(car.id)])-0.000001)
		ticks+=1
	var wall:float=float(Time.get_ticks_usec()-start)/1000000.0
	assert(race.finished)
	var positions:Dictionary={}
	for car in race.cars:
		assert(car.finished)
		assert(not positions.has(car.position))
		positions[car.position]=true
		assert(float(car.best_lap)>0 and is_finite(float(car.best_lap)))
		assert(float(car.last_lap)>0 and int(car.laps_done)>0)
	assert(race.get_pit_history().size()>=2)
	if profiler!=null:profiler.set_enabled(false)
	var sporting:Dictionary={"clock":race.clock,"cars":race.cars,"events":race.events,"pits":race.get_pit_history()}
	var output:Dictionary={"seed":6557,"laps":3,"weather":weather_mode,"cars":24,"wall_seconds":wall,"sim_seconds":race.clock-8,"sim_per_wall":(race.clock-8)/wall,"state_sha256":JSON.stringify(sporting).sha256_text(),"state":sporting,"profiler_on":enabled,"profile":profiler.snapshot() if profiler!=null else {},"cpu":OS.get_processor_name(),"godot":Engine.get_version_info().string}
	var path:=OS.get_environment("APEX_BENCH_OUTPUT")
	if path.is_empty():path="user://perf_0657_cpu.json"
	var f:=FileAccess.open(path,FileAccess.WRITE)
	assert(f!=null)
	f.store_string(JSON.stringify(output))
	print("PERF_CPU_PASS ",weather_mode," on=",enabled," sim_s=",race.clock-8," wall_s=",wall," hash=",output.state_sha256)
	quit()
