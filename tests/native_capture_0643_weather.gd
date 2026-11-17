extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game._start_race()
	await process_frame
	game.race.configure_weather("Chuva intensa")
	game.race.running = true
	for i in range(46):
		game.race.step(4.0)
	game.race.running = false
	var hud = game.race_hud_0620
	hud.refresh_hud()
	hud._open_window("dados")
	for i in range(18):
		await process_frame
	var img: Image = root.get_texture().get_image()
	var status: Error = img.save_png("user://APEX_0643_WEATHER_PREVIEW.png")
	print("APEX 0643 VISUAL ", img.get_width(), "x", img.get_height(), " status=", status,
		" water_mm=", game.race.weather_snapshot().get("water_mm"), " rain=", game.race.weather_snapshot().get("rain_intensity"))
	quit(0 if status == OK and hud.weather_line.text.contains("mm") else 1)
