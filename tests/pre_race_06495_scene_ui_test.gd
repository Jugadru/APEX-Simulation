extends SceneTree
## Validates real menu/popup, explicit manual booking, stale plan and autonomous no-book.
var fails: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok:
		fails.append(label)
		printerr("PRE_RACE_UI_06495_FAIL " + label)
func _find_button(popup: Window, prefix: String) -> Button:
	for n in popup.find_children("*", "Button", true, false):
		if (n as Button).text.begins_with(prefix):
			return n as Button
	return null
func _wait_frames(count: int) -> void:
	for i in range(count):
		await process_frame
func _run() -> void:
	root.size = Vector2i(1600,900)
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await _wait_frames(2)
	var index: int = -1
	for i in range(game.season_tracks.size()):
		if str(game.season_tracks[i].get("code","")) == "GBR":
			index = i
	check(index >= 0,"Silverstone selected")
	game._on_track_selected(index)
	game.track_picker.select(index)
	game.seed_picker.value = 6403
	game.weather_mode_picker.select(1) # Seco
	check(game.pre_race_strategy_status != null,"planning entry in menu")
	game._open_pre_race_strategy()
	await _wait_frames(4)
	var win: Window = game.pre_race_strategy_dialog
	check(win != null and win.visible,"real popup opens")
	var apply: Button = _find_button(win,"APLICAR PRIMEIRAS")
	check(apply != null and not apply.disabled,"manual first pit apply enabled")
	var chart_count: int = 0
	for child in win.find_children("*","Control",true,false):
		if child.get_script() != null and str(child.get_script().resource_path).ends_with("apex_pre_race_tyre_chart_06495.gd"):
			chart_count += 1
	check(chart_count == 2,"two actual plan charts")
	var img: Image = win.get_texture().get_image()
	check(img != null and img.get_width() > 700 and img.save_png("res://docs/APEX_06495_PLANEJAMENTO_REAL.png") == OK,"native popup screenshot")
	root.size = Vector2i(1920,1080)
	await _wait_frames(2)
	check(win.visible and win.size.x >= 760 and win.size.y >= 520,"popup 1920")
	apply.pressed.emit()
	check(game.pre_race_strategy_pending.get("bookings",[]).size() == 2,"explicit approval stores exactly 2 orders")
	var expected: Array = game.pre_race_strategy_pending.get("bookings",[]).duplicate(true)
	game._start_race()
	await _wait_frames(2)
	check(game.race != null and game.race_hud_0620.visible,"race loads")
	for booking in expected:
		var actual: Dictionary = game._car_by_id(int(booking["id"]))
		check(int(actual.get("pit_scheduled_lap",-1)) == int(booking["lap"]),"first stop scheduled at correct lap")
		check(str(actual.get("pit_target",""))==str(booking["target"]),"right target tire")
		check(not bool(actual.get("pit_request",true)),"no immediate box request")
	check(game.pre_race_strategy_pending.is_empty(),"order cache cleared after start")
	game._show_menu()
	game._open_pre_race_strategy()
	await _wait_frames(2)
	var next_dialog: Window = game.pre_race_strategy_dialog
	var next_apply: Button = _find_button(next_dialog,"APLICAR PRIMEIRAS")
	check(next_apply != null and not next_apply.disabled,"dialog reopens on menu")
	next_apply.pressed.emit()
	check(not game.pre_race_strategy_pending.is_empty(),"second approval possible")
	game.seed_picker.value = 7049
	game._start_race()
	await _wait_frames(2)
	for car in game.race.player_cars():
		check(int(car.get("pit_scheduled_lap",-1)) == 0,"old plan rejected after seed change")
	game._show_menu()
	game._select_pre_race_team_mode(1) # auto
	game._open_pre_race_strategy()
	await _wait_frames(3)
	var auto_button: Button = _find_button(game.pre_race_strategy_dialog,"APLICAR PRIMEIRAS")
	check(auto_button != null and auto_button.disabled,"automatic cannot hardcode manual pits")
	game._start_race()
	await _wait_frames(2)
	check(game.race != null and game.team_control_mode == "Automático","auto mode starts")
	for car in game.race.player_cars():
		check(int(car.get("pit_scheduled_lap",-1)) == 0,"no pre-race manual booking in auto mode")
	if fails.is_empty():
		print("PRE_RACE_UI_06495_PASS popup, charts, 1600/1920, approved first stops, stale plan guard, automatic advisory")
	quit(0 if fails.is_empty() else 1)
