extends SceneTree
## Run: godot --headless --path . --script res://tests/core_0623_load_smoke_test.gd
## This validates script loading; it does NOT render UI or simulate a race.

func _initialize() -> void:
	call_deferred("_validate")

func _validate() -> void:
	var files: Array[String] = [
		"res://scripts/main.gd",
		"res://scripts/apex_race_commands.gd",
		"res://scripts/apex_race_view_controller.gd",
		"res://scripts/apex_telemetry_reports.gd",
		"res://scripts/apex_pit_reports.gd",
		"res://scripts/apex_menu_screen.gd",
		"res://scripts/apex_garage_screen.gd",
		"res://scripts/apex_race_session_controller.gd",
		"res://scripts/apex_radio_feed.gd",
		"res://scripts/apex_race_hud_0622.gd",
		"res://scripts/race_engine.gd",
	]
	for path in files:
		var script = load(path)
		if script == null:
			push_error("APEX 0623: failed to load " + path)
			quit(1)
			return
	var scene = load("res://scenes/main.tscn")
	if scene == null or not (scene is PackedScene):
		push_error("APEX 0623: main.tscn not loadable")
		quit(1)
		return
	print("APEX 0.6.2.3: scripts and main scene loaded by Godot")
	quit(0)
