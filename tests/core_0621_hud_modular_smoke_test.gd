extends SceneTree
## Execution: godot --headless --path . --script res://tests/core_0621_hud_modular_smoke_test.gd
## Must be run with Godot 4.x. Tests parsing, scene setup, HUD opening upward.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for path in [
		"res://scripts/apex_race_hud_0620.gd",
		"res://scripts/apex_strategy_planner_0620.gd",
		"res://scripts/apex_session_settings.gd",
		"res://scripts/apex_championship_flow.gd",
		"res://scripts/apex_garage_presentation.gd",
		"res://scripts/apex_race_formatting.gd",
		"res://scripts/main.gd"
	]:
		if load(path) == null:
			push_error("APEX 0621: failure to load " + path)
			quit(1)
			return
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		push_error("APEX 0621: main.tscn failed")
		quit(2)
		return
	var root_scene := packed.instantiate()
	root.add_child(root_scene)
	await process_frame
	var hud = root_scene.race_hud_0620
	if hud == null:
		push_error("APEX 0621: HUD was not created")
		quit(3)
		return
	root_scene._start_race()
	await process_frame
	if not hud.visible or hud.race_card_panels.size() != 2:
		push_error("APEX 0621: race cards were not initialized")
		quit(4)
		return
	hud._expand_driver(0, 0)
	var card: Dictionary = hud.race_card_panels[0]
	if not card["expanded"].visible or card["expanded"].position.y >= card["base"].position.y:
		push_error("APEX 0621: driver details did not open upward")
		quit(5)
		return
	hud._open_window("estrategia")
	if hud.active_window != "estrategia":
		push_error("APEX 0621: strategy window failed")
		quit(6)
		return
	hud._close_window()
	print("PASS APEX 0621: scripts, main scene, driver panel upwards, strategy overlay")
	quit(0)
