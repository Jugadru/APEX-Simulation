extends SceneTree
## Native Godot capture, 1600x900 with Xvfb. Saves to user://, not to
## a ChatGPT-specific path, so this script remains portable to Linux Mint.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	for i in range(game.season_tracks.size()):
		if str(game.season_tracks[i].get("code", "")) == "BRA":
			game.selected_track_index = i
			break
	game._start_race()
	await process_frame
	game.race.running = false
	var cars: Array = game.race.player_cars()
	game._set_engineer_driver_mode(int(cars[0]["id"]), "Assistido")
	game._set_engineer_driver_mode(int(cars[1]["id"]), "Automático")
	var hud = game.race_hud_0620
	hud._open_window("engineer")
	for frame in range(25):
		await process_frame
	var picture: Image = root.get_texture().get_image()
	var path: String = "user://APEX_0640_PitWall_Preview.png"
	var outcome: Error = picture.save_png(path)
	print("APEX 0640 CAPTURE ", picture.get_width(), "x", picture.get_height(),
		" saved=", outcome, " path=", ProjectSettings.globalize_path(path),
		" role1=", game._engineer_mode_for(int(cars[0]["id"])),
		" role2=", game._engineer_mode_for(int(cars[1]["id"])))
	quit(0 if outcome == OK and hud.engineer_cards.size() == 2 else 1)
