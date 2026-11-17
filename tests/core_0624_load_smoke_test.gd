extends SceneTree
## Run in Godot 4.7.2:
## godot --headless --path . --script res://tests/core_0624_load_smoke_test.gd
## Script resource loading only; this does NOT render HUD or run a race.

func _initialize() -> void:
	call_deferred("_validate")

func _validate() -> void:
	var paths: Array[String] = [
		"res://scripts/main.gd",
		"res://scripts/apex_race_ui_legacy_builder.gd",
		"res://scripts/apex_race_ui_layout.gd",
		"res://scripts/apex_race_ui_presenter.gd",
		"res://scripts/apex_race_ui_legacy_cards.gd",
		"res://scripts/apex_race_view_controller.gd",
		"res://scripts/apex_race_session_controller.gd",
		"res://scripts/apex_race_hud_0622.gd",
		"res://scripts/apex_strategy_planner_0620.gd",
		"res://scripts/race_engine.gd"
	]
	for path in paths:
		var obj = load(path)
		if obj == null or not (obj is Script):
			push_error("APEX 0624: falha ao carregar " + path)
			quit(1)
			return
	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		push_error("APEX 0624: cena principal não carregou")
		quit(1)
		return
	print("APEX 0.6.2.4: scripts e cena carregados; validar HUD visualmente com F5")
	quit(0)
