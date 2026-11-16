extends SceneTree
# 0665 UI snapshot of an actual Godot race state (not mockup/render).
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w: int = int(OS.get_environment("APEX_VIEW_WIDTH"))
	var h: int = int(OS.get_environment("APEX_VIEW_HEIGHT"))
	if w < 800: w=1600
	if h < 500: h=900
	var dimensions := Vector2i(w,h)
	root.mode=Window.MODE_WINDOWED
	root.size=dimensions
	var hud = load("res://scenes/main.tscn").instantiate()
	root.add_child(hud)
	for i in range(10): await process_frame
	hud.set_process(false)
	for i in range(hud.season_tracks.size()):
		if hud.season_tracks[i].code=="GBR": hud.selected_track_index=i
	hud.seed_picker.value=661
	hud._start_race()
	hud.race.running=true
	hud.sim_speed=1
	for i in range(220): hud._process(1.0/60.0)
	hud.race.running=false
	hud._process(1.0/60.0)
	for i in range(18): await process_frame
	await RenderingServer.frame_post_draw
	var img: Image=root.get_texture().get_image()
	assert(img != null and img.get_width()==w and img.get_height()==h,"Godot viewport size mismatch")
	var path: String="res://qa/replay_checkpoints_0665/godot_race_%dx%d.png" % [w,h]
	assert(img.save_png(path)==OK,"Cannot save native Godot capture")
	print("REPLAY_CHECKPOINTS_VISUAL_0665_PASS ",w,"x",h," image=",path)
	quit()
