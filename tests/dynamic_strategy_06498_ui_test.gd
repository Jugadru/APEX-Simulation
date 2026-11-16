extends SceneTree
## Native Godot 4.7.2 visual + interaction regression, 1600x900 and 1920x1080.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		printerr("APEX_06498_UI_FAIL " + label)

func _shot(name: String, expected: Vector2i) -> void:
	for i in range(7):
		await process_frame
	var img: Image = root.get_texture().get_image()
	check(img != null, "viewport image " + name)
	if img != null:
		check(img.get_width() == expected.x and img.get_height() == expected.y, "capture dimensions " + name)
		check(img.save_png("res://docs/" + name) == OK, "capture PNG " + name)

func _run() -> void:
	root.size = Vector2i(1600,900)
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
	check(str(game.season_tracks[game.selected_track_index].get("code","")) == "GBR", "Silverstone selected")
	game.seed_picker.value = 6403
	game.team_control_mode = "Automático"
	game._start_race()
	await process_frame
	check(game.race != null, "race created")
	if game.race == null:
		quit(2)
		return
	var hud = game.race_hud_0620
	check(hud != null and hud.visible, "hybrid HUD active")
	check(hud.media_buttons.size() == 6, "original top shortcuts preserved")
	check(hud.dynamic_graph_data.initial_plans.size() == 2,"two frozen initial plans")
	var original: String = JSON.stringify(hud.dynamic_graph_data.initial_plans)
	var baseline: Array = []
	for car in game.race.player_cars():
		baseline.append([int(car.get("id",-1)),int(car.get("pit_scheduled_lap",0)),bool(car.get("pit_request",false))])
	hud._open_window("graficos")
	await process_frame
	check(hud.dynamic_chart_views.size() == 2,"both driver graph cards")
	check(hud.dynamic_garage_status.text.contains("GARAGEM"), "live garage report")
	for item in hud.dynamic_chart_views:
		var snap: Dictionary = item["graph"].data
		check(snap["history"].size() == 1, "one grid sample")
		check(int(snap["history"][0]["lap"]) == 0,"grid lap is zero")
		check(float(snap["history"][0]["wear"]) == 0.0, "grid wear is simulator zero")
		check(snap["forecast"].size() > 0, "forecast from live engine")
	await _shot("APEX_06498_GRAFICOS_SILVERSTONE_1600.png", Vector2i(1600,900))
	root.size = Vector2i(1920,1080)
	await process_frame
	game._layout_ui()
	hud.layout_hud()
	await _shot("APEX_06498_GRAFICOS_SILVERSTONE_1920.png", Vector2i(1920,1080))
	check(hud.overlay_window.size.x > 1000.0 and hud.overlay_window.size.y > 600.0, "responsive 1920 modal")
	root.size = Vector2i(1600,900)
	await process_frame
	game._layout_ui()
	hud.layout_hud()
	hud._open_window("pitwall3")
	check(hud.pitwall3_cards.size() == 2, "Pit Wall 3.0 remains")
	hud._open_window("engineer")
	check(hud.engineer_cards.size() == 2,"Engineer 3.0 remains")
	hud._open_window("estrategia")
	check(hud.modal_timeline != null, "existing strategy remains")
	hud._open_window("graficos")
	var after: Array = []
	for car in game.race.player_cars():
		after.append([int(car.get("id",-1)),int(car.get("pit_scheduled_lap",0)),bool(car.get("pit_request",false))])
	check(after == baseline, "opening graphs causes no pit command")
	check(JSON.stringify(hud.dynamic_graph_data.initial_plans) == original,"initial plan stays frozen")
	# Run native race steps and sample on every visible lap crossing.
	game.race.running = true
	var ticks: int = 0
	while int(game.race.player_cars()[0].get("laps_done",0)) < 7 and ticks < 800:
		game.race.step(4.0)
		hud.dynamic_graph_data.capture(game.race)
		ticks += 1
	check(ticks < 800,"Silverstone advances 7 laps")
	hud.refresh_hud()
	for car in game.race.player_cars():
		var view: Dictionary = hud.dynamic_graph_data.view(game.race, car)
		var history: Array = view["history"]
		check(history.size() >= 5, "lap observations stored " + str(car.get("name")))
		check(int(history[-1]["lap"]) == int(car.get("laps_done",0)), "observed current lap")
		check(float(history[-1]["wear"]) >= 0.0 and float(history[-1]["wear"]) <= 100.0, "physical wear within simulator bounds")
		check(float(car.get("wear", 0.0)) >= float(history[-1]["wear"]) - 0.001 or int(car.get("stops", 0)) > int(history[-1]["stops"]), "no impossible wear decrease within a stint")
		for i in range(1,history.size()):
			check(int(history[i]["lap"]) > int(history[i-1]["lap"]),"sample order")
		check(float(view["rate"]) > 0.0, "live wear rate")
	check(JSON.stringify(hud.dynamic_graph_data.initial_plans) == original,"initial planner snapshot unmodified after laps")
	await _shot("APEX_06498_DESGASTE_REAL_SILVERSTONE_1600.png", Vector2i(1600,900))
	hud._close_window()
	if failures.is_empty():
		print("APEX_06498_UI_PASS Silverstone; 1600x900 and 1920x1080 real PNG; two pilots; live wear and 9.7 regressions")
	quit(0 if failures.is_empty() else 1)
