extends SceneTree
## v0.6.4.9.6: interface real + 2 resoluções, sem executar ordens ao consultar.
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("UI_06497_FAIL " + label)
		failures.append(label)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1600,900)
	var scene: PackedScene = load("res://scenes/main.tscn")
	check(scene != null, "main scene")
	if scene == null:
		quit(2)
		return
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game._start_race()
	await process_frame
	check(game.race != null and game.race_hud_0620 != null, "game and HUD loaded")
	if game.race == null:
		quit(2)
		return
	game.race.running = true
	for i in range(45):
		game.race.step(4.0)
	check(int(game.race.player_cars()[0]["laps_done"]) >= 1, "player completed lap")
	# 06497: render the latest coordination decision without executing it.
	var player_a: Dictionary = game.race.player_cars()[0]
	player_a["team_pit_coord_06497"] = {"overlap":true,"decision":"ANTECIPAR",
		"reason":"Janela V16 coincide; antecipar carro secundário para V15.",
		"target_lap":16}
	var before: Array = []
	for c in game.race.player_cars():
		before.append([int(c.get("pit_scheduled_lap",0)),bool(c.get("pit_request",false))])
	var hud = game.race_hud_0620
	hud._open_window("engineer")
	await process_frame
	check(hud.engineer_cards.size() == 2, "two engineer cards")
	for ui in hud.engineer_cards:
		check((ui["evidence"] as Label).text.contains("REVISÃO V"), "engineer lap revision displayed")
	check((hud.engineer_cards[0]["evidence"] as Label).text.contains("EQUIPE: ANTECIPAR"), "coordination note in engineer")
	hud._open_window("pitwall3")
	await process_frame
	check(hud.pitwall3_cards.size() == 2, "pitwall cards")
	for ui in hud.pitwall3_cards:
		check((ui["notes"] as Label).text.contains("REAVALIAÇÃO V"),"pitwall lap revision displayed")
	check((hud.pitwall3_cards[0]["notes"] as Label).text.contains("COORDENAÇÃO AUTO: ANTECIPAR"),"coordination note in pitwall")
	for viewport in [Vector2i(1600,900), Vector2i(1920,1080)]:
		root.size = viewport
		await process_frame
		game._layout_ui()
		hud.layout_hud()
		await process_frame
		check(hud.overlay_window.size.x > 500 and hud.overlay_window.size.y > 250, "modal dimensions " + str(viewport))
	root.size = Vector2i(1600,900)
	await process_frame
	game._layout_ui()
	hud.layout_hud()
	for i in range(3):
		await process_frame
	var shot: Image = root.get_texture().get_image()
	check(shot.save_png("res://docs/APEX_06497_COORDENACAO_PITWALL_1600.png") == OK,"screenshot saved")
	hud._close_window()
	var after: Array = []
	for c in game.race.player_cars():
		after.append([int(c.get("pit_scheduled_lap",0)),bool(c.get("pit_request",false))])
	check(before == after,"reading interface did not send pit orders")
	if failures.is_empty():
		print("APEX_06497_UI_PASS native HUD, 2 pilots, 1600 and 1920, no hidden orders")
	quit(0 if failures.is_empty() else 1)
