extends SceneTree
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._start_race()
	await process_frame
	var hud = game.race_hud_0620
	var car_id: int = int(game.race.player_cars()[0]["id"])
	game.race.clock = 147.0
	game.race.running = true
	game.race._event("incident", car_id, "ERRO DE TESTE: tempo perdido sem alteração de estratégia.", 115)
	hud._update_reactive_radio()
	var result: bool = hud.radio_reactive_toast.visible and not hud.radio_reactive_latest.contains("Aguardando")
	hud._open_window("radio")
	hud._set_radio_category(2)
	for frame in range(18):
		await process_frame
	var png: Image = root.get_texture().get_image()
	var file_path: String = "user://Apex_0637_Radio_Reativo_Preview.png"
	var err: int = png.save_png(file_path)
	print("APEX 0637 VISUAL",png.get_width(),"x",png.get_height()," alert=", result, " saved=", err)
	quit(0 if result and err == OK else 1)
