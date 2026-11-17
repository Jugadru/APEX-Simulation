extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String, resolution: Vector2i) -> void:
	root.size = resolution
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	var frame: Image = root.get_texture().get_image()
	assert(frame != null and frame.get_width() == resolution.x and frame.get_height() == resolution.y)
	assert(frame.save_png("res://qa/strategic_2d_066722/"+name+".png") == OK)
	print("STRATEGIC_2D_CAPTURE_PASS ", name, " ", resolution)
func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600,900)
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(10): await process_frame
	host.set_process(false)
	for k in range(host.season_tracks.size()):
		if str(host.season_tracks[k].code) == "GBR": host.selected_track_index = k
	host._start_race()
	host.race.running = true
	host._change_speed(3)
	assert(host.render_mode == 0 and host.map_view.visible)
	for i in range(25): host._process(1.0/60.0)
	host.race.running = false
	host._process(1.0/60.0)
	await capture("map_10x_1600x900",Vector2i(1600,900))
	host.race.running = true
	host._change_speed(5)
	for i in range(18): host._process(1.0/60.0)
	host.race.running = false
	host._process(1.0/60.0)
	assert(host.render_mode == 0 and not host.world_container.visible)
	await capture("map_32x_1920x1080",Vector2i(1920,1080))
	print("STRATEGIC_2D_066722_UI_PASS")
	quit(0)
