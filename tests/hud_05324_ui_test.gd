extends SceneTree
## Run: godot --headless --path . --script res://tests/hud_05324_ui_test.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	assert(scene != null, "Main scene not found")
	var app = scene.instantiate()
	root.add_child(app)
	await process_frame
	app._start_race()
	await process_frame
	assert(app.player_cards.size() == 2, "Both driver cards should exist")
	assert(app.commentary != null and app.radio_log != null)
	assert(app.diagnostic_primary != null and app.diagnostic_secondary != null)
	assert(app.strategy_stints != null)
	app._change_hud_layout(1)
	app.card_fold_preferences[0] = false
	app.card_fold_preferences[1] = false
	app._layout_ui()
	var first: Dictionary = app.race.player_cars()[0]
	var tire_select: OptionButton = app.player_cards[0]["tire"]
	tire_select.select(0)
	# A click on the bottom driver card should order the pit, with the selected tyre.
	app.player_cards[0]["pit"].pressed.emit()
	assert(bool(first["pit_request"]), "Driver card did not request a pit stop")
	assert(str(first["pit_target"]) == "Macio", "Selected compound was lost")
	app._update_game_ui()
	assert(app.player_cards[0]["pit"].disabled, "Pit button should not allow duplicate orders")
	assert(app.strategy_primary.text.contains("BOX CHAMADO"))
	app._set_radio_filter(0)
	app.race._event("pass", int(first["id"]), "%s avançou para P1." % str(first["name"]), 90)
	app._update_game_ui()
	assert(app.radio_log.text.contains("NARRADOR"))
	app._set_radio_filter(2)
	assert(app.radio_log.text.contains("ENGENHEIRO"))
	assert(app.diagnostic_primary.text.contains("CARRO 1"))
	app._set_pitwall_mode(0)
	assert(app.pitwall_summary_body.text.contains("Chance de chuva"))
	app._set_pitwall_mode(1)
	assert(app.pitwall_summary_body.text.contains("Degradação"))
	app._set_pitwall_mode(2)
	assert(app.pitwall_summary_body.text.contains("Ritmo:"))
	print("PASS v0.5.3.2.4: driver card box, commentary filters, diagnostics, strategy shortcuts")
	quit(0)
