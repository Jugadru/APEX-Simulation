extends SceneTree
## Real radio HUD: player must authorize and may cancel in the following tick.
var checks := 0
var fails := 0
func _initialize() -> void: call_deferred("run")
func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		printerr("TEAM_ORDERS_066810_UI_FAIL: " + label)
func run() -> void:
	var game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._start_race()
	await process_frame
	var hud = game.race_hud_0620
	verify(hud != null, "Live HUD")
	var rear: Dictionary = game.race.player_cars()[0]
	var leader: Dictionary = game.race.player_cars()[1]
	var rid: int = int(rear.id)
	var lid: int = int(leader.id)
	var compound: String = str(game.race.available_pit_compounds()[0])
	verify(game.replay_session.enqueue("schedule_pit", [rid, compound, 21], 1), "V21 queue")
	verify(game.replay_session.step_tick(), "Pit command applies")
	verify(int(rear.pit_scheduled_lap) == 21, "V21 booked")
	rear.position = 2
	leader.position = 1
	rear.progress = 0.394
	leader.progress = 0.397
	rear.interval = 0.8
	leader.interval = 0.0
	rear.last_lap = 99.0
	leader.last_lap = 100.0
	rear.laps_done = 9
	leader.laps_done = 9
	rear.wear = 37.0
	rear.tire = "Médio"
	rear.driver_soul.team_streak = 3
	hud._open_window("radio")
	var index: int = hud.radio_driver_ids.find(rid)
	verify(index >= 0, "Rear driver selectable")
	hud.radio_driver_picker.select(index)
	var before: PackedByteArray = var_to_bytes(game.race.get_state_snapshot())
	var count: int = game.replay_session.commands.size()
	hud._compare_teammate()
	verify(game.replay_session.commands.size() == count, "Advice is read-only")
	verify(var_to_bytes(game.race.get_state_snapshot()) == before, "Consultation cannot move cars")
	hud._authorize_teammate_pass()
	verify(game.replay_session.commands.size() == count + 1, "Explicit click queues authorization")
	verify(str(hud.radio_response_label.text).contains("ORDEM ENFILEIRADA"), "Reports pending action")
	verify(int(leader.team_yield_ticks) == 0, "No premature application")
	verify(game.replay_session.step_tick(), "Authorization applies next tick")
	verify(int(leader.team_yield_ticks) > 0 and int(leader.team_yield_to_id) == rid, "Leader granted 15s window")
	verify(int(rear.pit_scheduled_lap) == 21 and not bool(rear.pit_request), "V21 intact")
	count = game.replay_session.commands.size()
	hud._cancel_teammate_pass()
	verify(game.replay_session.commands.size() == count + 1, "Cancellation queues")
	verify(str(hud.radio_response_label.text).contains("CANCELAMENTO ENFILEIRADO"), "Reports pending cancellation")
	verify(game.replay_session.step_tick(), "Cancellation applies next tick")
	verify(int(leader.team_yield_ticks) == 0 and int(leader.team_yield_to_id) == -1, "Authorization canceled")
	verify(int(rear.pit_scheduled_lap) == 21 and not bool(rear.pit_request), "Canceled without touching V21")
	if fails == 0: print("TEAM_ORDERS_066810_UI_PASS checks=%d" % checks)
	quit(0 if fails == 0 else 1)
