extends SceneTree
## Actual scene integration; no standalone mock race.
const Modes = preload("res://scripts/apex_hud_rebroadcast_0668.gd")
var fails: Array[String] = []
var checks_run: int = 0

func check(ok: bool, name: String) -> void:
	checks_run += 1
	if not ok:
		fails.append(name)
		printerr("FAIL HUD 0668: ", name)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1600, 900)
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await process_frame
	host.set_process(false)
	host._start_race()
	await process_frame
	var hud = host.race_hud_0620
	check(hud != null and hud.visible, "HUD started in real race")
	check(hud.standing_rows.size() == 24, "24 reusable leaderboard rows")
	check(hud.race_card_panels.size() == 2, "two live driver cards")
	if hud == null:
		quit(2)
		return
	# Read-only refresh must not mutate sporting dictionaries.
	var state_before: Array = host.race.cars.duplicate(true)
	var old_writes: int = hud.ranking_field_writes
	hud.refresh_hud()
	check(host.race.cars == state_before, "sporting cars unchanged by refresh")
	check(hud.ranking_field_writes == old_writes, "no redundant leaderboard field writes")
	for mode in range(3):
		hud._change_hud_mode(mode)
		check(hud.hud_mode_picker.selected == mode, "mode selector %d" % mode)
		check(hud.ranking.visible and hud.weather_box.visible and hud.map_box.visible, "persistent broadcast information")
		check(hud.pit_quick_panel.visible == (mode == 2), "full-only real pit controls")
		check(bool(hud.race_card_panels[0]["base"].visible) == (mode != 0), "mode card visibility %d" % mode)
		check(Modes.load_mode() == mode, "saved preference %d" % mode)
	for dimensions in [Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(1366, 768)]:
		root.size = dimensions
		await process_frame
		hud.layout_hud()
		check(hud.ranking.position.x + hud.ranking.size.x < dimensions.x * .34, "ranking anchored left %s" % str(dimensions))
		check(hud.map_box.position.x > dimensions.x * .70, "minimap anchored right %s" % str(dimensions))
		check(hud.ranking.position.y + hud.ranking.size.y < hud.race_card_panels[0]["base"].position.y, "no ranking/card overlap %s" % str(dimensions))
	# Existing real modals must remain connected.
	hud._open_window("estrategia")
	check(hud.active_window == "estrategia" and hud.modal_driver_rows.size() == 2, "strategy modal and two real cars")
	hud._open_window("pitwall3")
	check(hud.active_window == "pitwall3" and hud.pitwall3_cards.size() == 2, "Pit Wall 3.0 backend")
	hud._open_window("engineer")
	check(hud.active_window == "engineer", "real engineer backend")
	hud._close_window()
	check(host.race.cars == state_before, "HUD modes/modals do not alter racing state")
	# Leave default preference clean for the next run and user installation.
	hud._change_hud_mode(1)
	check(Modes.load_mode() == 1, "compact restored")
	print("HUD_REBROADCAST_0668_INTEGRATION_", "PASS" if fails.is_empty() else "FAIL", " checks=", checks_run, " issues=", fails)
	quit(0 if fails.is_empty() else 1)
