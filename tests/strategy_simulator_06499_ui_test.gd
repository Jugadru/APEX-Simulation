extends SceneTree
## Native Godot 4.7.2 screenshots, both resolutions, real in-race telemetry.
var errors: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, what: String) -> void:
	if not ok:
		errors.append(what)
		printerr("APEX_06499_UI_FAIL "+what)
func _capture(name: String, dims: Vector2i) -> void:
	for i in range(8):
		await process_frame
	var img: Image = root.get_texture().get_image()
	check(img != null, "screenshot exists "+name)
	if img != null:
		check(img.get_width() == dims.x and img.get_height() == dims.y, "actual dimensions "+name)
		check(img.save_png("res://docs/"+name) == OK,"saved PNG "+name)
func _run() -> void:
	root.size = Vector2i(1600, 900)
	var packed = load("res://scenes/main.tscn")
	check(packed != null,"main scene")
	if packed == null:
		quit(2)
		return
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	for i in range(game.season_tracks.size()):
		if str(game.season_tracks[i].get("code", "")) == "GBR":
			game.selected_track_index = i
			game.track_picker.select(i)
			break
	game.seed_picker.value = 6403
	game.team_control_mode = "Automático"
	game._start_race()
	await process_frame
	check(game.race != null, "Silverstone race started")
	var hud = game.race_hud_0620
	check(hud != null and hud.visible, "hybrid HUD")
	check(hud.media_buttons.size() == 6,"top HUD shortcuts preserved")
	var before: String = JSON.stringify(game.race.get_state_snapshot())
	hud._open_window("simulator")
	await process_frame
	check(hud.active_window == "simulator","simulator opened")
	check(hud.simulator_cards.size() == 2,"two strategy cards")
	for card in hud.simulator_cards:
		check(card["buttons"].size() == 6,"six alternatives for driver")
		check((card["detail"] as Label).text.contains("retorno"),"live scenario detail")
	check(before == JSON.stringify(game.race.get_state_snapshot()),"opening preview no race mutation")
	var id: int = int(game.race.player_cars()[0]["id"])
	hud._select_strategy_simulator_case(id, 3)
	check(int(hud.simulator_selection.get(id, -1)) == 3,"selected +3 lap")
	check(before == JSON.stringify(game.race.get_state_snapshot()),"click selection no pit order")
	await _capture("APEX_06499_SIMULADOR_SILVERSTONE_1600.png",Vector2i(1600,900))
	root.size = Vector2i(1920,1080)
	await process_frame
	game._layout_ui()
	hud.layout_hud()
	await _capture("APEX_06499_SIMULADOR_SILVERSTONE_1920.png",Vector2i(1920,1080))
	check(hud.overlay_window.size.x >= 1200.0 and hud.overlay_window.size.y >= 700.0,"responsive 1920")
	root.size = Vector2i(1600,900)
	await process_frame
	game._layout_ui()
	hud.layout_hud()
	# Use engine ticks, not fictional point values.
	game.race.running = true
	for i in range(170):
		game.race.step(4.0)
		hud.dynamic_graph_data.capture(game.race)
	hud.refresh_hud()
	check(int(game.race.player_cars()[0].get("laps_done", 0)) > 1,"live racing laps")
	await _capture("APEX_06499_TELEMETRIA_SILVERSTONE_1600.png",Vector2i(1600,900))
	hud._open_window("pitwall3")
	check(hud.pitwall3_cards.size() == 2,"Pit Wall 3.0 preserved")
	hud._open_window("engineer")
	check(hud.engineer_cards.size() == 2,"Race Engineer 3.0 preserved")
	hud._open_window("graficos")
	check(hud.dynamic_chart_views.size() == 2,"graphs 9.8 preserved")
	hud._open_window("estrategia")
	check(hud.modal_timeline != null,"strategy commands preserved")
	if errors.is_empty():
		print("APEX_06499_UI_PASS Godot 4.7.2, Silverstone 1600x900 / 1920x1080, two drivers, six scenarios, no pit orders, HUD regressions")
	quit(0 if errors.is_empty() else 1)
