extends SceneTree
## Make three native screenshots. Reads env APEX_CAPTURE_CIRCUIT.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await process_frame
	var requested: String = OS.get_environment("APEX_CAPTURE_CIRCUIT")
	if requested.is_empty():
		requested = "Bahrain"
	for i in range(host.season_tracks.size()):
		var name: String = str(host.season_tracks[i].get("name", ""))
		if requested.to_lower() in name.to_lower():
			host.selected_track_index = i
			break
	host._start_race()
	await process_frame
	host._change_camera_mode(0)
	host.visual_setting = 2
	host._apply_visual_from_setting()
	host.world_view.set_zoom(0.70)
	host.world_view.center_track()
	await process_frame
	await RenderingServer.frame_post_draw
	var screen_image: Image = root.get_texture().get_image()
	var dest: String = "/mnt/data/apex_0629_preview_" + requested.to_lower().replace(" ", "_") + ".png"
	var result: Error = screen_image.save_png(dest)
	print("APEX_0629_CAPTURE: ", result, " ", requested, " ", screen_image.get_size(), " ", dest)
	quit(0 if result == OK else 1)
