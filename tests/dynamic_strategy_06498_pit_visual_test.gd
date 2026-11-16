extends SceneTree
## Real Silverstone stop and live chart integration; screenshot after service.
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, name: String) -> void:
	if not ok:
		failures.append(name)
		printerr("APEX_06498_PIT_FAIL " + name)
func _run() -> void:
	root.size = Vector2i(1600,900)
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	for i in range(game.season_tracks.size()):
		if str(game.season_tracks[i].get("code", "")) == "GBR":
			game.selected_track_index = i
			game.track_picker.select(i)
	game.seed_picker.value = 6403
	game.team_control_mode = "Automático"
	game._start_race()
	await process_frame
	var hud = game.race_hud_0620
	game.race.running = true
	var pit: Dictionary = {}
	for step in range(1600):
		game.race.step(4.0)
		hud.dynamic_graph_data.capture(game.race)
		for service in game.race.pit_history:
			if str(service.get("team","")) == str(game.selected_team):
				pit = service
				break
		if not pit.is_empty():
			break
	check(not pit.is_empty(), "actual completed pit in Silverstone")
	check(not game.race.finished, "pit before race end")
	if not pit.is_empty():
		var car: Dictionary = game._car_by_id(int(pit["car_id"]))
		var view: Dictionary = hud.dynamic_graph_data.view(game.race, car)
		check(view["pits"].size() > 0,"real pit history shown in graph")
		check(int(view["stops"]) > 0, "car count increased through engine")
		check(int(view["pits"][0]["lap"]) == int(pit["lap"]), "actual pit lap and chart identical")
		hud._open_window("graficos")
		hud.refresh_hud()
		for frame in range(8):
			await process_frame
		var screenshot: Image = root.get_texture().get_image()
		check(screenshot.save_png("res://docs/APEX_06498_PIT_REAL_SILVERSTONE_1600.png") == OK,"post-pit screenshot")
	if failures.is_empty():
		print("APEX_06498_PIT_PASS real Silverstone service V%d, no synthetic stops, native 1600x900 PNG" % int(pit.get("lap",-1)))
	quit(0 if failures.is_empty() else 1)
