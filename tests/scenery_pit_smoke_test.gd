extends SceneTree
## Run: godot --headless --path . --script res://tests/scenery_pit_smoke_test.gd

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
	assert(app.race.cars.size() == 24)
	assert(app.world_view.pit_complex != null)
	assert(app.world_view.pit_complex.team_slots.size() == 12)
	assert(app.world_view.course_root.get_child_count() > 9)
	app._process(0.05)
	var driver: Dictionary = app.race.player_cars()[0]
	var id: int = int(driver["id"])
	app.race.order_pit(id, "Médio")
	driver["progress"] = 0.949
	app.race.running = true
	for i in range(15):
		app._process(0.2)
		if float(driver["pit_left"]) > 0.0:
			break
	assert(float(driver["pit_left"]) > 0.0)
	assert(app.world_view.pit_visual_phase.has(id), "3D pit state was not rendered")
	assert(app.world_view.pit_complex.active_teams.has(str(driver["team"])))
	var position_2d: Vector2 = app.map_view.point_on_track(float(driver["progress"]))
	var direction_2d: Vector2 = app.map_view.direction_on_track(float(driver["progress"]))
	app.world_view.set_broadcast_view(position_2d, direction_2d, null, "pit", 0.1, id)
	assert(app.world_view.camera_mode_3d == "pit")
	app._change_speed(2)
	assert(app.render_mode == 0)
	print("APEX CIRCUIT LIFE OK: team garages, active mechanics, pit shot and 2D fallback")
	quit(0)
