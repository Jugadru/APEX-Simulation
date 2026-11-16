extends SceneTree
## Real Godot render, not an illustrative mock.
var failed := false
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.borderless = true
	root.size = Vector2i(1600, 900)
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for _i in range(3): await process_frame
	host.set_process(false)
	# Silverstone is chosen from the actual historical 2012 track roster.
	for i in range(host.season_tracks.size()):
		if str(host.season_tracks[i].get("code", "")) == "GBR":
			host.selected_track_index = i
			break
	host._start_race()
	host.race.running = false
	# Use the existing strategic map, without changing game state.
	host._change_visual_setting(1)
	var hud = host.race_hud_0620
	for resolution in [Vector2i(1600,900), Vector2i(1920,1080), Vector2i(1366,768)]:
		# Xvfb/llvmpipe trims a one-pixel X11 window border at 1366 px.
		root.size = resolution + (Vector2i(1,0) if resolution.x == 1366 else Vector2i.ZERO)
		await process_frame
		for mode in range(3):
			hud._change_hud_mode(mode)
			host._layout_ui()
			for _i in range(4): await process_frame
			await RenderingServer.frame_post_draw
			var photo: Image = root.get_texture().get_image()
			var actual: Vector2i = photo.get_size()
			var file: String = "res://qa/hud_rebroadcast_0668/%s_%dx%d.png" % [
				["broadcast","compact","full"][mode],actual.x,actual.y]
			if abs(actual.x-resolution.x)>1 or actual.y != resolution.y or photo.save_png(file) != OK:
				printerr("FAIL HUD_0668_GRAPHICS ",file," actual ",actual)
				failed = true
			elif actual != resolution:
				print("INCONCLUSIVE HUD_0668_EXACT_RESOLUTION requested=",resolution," actual=",actual," saved=",file)
			else:
				print("CAPTURE HUD_0668_REAL ",file)
	# One additional real 3D presentation capture at the standard 1x speed.
	root.size = Vector2i(1600, 900)
	hud._change_hud_mode(1)
	host._change_visual_setting(0)
	host._layout_ui()
	for _i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	var image3d: Image = root.get_texture().get_image()
	var capture_3d: String = "res://qa/hud_rebroadcast_0668/compact_3d_1600x900.png"
	if host.render_mode != 1 or image3d.get_size() != Vector2i(1600,900) or image3d.save_png(capture_3d) != OK:
		printerr("FAIL HUD_0668_3D_VIEW")
		failed = true
	else:
		print("CAPTURE HUD_0668_REAL_3D ",capture_3d)
	print("HUD_REBROADCAST_0668_GRAPHICS_", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
