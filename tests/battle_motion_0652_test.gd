extends SceneTree
const Motion = preload("res://tests/legacy/apex_battle_motion_0652.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL ",message)
func _initialize() -> void:
	var cars := [{"id":0,"progress":0.1,"route_point":Vector2(0,0),"route_direction":Vector2.RIGHT,"combat_state":"attacking","combat_target_id":1},
		{"id":1,"progress":0.101,"route_point":Vector2(4,0),"route_direction":Vector2.RIGHT,"combat_state":"clear"}]
	var before := JSON.stringify(cars)
	var offsets := Motion.targets(cars)
	check(offsets[0] == 1.55 and offsets[1] == -1.55,"paired attack separates cars")
	check(JSON.stringify(cars)==before,"input immutable")
	check(Motion.advance(1.0,0,0)==1.0,"paused animation frozen")
	var a := 0.0
	var b := 0.0
	for i in range(30): a = Motion.advance(a,1.55,1.0/30.0)
	for i in range(60): b = Motion.advance(b,1.55,1.0/60.0)
	check(absf(a-b)<0.00001,"FPS independent")
	cars[0].combat_state = "recovering"
	check(Motion.targets(cars)[0] == 0.0,"return to line")
	check(Motion.targets(cars,{0:1.55,1:-1.55})[0] == 1.55,"hold lane until bodies clear")
	cars[0].combat_state = "duel"
	cars[1]["pit_left"] = 3.0
	check(Motion.targets(cars)[0] == 0.0,"pit excluded")
	cars[1].pit_left = 0
	cars[1].route_direction = Vector2.LEFT
	check(Motion.targets(cars)[0] == 0.0,"opposing section excluded")
	cars[1].route_direction = Vector2.RIGHT
	cars[1].progress = 1.101
	check(Motion.targets(cars)[0] == 0.0,"remote lap excluded")
	cars[1].progress = 0.101
	cars[1].route_point = Vector2(100,0)
	check(Motion.targets(cars)[0] == 0.0,"remote target excluded")
	var model = load("res://scripts/car_model_3d.gd").new("#c82030","Test",1)
	root.add_child(model)
	model.update_motion(1.0,0.2,0.1)
	model.set_race_animation(true,0.2)
	check(model.drs_angle < -0.3,"DRS opens")
	check(model.wheel_spins[0].rotation.x > 0,"wheels rotate")
	var paused := [model.drs_angle, model.wheel_spins[0].rotation.x, model.chassis.position.y, model.chassis.rotation.x]
	model.update_motion(4.0,-0.2,0.0)
	model.set_race_animation(false,0.0)
	check(paused == [model.drs_angle, model.wheel_spins[0].rotation.x, model.chassis.position.y, model.chassis.rotation.x],"whole model frozen on pause")
	model.set_race_animation(false,1.0)
	check(absf(model.drs_angle)<0.001,"DRS closes")
	model.free()
	if failures == 0: print("BATTLE_MOTION_PASS pair / recovery / pause / FPS / pit / lap / opposite / immutable")
	quit(0 if failures == 0 else 1)
