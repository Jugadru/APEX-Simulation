extends SceneTree
## Run: godot --headless --path . --script res://tests/pit_lane_regression_test.gd
## This test specifically exercises the former reverse/teleport pit-stop failure.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	assert(scene != null)
	var app: Node2D = scene.instantiate()
	root.add_child(app)
	await process_frame
	app._start_race()
	app._change_speed(0)
	var pit = app.world_view.pit_complex
	assert(pit != null)
	assert(pit.team_slots.size() == 12)
	assert(pit.team_paths.size() == 12)

	var previous_slot_z := -1000.0
	var checked := 0
	for team in app.teams:
		var name_team: String = str(team["name"])
		var slot: int = pit.slot_for(name_team)
		assert(slot == checked, "Team assigned wrong garage slot")
		var entry_world: Vector3 = pit.position_for_stop(name_team, 0.0)
		var exit_world: Vector3 = pit.position_for_stop(name_team, 1.0)
		var stall_world: Vector3 = pit.stop_position(name_team)
		assert(entry_world.distance_to(pit.to_global(Vector3(0.0, 0.08, 0.0))) < 0.01)
		assert(exit_world.distance_to(pit.to_global(pit.exit_local)) < 0.01)
		assert(stall_world.distance_to(pit.position_for_stop(name_team, 0.50)) < 0.01)
		var stall: Vector3 = pit.to_local(stall_world)
		assert(stall.z > previous_slot_z + 3.0, "Pit garages are reversed or duplicated")
		previous_slot_z = stall.z
		var last_z := -1000.0
		for i in range(101):
			var phase: float = float(i) / 100.0
			var position_local: Vector3 = pit.local_stop_position(name_team, phase)
			assert(position_local.z + 0.08 >= last_z, "Pit path sent car backwards")
			last_z = position_local.z
		checked += 1
	assert(checked == 12)

	var driver: Dictionary = app.race.player_cars()[0]
	var id: int = int(driver["id"])
	var team_name: String = str(driver["team"])
	app.race.order_pit(id, "Duro")
	# Position just BEFORE pit entry to exercise entry detection reliably.
	driver["progress"] = 0.948
	app.race.running = true
	var started := false
	for i in range(20):
		app._process(0.15)
		if float(driver["pit_left"]) > 0.0:
			started = true
			break
	assert(started, "Engine did not trigger pit stop at the entry point")
	assert(int(driver["stops"]) == 1)
	assert(driver["pit_phase"] >= 0.0)
	var track_entry: Vector3 = app.world_view.track_point_to_world(app.map_view.point_on_track(0.950))
	assert(track_entry.distance_to(pit.position_for_stop(team_name, 0.0)) < 0.12)
	var previous_progress := float(driver["progress"])
	var previous_phase := float(driver["pit_phase"])
	var saw_stall := false
	for i in range(310):
		app._process(0.15)
		var progress: float = float(driver["progress"])
		assert(progress >= previous_progress - 0.00001, "Race progress reversed during pit")
		previous_progress = progress
		if float(driver["pit_left"]) <= 0.0:
			break
		var phase: float = float(driver["pit_phase"])
		assert(phase >= previous_phase - 0.00001)
		previous_phase = phase
		if phase > 0.46 and phase < 0.54:
			saw_stall = true
			var car_pos: Vector3 = app.world_view.live_cars[id].global_position
			assert(car_pos.distance_to(pit.stop_position(team_name)) < 0.25, "Car stopped at wrong team garage")
	assert(saw_stall, "Did not observe service stop")
	assert(float(driver["pit_left"]) <= 0.0, "Car did not complete stop")
	var track_exit: Vector3 = app.world_view.track_point_to_world(app.map_view.point_on_track(0.025))
	assert(track_exit.distance_to(pit.position_for_stop(team_name, 1.0)) < 0.12)
	assert(app.race.cars.size() == 24)
	print("APEX PIT 0.5.2.4.3 OK: team slots, forward lane, continuity and timed exit")
	quit(0)
