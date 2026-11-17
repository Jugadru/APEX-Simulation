extends SceneTree
const Track3D = preload("res://scripts/track_3d.gd")
const FRAMES := 120

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world: Node3D = Track3D.new()
	root.add_child(world)
	await process_frame
	var ring := PackedVector2Array()
	for i in range(100):
		var angle: float = TAU * float(i) / 100.0
		ring.append(Vector2(430.0 * cos(angle), 270.0 * sin(angle)))
	ring.append(ring[0])
	var teams: Array = []
	for team_i in range(12):
		teams.append({"name":"Equipe%02d" % team_i, "color":"#cbd4db"})
	world.set_track_data(ring, "Monza", teams)
	var samples: Array = []
	for frame_i in range(FRAMES + 12):
		var cars: Array = []
		for n in range(24):
			var p: float = fposmod(float(n) / 24.0 + float(frame_i) * .000007, 1.0)
			cars.append({"id":n, "grid":n+1, "team":"Ferrari" if n < 2 else "Rival", "color":"#e23832" if n < 2 else "#c9d3d6", "progress":p, "route_point":world._point_on_route(p), "route_direction":world._direction_on_route(p), "pit_left":0.0, "pit_stage":"none", "pit_phase":0.0, "drs_active":n%2==0, "tire":"Médio", "combat_state":"clear", "combat_target_id":-1, "player":n<2, "race_lane":0.0})
		samples.append(cars)
	var total_us: int = 0
	for frame_i in range(FRAMES + 12):
		var now: int = Time.get_ticks_usec()
		world.set_race_cars(samples[frame_i], 0, 0.016)
		if frame_i >= 12:
			total_us += Time.get_ticks_usec() - now
	assert(world.live_cars.size() == 24)
	assert(world.models_created == 24)
	var marked: int = 0
	var selected: int = 0
	for key in world.live_cars:
		var model: Node3D = world.live_cars[key]
		assert(model.has_node("QueueTag"))
		assert(model.has_node("FocusDisc"))
		assert(model.has_node("PlayerRing"))
		assert(model.has_node("NumberTag"))
		if (model.get_node("FocusDisc") as MeshInstance3D).visible: selected += 1
		marked += 1
	assert(marked == 24 and selected == 1)
	print("APEX_06685_3D_BENCH PASS total_us=%d frames=%d avg_us=%.3f models=%d focus=%d" % [total_us, FRAMES, float(total_us)/FRAMES, world.models_created, selected])
	quit(0)
