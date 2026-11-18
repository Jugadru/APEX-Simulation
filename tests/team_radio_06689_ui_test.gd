extends SceneTree
## End-to-end radio HUD: selected driver's teammate comparison cannot mutate race.
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("TEAM_RADIO_UI_06689_FAIL " + why)
func run() -> void:
	var game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._start_race()
	await process_frame
	var hud = game.race_hud_0620
	check(hud != null, "HUD present")
	var rear: Dictionary = game.race.player_cars()[0]
	var ahead: Dictionary = game.race.player_cars()[1]
	var id: int = int(rear.id)
	var compound: String = str(game.race.available_pit_compounds()[0])
	check(game.replay_session.enqueue("schedule_pit", [id, compound, 21], game.replay_session.tick + 1), "V21 queued")
	check(game.replay_session.step_tick(), "Queued V21 applied")
	check(int(rear.get("pit_scheduled_lap", -1)) == 21, "Manual booking present")
	# Mimic established, adjacent teammate positions after valid completed laps.
	rear.position = 7
	ahead.position = 6
	rear.interval = 0.8
	ahead.interval = 1.8
	rear.last_lap = 99.0
	ahead.last_lap = 100.0
	rear.laps_done = 8
	ahead.laps_done = 8
	rear.wear = 38.0
	rear.tire = "Médio"
	rear.driver_soul.team_streak = 3
	hud._open_window("radio")
	var idx: int = hud.radio_driver_ids.find(id)
	check(idx >= 0, "Selected player found")
	hud.radio_driver_picker.select(idx)
	var previous: PackedByteArray = var_to_bytes(game.race.get_state_snapshot())
	var prior_cmds: int = game.replay_session.commands.size()
	hud._compare_teammate()
	var msg: String = str(hud.radio_response_label.text)
	check(msg.contains("1.00s"), "Engineer speaks actual difference")
	check(msg.contains("V21") and msg.contains("permanece"), "Preserves planned pit")
	check(msg.contains("ENGENHEIRO"), "Engineer's answer visible")
	check(previous == var_to_bytes(game.race.get_state_snapshot()), "No sporting mutation")
	check(game.replay_session.commands.size() == prior_cmds, "No replay commands created")
	check(int(rear.pit_scheduled_lap) == 21 and not bool(rear.pit_request), "No unintended BOX")
	if failures == 0:
		print("TEAM_RADIO_UI_06689_PASS checks=%d" % checks)
	quit(0 if failures == 0 else 1)
