extends SceneTree
## Run with Godot 4.x: godot --headless --path . --script res://tests/core_0620_hud_smoke_test.gd
## Loads the full main scene and constructs the new HUD in engine context.

func _initialize() -> void:
	call_deferred("_smoke")

func _smoke() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		push_error("APEX 0620: main scene could not be parsed")
		quit(1)
		return
	var scene := packed.instantiate()
	if scene == null:
		push_error("APEX 0620: scene could not be instantiated")
		quit(2)
		return
	root.add_child(scene)
	await process_frame
	var hud: Control = _find_hud(scene)
	if hud == null:
		push_error("APEX 0620: new HUD node missing")
		quit(3)
		return
	print("APEX 0620 HUD smoke PASS: scene and new layer constructed")
	quit(0)

func _find_hud(node: Node) -> Control:
	if node.name == "RaceHUD0620":
		return node as Control
	for child in node.get_children():
		var found: Control = _find_hud(child)
		if found != null:
			return found
	return null
