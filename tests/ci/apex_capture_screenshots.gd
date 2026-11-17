extends SceneTree
## CI screenshot fixture: real 2012 APEX UI, Silverstone/24 cars/seed 660.
## Does NOT alter race logic or write to player saves.

const OUTPUT_DIR := "res://ci_artifacts/screenshots"
const RESOLUTION := Vector2i(1600, 900)

var captures: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	printerr("APEX_CAPTURE_CI_FAIL ", message)
	quit(1)


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.borderless = true
	root.size = RESOLUTION
	var make_result: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if make_result != OK:
		_fail("Could not create screenshot output directory")
		return

	var scene: PackedScene = load("res://scenes/main.tscn")
	if scene == null:
		_fail("Main scene could not be loaded")
		return
	var host = scene.instantiate()
	root.add_child(host)
	for _i in range(10):
		await process_frame
	host.set_process(false)

	var found_silverstone: bool = false
	for i in range(host.season_tracks.size()):
		if str(host.season_tracks[i].get("code", "")) == "GBR":
			host.selected_track_index = i
			found_silverstone = true
			break
	if not found_silverstone:
		_fail("Historical GBR circuit missing")
		return

	host.seed_picker.value = 660
	host._start_race()
	if host.race == null or host.race.cars.size() != 24:
		_fail("Race failed to start with 24 cars")
		return
	host.race.running = false
	var before_cars: String = JSON.stringify(host.race.cars)

	if not await _capture(host, 1, 0, "silverstone_2d_broadcast", 0):
		return
	if not await _capture(host, 1, 1, "silverstone_2d_compact", 0):
		return
	if not await _capture(host, 2, 1, "silverstone_3d_compact", 1):
		return

	var state_unchanged: bool = JSON.stringify(host.race.cars) == before_cars
	if not state_unchanged:
		_fail("Visual capture changed the race cars")
		return

	var manifest: Dictionary = {
		"status": "PASS",
		"godot": Engine.get_version_info().string,
		"circuit": "GBR",
		"seed": 660,
		"cars": host.race.cars.size(),
		"resolution_requested": [RESOLUTION.x, RESOLUTION.y],
		"sporting_cars_unchanged": state_unchanged,
		"captures": captures,
		"note": "Actual Godot/Xvfb render. Visual differences are not checked in this step."
	}
	var manifest_file: FileAccess = FileAccess.open(OUTPUT_DIR + "/manifest.json", FileAccess.WRITE)
	if manifest_file == null:
		_fail("Could not write manifest")
		return
	manifest_file.store_string(JSON.stringify(manifest, "  "))
	manifest_file.close()
	print("APEX_CAPTURE_CI_PASS ", JSON.stringify({"count": captures.size(), "circuit": "GBR", "seed": 660}))
	quit(0)


func _capture(host, visual_setting: int, hud_mode: int, name: String, expected_render_mode: int) -> bool:
	host._change_visual_setting(visual_setting)
	host.race_hud_0620._change_hud_mode(hud_mode)
	host._layout_ui()
	for _i in range(16):
		await process_frame
	await RenderingServer.frame_post_draw

	if host.render_mode != expected_render_mode or not host.race_hud_0620.visible:
		_fail("Unexpected visual mode or hidden HUD: " + name)
		return false

	var image: Image = root.get_texture().get_image()
	if image == null:
		_fail("Empty viewport image: " + name)
		return false
	var actual_size: Vector2i = image.get_size()
	if abs(actual_size.x - RESOLUTION.x) > 1 or actual_size.y != RESOLUTION.y:
		_fail("Unexpected image size for %s: %s" % [name, actual_size])
		return false

	var output: String = OUTPUT_DIR + "/" + name + ".png"
	if image.save_png(output) != OK:
		_fail("Could not save screenshot: " + output)
		return false

	var byte_count: int = FileAccess.get_file_as_bytes(output).size()
	if byte_count < 4096:
		_fail("Screenshot unexpectedly small: " + name)
		return false
	captures.append({
		"name": name,
		"file": name + ".png",
		"render_mode": "3D" if expected_render_mode == 1 else "2D",
		"hud_mode": hud_mode,
		"width": actual_size.x,
		"height": actual_size.y,
		"bytes": byte_count,
		"sha256": FileAccess.get_sha256(output)
	})
	print("APEX_CAPTURE_CI_FILE ", name, " ", actual_size, " bytes=", byte_count)
	return true
