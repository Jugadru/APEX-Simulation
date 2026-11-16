extends SceneTree
## Run: godot --headless --path . --script res://tests/hud_05322_ui_test.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	assert(scene != null, "Main scene missing")
	var app = scene.instantiate()
	root.add_child(app)
	await process_frame
	app._start_race()
	await process_frame
	assert(app.player_cards.size() == 2)
	assert(app.mini_map != null and app.conditions != null)
	app._change_hud_layout(1) # Explicit complete mode, not automatic.
	app.card_fold_preferences[0] = false
	app.card_fold_preferences[1] = false
	app._layout_ui()
	assert(app.player_cards[0]["details"].visible)
	assert(app.player_cards[1]["details"].visible)
	app._toggle_driver_card(0)
	assert(not app.player_cards[0]["details"].visible)
	assert(app.player_cards[1]["details"].visible)
	app._toggle_all_driver_cards()
	assert(not app.player_cards[0]["details"].visible)
	assert(not app.player_cards[1]["details"].visible)
	app._toggle_all_driver_cards()
	assert(app.player_cards[0]["details"].visible)
	assert(app.player_cards[1]["details"].visible)
	var start_bar: float = app.bottom_bar.position.y
	var cards_end: float = app.player_card_strip.position.y + app.player_card_strip.size.y
	assert(cards_end <= start_bar + 0.1, "Driver cards overlap bottom bar")
	var side_x: float = app.left_panel.position.x + app.left_panel.size.x
	assert(app.player_card_strip.position.x >= side_x, "Cards cover Live Timing")
	var right_edge: float = app.player_card_strip.position.x + app.player_card_strip.size.x
	assert(right_edge <= app.right_panel.position.x + 0.1, "Cards cover Pit Wall")
	# New timing UI must not remove existing strategy commands.
	var car: Dictionary = app.race.player_cars()[0]
	app.player_cards[0]["tire"].select(0)
	app._request_pit(int(car["id"]), app.player_cards[0]["tire"])
	assert(bool(car["pit_request"]), "Pit call from compact card failed")
	app._change_hud_layout(3)
	assert(not app.left_panel.visible and not app.right_panel.visible)
	assert(not app.player_card_strip.visible)
	app._change_hud_layout(0)
	assert(app.player_card_strip.visible)
	print("PASS: Apex 0.5.3.2.2 cards collapse/expand, no overlap, pit command, cinema mode")
	quit(0)
