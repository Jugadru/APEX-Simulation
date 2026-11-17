extends SceneTree
const Track3D = preload("res://scripts/track_3d.gd")
var count := 0
func _check(value: bool, reason: String) -> void:
	if not value:
		push_error(reason)
		quit(1)
		assert(false, reason)
	count += 1
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var world: Node3D = Track3D.new()
	root.add_child(world)
	await process_frame
	var route := PackedVector2Array()
	for i in range(100):
		var theta := TAU * float(i) / 100.0
		route.append(Vector2(430*cos(theta), 280*sin(theta)))
	route.append(route[0])
	var teams: Array = []
	for i in range(12): teams.append({"name":"Equipe%02d" % i, "color":"#e23d37"})
	world.set_track_data(route, "Monza", teams)
	var cars: Array = []
	for i in range(24):
		var p := float(i) / 24.0
		cars.append({"id":i,"team":"Equipe%02d" % (i%12),"color":"#e23d37","progress":p,"route_point":world._point_on_route(p),"route_direction":world._direction_on_route(p),"pit_stage":"none","pit_left":0.0,"pit_phase":0.0,"pit_wait":0.0,"drs_active":false,"tire":"Médio","combat_state":"clear","combat_target_id":-1,"race_lane":0.0,"player":i<2})
	world.set_race_cars(cars, 0, .016)
	_check(world.models_created == 24, "should create 24 models")
	_check(world.marker_cache.size() == 24, "24 marker refs")
	var marker := world.marker_cache[0]["queue"] as Label3D
	var marker_id := marker.get_instance_id()
	world.set_race_cars(cars, 1, .016)
	_check(world.marker_cache[0]["queue"].get_instance_id() == marker_id, "stable label identity")
	_check((world.live_cars[1].get_node("FocusDisc") as MeshInstance3D).visible, "focused pilot visible")
	_check(not (world.live_cars[0].get_node("FocusDisc") as MeshInstance3D).visible, "old focus hidden")
	var pit_cars: Array = cars.duplicate(true)
	pit_cars[0]["pit_left"] = 1.0
	pit_cars[0]["pit_phase"] = .50
	pit_cars[0]["pit_stage"] = "service"
	pit_cars[0]["pit_service_total"] = 3.5
	pit_cars[0]["pit_service_elapsed"] = 1.5
	world.set_race_cars(pit_cars, 0, .016)
	var wheels: Array = world.live_cars[0].wheel_spins
	for wheel in wheels: _check(not wheel.visible, "wheels briefly hidden during service")
	_check(world.live_cars[0].pit_wheels_visible == false, "wheel state tracked")
	_check(world.pit_complex.crew_by_slot[0].visible, "crew shown on active service")
	world.set_race_cars(pit_cars, 0, .016)
	for wheel in wheels: _check(not wheel.visible, "wheel hiding persists during service")
	world.set_race_cars(cars, 0, .016)
	for wheel in wheels: _check(wheel.visible, "wheels restored after pit")
	_check(world.pit_complex.crew_by_slot[0].visible == false, "crew hidden after service")
	_check(world.pit_complex.service_frames.is_empty(), "service frames cleared")
	world.set_race_cars(cars, 0, .016)
	_check(world.pit_complex.crew_by_slot[0].visible == false, "idle update leaves crew hidden")
	var smaller: Array = cars.slice(0, 23)
	world.set_race_cars(smaller, 0, .016)
	_check(world.live_cars.size() == 23, "old car removed")
	_check(world.marker_cache.size() == 23, "marker refs pruned")
	world.set_track_data(route,"Monza",teams)
	_check(world.marker_cache.is_empty(), "reset clears marker refs")
	world.set_race_cars(cars,0,.016)
	_check(world.marker_cache.size() == 24, "refs rebuilt for next race")
	print("APEX_06685_3D_VISUAL PASS checks=%d" % count)
	quit(0)
