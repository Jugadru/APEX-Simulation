extends SceneTree
const P=preload("res://scripts/debug/apex_perf_trace_0657.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await process_frame
	host.set_process(false)
	host.seed_picker.value=6558
	host._start_race()
	host.render_mode=1
	host.race.running=true
	for i in range(20):host._process(1.0/60)
	host.race.running=false
	var sporting:=JSON.stringify(host.race.cars)
	var rng_state:int=host.race.rng.state
	host._process(1.0/60)
	P.set_enabled(true)
	P.reset()
	for i in range(10):host._process(1.0/60)
	assert(not P.snapshot().sections.has("visual.world_3d"),"paused 3D must not rebuild")
	assert(JSON.stringify(host.race.cars)==sporting and host.race.rng.state==rng_state)
	host.camera_mode="Seguir piloto"
	host.manual_driver=int(host.race.player_cars()[1].id)
	host._process(1.0/60)
	assert(P.snapshot().sections.has("visual.world_3d"),"selection refresh")
	var map=host.map_view
	map.hide()
	var old=map.cars
	host.race.running=true
	host._process(1.0/60)
	assert(map.cars==old,"hidden map retains previous state")
	map.show()
	host._process(1.0/60)
	assert(map.cars==host.presentation.frames,"reentry catches up")
	assert(host.presentation.frames.size()==24)
	for car in host.presentation.frames:
		for value in car.values():assert(not value is Array and not value is Dictionary and not value is Object)
	P.set_enabled(false)
	print("VIEW_INTEGRATION_PASS pause, focus, hidden/reentry, 24 compact cars, engine/RNG unchanged")
	quit()
