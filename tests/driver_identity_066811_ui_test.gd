extends SceneTree
## Team radio identity/photo UI is presentation only, no RaceEngine mutation.
var checks := 0
var fails := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		printerr("DRIVER_IDENTITY_066811_UI_FAIL: " + reason)
func run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	check(game.portrait_manager != null, "Identity manager exists")
	check(game.portrait_download_button != null and game.portrait_download_button.visible, "Team portrait download available")
	check(game.portrait_download_all_button != null and game.portrait_download_all_button.visible, "Grid download available")
	check(game.portrait_manager.download_state == "idle", "No background download")
	game._start_race()
	await process_frame
	var hud = game.race_hud_0620
	check(hud != null, "Real HUD instance")
	hud.refresh_hud()
	var order: Array = game.race.get_sorted()
	check(hud.standing_rows.size() == 24, "24 leaderboard entries")
	for card in hud.race_card_panels:
		var card_name: String = str(card["name"].text)
		var card_info: Dictionary = game.portrait_manager.get_info(card_name)
		check(str(card["identity"].text).contains(str(card_info.get("abbr", "___"))), "Card displays official code: " + card_name)
	for i in range(mini(order.size(), hud.standing_rows.size())):
		var grid_name: String = str(order[i].get("name", ""))
		var official: String = game.portrait_manager.get_abbreviation(grid_name)
		check(hud.standing_rows[i]["driver"].text == official, "Official 2012 abbreviation in ranking: " + grid_name)
	var player: Dictionary = game.race.player_cars()[0]
	var player_name: String = str(player.get("name", ""))
	var info: Dictionary = game.portrait_manager.get_info(player_name)
	check(not info.is_empty(), "Actual team driver recognized")
	hud._open_window("radio")
	check(hud.radio_portrait_texture != null, "Portrait slot created")
	check(hud.radio_identity_info != null, "Identity data label created")
	var index: int = hud.radio_driver_ids.find(int(player.get("id", -1)))
	check(index >= 0, "Selected driver exists in radio")
	hud.radio_driver_picker.select(index)
	hud._radio_driver_changed(index)
	var snapshot: PackedByteArray = var_to_bytes(game.race.get_state_snapshot())
	var info_line: String = str(hud.radio_identity_info.text)
	check(info_line.contains(player_name), "Identity shows name of actual driver")
	print("DRIVER_066811_UI_DEBUG name=", player_name, " number=", info.get("number", -1), " label=", info_line)
	check(info_line.contains("#" + str(int(info.get("number", 0)))), "Historical number visible")
	check(info_line.contains(str(info.get("country", ""))), "Historical country visible")
	var image = game.portrait_manager.get_photo(player_name)
	check(hud.radio_portrait_texture.visible == (image != null), "Actual JPG only, no fake car fallback")
	check(hud.radio_portrait_placeholder.visible == (image == null), "Initials on missing photo")
	check(hud.radio_portrait_placeholder.text == str(info.get("abbr", "---")), "Official initials in radio fallback")
	if image != null:
		var photo_credit: String = game.portrait_manager.get_credit(player_name)
		check(not photo_credit.is_empty() and str(hud.radio_identity_info.text).contains(photo_credit), "Photo visible with correct source attribution")
	else:
		check(str(hud.radio_identity_info.text).contains("apenas iniciais"), "No-photo state never shows a vehicle")
	check(game.replay_session.commands.size() == 0, "No sports command created by identity UI")
	check(snapshot == var_to_bytes(game.race.get_state_snapshot()), "Presentation does not change sporting state")
	check(int(game.race.player_cars()[0].get("pit_scheduled_lap", 0)) == 0, "No pit order invented")
	if fails == 0:
		print("DRIVER_IDENTITY_066811_UI_PASS checks=%d no_sporting_mutation=true" % checks)
	quit(0 if fails == 0 else 1)
