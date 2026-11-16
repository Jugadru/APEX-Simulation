extends SceneTree
func _initialize()->void:call_deferred("run")
func capture(name:String, size: Vector2i) -> void:
	root.mode=Window.MODE_WINDOWED
	root.size=size
	for i in range(15):await process_frame
	await RenderingServer.frame_post_draw
	var img:Image=root.get_texture().get_image()
	assert(img!=null and img.get_width()==size.x and img.get_height()==size.y,"Viewport image wrong size")
	assert(img.save_png("res://qa/racecraft_0662/"+name+".png")==OK,"Capture failed")
	print("RACECRAFT_VISUAL_CAPTURE ",name," ",img.get_width(),"x",img.get_height())
func run()->void:
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1600,900)
	var hud=load("res://scenes/main.tscn").instantiate()
	root.add_child(hud)
	for i in range(10):await process_frame
	hud.set_process(false)
	for i in range(hud.season_tracks.size()):
		if hud.season_tracks[i].code=="GBR":hud.selected_track_index=i
	hud.seed_picker.value=661
	hud._start_race()
	hud.race.running=true
	hud.sim_speed=1
	for i in range(220):hud._process(1.0/60.0)
	hud.race.running=false
	hud._process(1.0/60.0)
	## The 1600x900 capture is generated in a separate QA invocation.
	await capture("race_1920x1080",Vector2i(1920,1080))
	print("RACECRAFT_VISUAL_0662_PASS real Godot UI / circuit")
	quit()
