extends SceneTree
const Motion = preload("res://tests/legacy/apex_battle_motion_0652.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1600,900)
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(8): await process_frame
	for i in range(host.season_tracks.size()):
		if host.season_tracks[i].code == "GBR": host.selected_track_index = i
	host._start_race()
	host.set_process(false)
	host.race.running = true
	var focus := -1
	for tick in range(200):
		host.race.step(4.0)
		var copy: Array = host.race.cars.duplicate(true)
		for car in copy:
			car.route_point = host.map_view.point_on_track(car.progress)
			car.route_direction = host.map_view.direction_on_track(car.progress)
		var lanes := Motion.targets(copy)
		for car in copy:
			if absf(float(car.get("race_lane",0)))>2.0 and car.combat_state in ["attacking","duel"]:
				focus = int(car.id)
				break
		if focus >= 0: break
	assert(focus >= 0,"real attack found")
	host.race.running = false
	host.manual_driver = focus
	host.camera_mode = "Seguir piloto"
	host.tv_shot_override = "battle"
	host.world_view.occupation.clear()
	host._process(0.0)
	for resolution in [Vector2i(1600,900),Vector2i(1920,1080)]:
		root.mode = Window.MODE_FULLSCREEN if resolution.x == 1920 else Window.MODE_WINDOWED
		root.size = resolution
		host._layout_ui()
		for i in range(12): await process_frame
		host._process(0.0)
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		assert(img.get_size()==resolution)
		img.save_png("res://qa/sim_racecraft/race_%dx%d.png" % [resolution.x,resolution.y])
	print("SIMULATION_HUD_PASS actual attack id=",focus," time=",host.race.clock," native 1600x900 + 1920x1080")
	quit(0)
