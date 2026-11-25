extends SceneTree
## Real scene UI: two drivers, manual command, no double-stack click, mode guard.
var fail: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(cond: bool, name: String) -> void:
	if not cond:
		fail.append(name)
		printerr("PITWALL_0649_UI_FAIL ",name)
func _capture(where: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	var pic: Image = root.get_texture().get_image()
	if pic == null or pic.is_empty():
		check(false,"missing real rendered image "+where)
		return
	var status: Error = pic.save_png(where)
	check(status == OK and FileAccess.file_exists(where),"save screenshot "+where)
	if status == OK:
		var saved: Image = Image.load_from_file(where)
		check(saved != null and not saved.is_empty(),"readable screenshot "+where)
		print("PITWALL_UI_CAPTURE ",where," image=",pic.get_width(),"x",pic.get_height())
func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("PITWALL_0649_UI_FAIL real framebuffer required; run via xvfb")
		quit(1)
		return
	var status: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa/stabilization_0667"))
	if status != OK:
		printerr("PITWALL_0649_UI_FAIL screenshot directory ",status)
		quit(1)
		return
	root.size = Vector2i(1600,900)
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game._start_race()
	await process_frame
	await process_frame
	var hud = game.race_hud_0620
	check(hud != null and hud.visible,"HUD visible")
	if hud == null: quit(3); return
	check(hud.media_buttons.size() == 6, "legacy six shortcuts preserved")
	hud._open_window("pitwall3")
	await process_frame
	check(hud.active_window == "pitwall3", "pitwall3 modal open")
	check(hud.pitwall3_cards.size() == 2, "two real drivers")
	check(hud.overlay_title.text.contains("PIT WALL 3.0"), "title")
	check(str(hud.pitwall3_cards[0]["strategy"].text).length()>20,"dynamic strategy")
	check(str(hud.pitwall3_cards[0]["scenarios"].text).contains("PIT" ) or str(hud.pitwall3_cards[0]["scenarios"].text).contains("Box"),"scenarios display")
	check(str(hud.pitwall3_cards[0]["scenarios"].text).contains("TRÁFEGO PROJETADO"),"039 real traffic forecast displayed")
	await _capture("res://qa/stabilization_0667/pitwall_1600.png")
	var team: Array = game.race.player_cars()
	var car: Dictionary = team[0]
	var mate: Dictionary = team[1]
	var id: int = int(car["id"])
	var id2: int = int(mate["id"])
	var next: int = game.race._next_pit_entry_lap(car)
	var scheduled_before: int = int(car.get("pit_scheduled_lap", 0))
	check(scheduled_before == 0, "starts with no schedule")
	hud._pitwall3_schedule(id,0)
	check(game.replay_session.commands.size() > 0, "schedule command queued")
	check(int(car.get("pit_scheduled_lap",0)) == 0, "queued command has not yet changed sports state")
	check(game.replay_session.step_tick(), "schedule command processed next tick")
	check(int(car.get("pit_scheduled_lap",0)) == next, "click schedules on motor")
	hud._refresh_pitwall3_window()
	check(str(hud.pitwall3_cards[0]["scenarios"].text).contains("ordem protegida"),"039 protected order displayed")
	check(not bool(car.get("pit_request",false)), "schedule not immediate pit")
	hud._pitwall3_schedule(id2,0)
	check(game.replay_session.step_tick(), "companion command-processing tick")
	check(int(mate.get("pit_scheduled_lap",0)) == 0, "team conflict blocks double-stack click")
	check(int(car.get("pit_scheduled_lap",0)) == next, "first order preserved after blocked second")
	hud._pitwall3_accept(id)
	check(game.replay_session.step_tick(), "accept command-processing tick")
	check(int(car.get("pit_scheduled_lap",0)) == next and not bool(car.get("pit_request",false)), "accept cannot override V1")
	game._set_engineer_driver_mode(id2,"Automático")
	hud._refresh_pitwall3_window()
	check(bool((hud.pitwall3_cards[1]["schedule"] as Button).disabled), "auto car manual schedule disabled")
	hud._open_window("engineer")
	check(hud.engineer_cards.size() == 2 and hud.overlay_title.text.contains("3.0"),"engineer still works")
	hud._open_window("estrategia")
	check(hud.active_window == "estrategia", "legacy scheduling works")
	hud._open_window("pitwall3")
	root.size = Vector2i(1920,1080)
	await process_frame
	game._layout_ui()
	hud.layout_hud()
	await _capture("res://qa/stabilization_0667/pitwall_1920.png")
	if fail.is_empty():print("PITWALL_0667_QUEUE_AWARE_UI_PASS real HUD 1600/1920, 2 cars, commands, protected bookings, engineer")
	quit(0 if fail.is_empty() else 1)
