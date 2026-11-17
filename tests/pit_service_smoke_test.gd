extends SceneTree
const RaceScript = preload("res://scripts/race_engine.gd")
const PitScript = preload("res://scripts/pit_complex_3d.gd")
## Execute in Godot 4:
## godot --headless --path . --script res://tests/pit_service_smoke_test.gd
## Validates 4 mechanics, wheel exchange, service timer and same pit duration.

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
	var driver: Dictionary = app.race.player_cars()[0]
	var id: int = int(driver["id"])
	var team_name: String = str(driver["team"])
	var old_tire: String = str(driver["tire"])
	var new_tire: String = "Duro" if old_tire != "Duro" else "Macio"
	var pit = app.world_view.pit_complex
	assert(pit != null)
	assert(pit.team_slots.size() == 12)
	assert(pit.crew_rigs.size() == 12)
	var slot: int = pit.slot_for(team_name)
	assert(slot >= 0)
	assert(pit.crew_rigs[slot].size() == 4, "Each garage must have four active wheel mechanics")
	assert(is_equal_approx(float(RaceScript.PIT_SERVICE_BEGIN), float(PitScript.STOP_START)))
	assert(is_equal_approx(float(RaceScript.PIT_SERVICE_END), float(PitScript.STOP_END)))
	app.race.order_pit(id, new_tire)
	driver["progress"] = 0.948
	app.race.running = true
	var started: bool = false
	var crew_seen: bool = false
	var wheel_swap_seen: bool = false
	var stopwatch_seen: bool = false
	var service_seen: bool = false
	for i in range(400):
		app._process(0.15)
		if float(driver["pit_left"]) > 0.0:
			started = true
			var phase: float = float(driver["pit_phase"])
			if phase < float(pit.STOP_END):
				assert(str(driver["tire"]) == old_tire, "Tyre changed before service completed")
			if phase >= float(pit.STOP_START) and phase < float(pit.STOP_END):
				service_seen = true
				assert(float(driver["pit_service_elapsed"]) >= 0.0)
				assert(float(driver["pit_service_elapsed"]) <= float(driver["pit_service_total"]) + 0.01)
				crew_seen = crew_seen or pit.crew_by_slot[slot].visible
				stopwatch_seen = stopwatch_seen or app.pit_timer_label.text.contains("BOX ")
				var model: Node3D = app.world_view.live_cars[id]
				for spin in model.wheel_spins:
					if not spin.visible:
						wheel_swap_seen = true
		if started and float(driver["pit_left"]) <= 0.0:
			break
	assert(started, "Pit stop never started")
	assert(service_seen and crew_seen and wheel_swap_seen, "Animated service not observed")
	assert(stopwatch_seen, "HUD stopwatch was not updated")
	assert(bool(driver["pit_service_complete"]))
	assert(str(driver["tire"]) == new_tire)
	assert(float(driver["pit_last_service"]) > 2.0)
	assert(int(driver["stops"]) == 1)
	assert(app.race.cars.size() == 24)
	print("APEX 0.5.2.5 OK: 12 garages, 4 mechanics, 4 wheel swap, HUD timer, unchanged pit duration")
	quit(0)
