extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game._new_championship()
	game._open_garage()
	for f in range(16):
		await process_frame
	var card: Node = game.garage_root.find_child("GarageScroll", true, false)
	if card == null:
		printerr("APEX 0642 capture: GarageScroll missing")
		quit(1)
		return
	var top: Error = root.get_texture().get_image().save_png("user://APEX_0642_GARAGE_TOP.png")
	(card as ScrollContainer).scroll_vertical = 425
	for f in range(10):
		await process_frame
	var lower: Error = root.get_texture().get_image().save_png("user://APEX_0642_GARAGE_RIVALS.png")
	print("APEX 0642 GARAGE CAPTURE top=", top, " rivals=", lower, " scroll=", (card as ScrollContainer).scroll_vertical,
		" project_controls=", game.garage_project_buttons.size())
	quit(0 if top == OK and lower == OK and game.garage_project_buttons.size() == 3 else 1)
