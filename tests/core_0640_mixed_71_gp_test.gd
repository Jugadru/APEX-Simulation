extends SceneTree
## APEX 0.6.4.0 — 71-lap Interlagos, two Ferrari drivers with
## different live pit-wall authorities. This executes the actual race loop.
var errors: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, note: String) -> void:
	if not ok:
		errors.append(note)
		printerr("APEX 0640 MIXED FAIL: ", note)

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.selected_team = "Ferrari"
	game.seed_picker.value = 321
	for i in range(game.season_tracks.size()):
		if str(game.season_tracks[i].get("code", "")) == "BRA":
			game.selected_track_index = i
			break
	game._start_race()
	await process_frame
	check(game.race.lap_count == 71, "must run all 71 laps")
	game.race.configure_weather("Seco")
	var pilots: Array = game.race.player_cars()
	var driver_a: int = int(pilots[0]["id"])
	var driver_b: int = int(pilots[1]["id"])
	var tires: Array = game.race.available_pit_compounds()
	var next_tire: String = str(tires[1])
	check(game.race.schedule_pit(driver_a, next_tire, 23), "book manual V23")
	game._set_engineer_driver_mode(driver_a, "Assistido")
	game._set_engineer_driver_mode(driver_b, "Automático")
	check(str(pilots[0]["pit_control_mode"]) == "Manual", "assisted driver's manual pit")
	check(str(pilots[1]["pit_control_mode"]) == "IA", "automatic driver's AI pit")
	game.race.running = true
	var steps: int = 0
	var scanned: bool = false
	var second_stop: bool = false
	var energy_bounds_ok: bool = true
	while not game.race.finished and steps < 16000:
		game._autonomy_tick()
		game.race.step(4.0)
		steps += 1
		if not scanned and game.race.lap >= 5:
			scanned = true
			check(int(pilots[0].get("pit_scheduled_lap", -1)) == 23, "V23 never fired before V5")
		if not second_stop and game.race.lap >= 30:
			second_stop = true
			check(game.race.schedule_pit(driver_a, str(tires[0]), 48), "book later manual V48")
		for p in pilots:
			if float(p.get("kers_remaining_kj", 0.0)) < -0.001 or float(p.get("kers_remaining_kj", 0.0)) > 400.001:
				energy_bounds_ok = false
	check(game.race.finished, "GP completed")
	check(game.race.finish_results_validated, "classification validated")
	check(energy_bounds_ok, "KERS budget bounds during 71 laps")
	check(scanned and second_stop, "early and second stop checkpoints reached")
	var observed_a: Array[int] = []
	var observed_b: Array[int] = []
	for event in game.race.get_pit_history("Ferrari"):
		if int(event.get("car_id", -1)) == driver_a:
			observed_a.append(int(event.get("lap", -1)))
		if int(event.get("car_id", -1)) == driver_b:
			observed_b.append(int(event.get("lap", -1)))
	check(observed_a == [23,48], "manual pit exact; got " + str(observed_a))
	check(observed_b.size() >= 1, "fully delegated driver stopped automatically")
	var invalid: int = 0
	for car in game.race.cars:
		invalid += int(car.get("invalid_lap_count", 0))
	check(invalid == 0, "0 impossible lap records")
	print("APEX 0640 MIXED GP RESULT ", JSON.stringify({"track": "BRA", "laps":game.race.lap_count,
		"drivers": 24,"clock": game.race.clock,"steps":steps,"manual_pits":observed_a,
		"auto_pits":observed_b,"invalid_laps":invalid,"errors":errors.size()}))
	if errors.is_empty():
		print("APEX 0640 MIXED GP PASS")
		quit(0)
	else:
		quit(1)
