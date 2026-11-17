extends SceneTree
## Run: godot --headless --path . --script res://tests/hud_0532_ui_test.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	assert(scene != null, "Main scene unavailable")
	var app = scene.instantiate()
	root.add_child(app)
	await process_frame
	assert(app.portrait_manager != null)
	assert(app.portrait_download_button != null)
	assert(app.mini_map != null)
	assert(app.conditions != null)
	app._start_race()
	await process_frame
	assert(app.race.cars.size() == 24)
	assert(app.player_cards.size() == 2)
	assert(app.mini_map.route.size() > 30)
	app._process(0.1)
	assert(app.mini_map.cars.size() == 24)
	app._update_game_ui()
	assert(app.weather_label.text.contains("Ar "))
	assert(app.weather_label.text.contains("Aderência"))
	app._change_hud_layout(3)
	assert(not app.player_card_strip.visible)
	app._change_hud_layout(0)
	assert(app.player_card_strip.visible)
	var target: int = int(app.race.player_cars()[0]["id"])
	app._focus_driver(target)
	assert(app.manual_driver == target)
	assert(app.camera_mode == "Seguir piloto")
	print("APEX v0.5.3.2 UI TEST OK — cards, mini map, weather and portrait hooks")
	quit(0)
