extends SceneTree
## Real rendered HUD states and spatial checks, using an isolated test user directory.
const OUTPUT := "res://qa/hud_manager_20261121/after"
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var failures: Array[String] = []
var captures: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		printerr("HUD_MANAGER_VISUAL_FAIL ", message)

func _settle() -> void:
	for _i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw

func _capture(name: String) -> void:
	await _settle()
	var picture: Image = root.get_texture().get_image()
	check(picture != null, "viewport image: " + name)
	if picture == null:
		return
	check(picture.save_png(OUTPUT + "/" + name + ".png") == OK, "save capture: " + name)
	captures.append({"name": name, "width": picture.get_width(), "height": picture.get_height()})

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.borderless = true
	root.size = Vector2i(1600, 900)
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await process_frame
	host.set_process(false)
	host.seed_picker.value = 660
	for i in range(host.season_tracks.size()):
		if str(host.season_tracks[i].get("code", "")) == "GBR":
			host.selected_track_index = i
			break
	host._start_race()
	var hud = host.race_hud_0620
	for _i in range(600):
		check(host.replay_session.step_tick(), "advance real simulation")
	host.race.running = false
	host._change_visual_setting(2)
	host._process(0.0)
	var reference: String = Codec.sporting_hash(host.race, host.replay_session.policy)
	for resolution in [Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(1366, 768)]:
		# Use fullscreen for the physical monitor size so the desktop window
		# manager does not shrink it to its usable work area.
		root.mode = Window.MODE_FULLSCREEN if resolution == Vector2i(1920, 1080) else Window.MODE_WINDOWED
		root.size = resolution
		await process_frame
		hud._change_hud_mode(1)
		host._layout_ui()
		hud.refresh_hud()
		await _settle()
		# Global Control rectangles use the logical canvas, while the PNG uses
		# physical pixels. The shipped project uses canvas_items stretching.
		var viewport_bounds: Rect2 = hud.get_viewport_rect()
		var rendered_size: Vector2i = root.get_texture().get_image().get_size()
		# At 1366x768 the 16:9 canvas rounds to 1365 rendered pixels.
		# Preserve the actual image; record its size rather than rescaling it.
		check(absi(rendered_size.x - resolution.x) <= 1 and rendered_size.y == resolution.y, "render resolution: " + str(resolution))
		for element in [hud.ranking, hud.weather_box, hud.map_box, hud.bottom_bar, hud.actions_top]:
			check(viewport_bounds.encloses(element.get_global_rect()), "HUD contained: " + str(resolution) + " " + str(element.get_global_rect()))
		for slot in range(2):
			var card: Dictionary = hud.race_card_panels[slot]
			check(viewport_bounds.encloses(card["base"].get_global_rect()), "driver contained: " + str(resolution))
			check(not card["base"].get_global_rect().intersects(hud.bottom_bar.get_global_rect()), "driver / transport separated")
		await _capture("race_%dx%d" % [resolution.x, resolution.y])
		# Exercise the bound buttons, rather than only calling the layout helper.
		for context in range(4):
			hud.race_card_panels[0]["tabs"][context].pressed.emit()
			await _settle()
			var detail: Control = hud.race_card_panels[0]["expanded"]
			check(detail.visible, "context opened by button")
			check(viewport_bounds.encloses(detail.get_global_rect()), "context contained: %s / %d" % [str(resolution), context])
			check(not detail.get_global_rect().intersects(hud.race_card_panels[0]["base"].get_global_rect()), "context / driver separated")
			if context == 2:
				await _capture("strategy_%dx%d" % [resolution.x, resolution.y])
			hud._collapse_driver(0)
		hud.race_card_panels[0]["tabs"][2].pressed.emit()
		hud.race_card_panels[1]["tabs"][2].pressed.emit()
		await _settle()
		var first_detail: Control = hud.race_card_panels[0]["expanded"]
		var second_detail: Control = hud.race_card_panels[1]["expanded"]
		check(not first_detail.visible or not first_detail.get_global_rect().intersects(second_detail.get_global_rect()), "two contexts do not overlap")
		hud._collapse_driver(0)
		hud._collapse_driver(1)
		check(Codec.sporting_hash(host.race, host.replay_session.policy) == reference, "presentation leaves sporting hash unchanged")
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 900)
	await process_frame
	hud._change_hud_mode(2)
	host._layout_ui()
	await _capture("full_1600x900")
	hud._open_window("radio")
	await _capture("radio_1600x900")
	hud._close_window()
	hud._change_hud_mode(1)
	var result: Dictionary = {"status": "PASS" if failures.is_empty() else "FAIL", "captures": captures, "issues": failures, "note": "Actual Godot OpenGL rendering; no FPS benchmark or full GP claim."}
	var file := FileAccess.open(OUTPUT + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	print("HUD_MANAGER_VISUAL ", JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
