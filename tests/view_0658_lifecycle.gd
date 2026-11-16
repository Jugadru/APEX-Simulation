extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await process_frame
	host.set_process(false)
	host._start_race()
	host.race.running=false
	host._process(1.0/60)
	await process_frame
	var models:int=host.world_view.live_cars.size()
	var node_count:int=int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for i in range(12):
		host.visual_setting=1
		host._apply_visual_from_setting()
		host._process(1.0/60)
		assert(host.map_view.cars==host.presentation.frames)
		host.visual_setting=2
		host._apply_visual_from_setting()
		host._process(1.0/60)
		await process_frame
	assert(host.world_view.live_cars.size()==models)
	assert(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))==node_count)
	var old_race=host.race
	host._end_to_menu()
	host.seed_picker.value=1234
	host._start_race()
	host._process(1.0/60)
	assert(host.presentation_race==host.race and host.race!=old_race)
	for frame in host.presentation.frames:
		assert(frame.progress==host._car_by_id(int(frame.id)).progress)
	print("VIEW_LIFECYCLE_PASS 12 map/3D switches, stable node count, session cache reset")
	quit()
