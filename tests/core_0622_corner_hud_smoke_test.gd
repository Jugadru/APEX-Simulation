extends SceneTree
## Run on the user's machine: godot --headless --path . --script res://tests/core_0622_corner_hud_smoke_test.gd
## Real parser + geometry test, run only with a Godot 4.x binary.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for file in ["res://scripts/apex_race_hud_0622.gd", "res://scripts/main.gd"]:
		if load(file) == null:
			push_error("APEX 0622: failed to parse " + file)
			quit(1)
			return
	var scene: PackedScene = load("res://scenes/main.tscn")
	if scene == null:
		push_error("APEX 0622: cannot load main scene")
		quit(2)
		return
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game._start_race()
	await process_frame
	var hud = game.race_hud_0620
	if hud == null or not hud.visible or hud.race_card_panels.size() != 2:
		push_error("APEX 0622: cards failed to initialize")
		quit(3)
		return
	if hud.bottom_bar.size.x > 270.0:
		push_error("APEX 0622: full-width bottom stripe still present")
		quit(4)
		return
	var first: Dictionary = hud.race_card_panels[0]
	var second: Dictionary = hud.race_card_panels[1]
	if first["base"].position.x > 25.0 or second["base"].position.x < hud.size.x * 0.60:
		push_error("APEX 0622: cards are not in opposite corners")
		quit(5)
		return
	for i in range(2):
		hud._expand_driver(i, 2)
		var card: Dictionary = hud.race_card_panels[i]
		var upper: Rect2 = Rect2(card["expanded"].position, card["expanded"].size)
		var lower: Rect2 = Rect2(card["base"].position, card["base"].size)
		if not card["expanded"].visible or upper.end.y >= lower.position.y:
			push_error("APEX 0622: detail does not open upward")
			quit(6)
			return
		if i == 0 and upper.intersects(Rect2(hud.ranking.position, hud.ranking.size)):
			push_error("APEX 0622: left detail overlaps ranking")
			quit(7)
			return
		if i == 1 and upper.intersects(Rect2(hud.map_box.position, hud.map_box.size)):
			push_error("APEX 0622: right detail overlaps minimap")
			quit(8)
			return
	hud._open_window("estrategia")
	if hud.active_window != "estrategia":
		push_error("APEX 0622: strategy panel failed to open")
		quit(9)
		return
	print("PASS APEX 0622: native parse, corner cards, compact speed controls, upward panes and strategy")
	quit(0)
