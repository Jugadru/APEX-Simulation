extends SceneTree
## Execute on Linux Mint: godot --headless --path . --script res://tests/menu_0590_ui_smoke_test.gd
## Checks the menu's start button is visible at several resolutions and launches a race.
func _initialize() -> void:
	call_deferred("_check")

func _fail(message: String) -> void:
	push_error("APEX MENU HOTFIX2: " + message)
	quit(1)

func _check() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		_fail("Failed to load main.tscn")
		return
	var app: Node = packed.instantiate()
	root.add_child(app)
	await process_frame
	if app.start_button == null or app.menu_scroll == null or app.menu_actions == null:
		_fail("Start or scroll/footer was not created")
		return
	if app.menu_scroll.is_ancestor_of(app.start_button):
		_fail("Start button is still inside the scrolling form")
		return
	for dim in [Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(1024, 768)]:
		root.size = dim
		app._layout_ui()
		await process_frame
		var rect: Rect2 = app.start_button.get_global_rect()
		var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(dim))
		if not app.start_button.is_visible_in_tree() or not bounds.encloses(rect):
			_fail("Start outside visible window %s: %s" % [str(dim), str(rect)])
			return
		if rect.size.y < 48.0 or rect.size.x < 150.0:
			_fail("Start button has unusable size %s" % str(rect))
			return
	app.start_button.pressed.emit()
	await process_frame
	if app.race == null or app.race.cars.size() != 24:
		_fail("Clicking start did not open a 24-car Grand Prix")
		return
	print("PASS MENU 0590: start visible at 1600x900, 1280x720, 1024x768; launches race")
	quit(0)
