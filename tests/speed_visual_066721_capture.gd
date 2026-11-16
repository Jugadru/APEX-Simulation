extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(filename: String, dimensions: Vector2i) -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = dimensions
	for frame in range(10): await process_frame
	await RenderingServer.frame_post_draw
	var screenshot: Image = root.get_texture().get_image()
	assert(screenshot.get_width()==dimensions.x and screenshot.get_height()==dimensions.y)
	assert(screenshot.save_png("res://qa/speed_visual_066721/"+filename+".png") == OK)
	print("SPEED_VISUAL_066721_CAPTURE_PASS ",filename," size=",dimensions)
func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600,900)
	var hud = load("res://scenes/main.tscn").instantiate()
	root.add_child(hud)
	for frame in range(12): await process_frame
	hud.set_process(false)
	for index in range(hud.season_tracks.size()):
		if hud.season_tracks[index].code == "GBR": hud.selected_track_index = index
	hud.seed_picker.value = 661
	hud._start_race()
	assert(is_equal_approx(hud.sim_speed,1.0))
	assert(hud.race_hud_0620.speed_label.selected == 0)
	hud.race.running = true
	for frame in range(120): hud._process(1.0/60.0)
	hud.race.running = false
	hud._process(1.0/60.0)
	await capture("race_1x_1600x900",Vector2i(1600,900))
	hud._change_speed(2)
	hud.race.running = true
	for frame in range(160): hud._process(1.0/60.0)
	hud.race.running = false
	hud._process(1.0/60.0)
	assert(hud.render_mode == 1)
	assert(hud.race_hud_0620.speed_label.selected == 2)
	await capture("race_5x_1920x1080",Vector2i(1920,1080))
	print("SPEED_VISUAL_066721_REAL_UI_PASS")
	quit(0)
