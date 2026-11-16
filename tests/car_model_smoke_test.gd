extends SceneTree
## Run: godot --headless --path . --script res://tests/car_model_smoke_test.gd
const CarModelScript = preload("res://scripts/car_model_3d.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var car: Node3D = CarModelScript.new("#d62f30", "Ferrari", 5)
	root.add_child(car)
	await process_frame
	assert(car.get_node_or_null("ChassisVisual/TaperedChassis") != null)
	assert(car.get_node_or_null("ChassisVisual/DriverHelmet") != null)
	assert(car.get_node_or_null("ChassisVisual/FrontWingMain") != null)
	assert(car.get_node_or_null("ChassisVisual/RearWingPrimary") != null)
	assert(car.get_node_or_null("FrontLeft/WheelSpin/Rubber") != null)
	assert(car.get_node_or_null("FrontRight/WheelSpin/Rubber") != null)
	assert(car.get_node_or_null("RearLeft/WheelSpin/Rubber") != null)
	assert(car.get_node_or_null("RearRight/WheelSpin/Rubber") != null)
	var wheels: Array = car.get("wheel_spins")
	var pivots: Array = car.get("steering_pivots")
	assert(wheels.size() == 4)
	assert(pivots.size() == 2)
	var start: float = wheels[0].rotation.x
	car.call("update_motion", 0.42, 0.18, 0.12)
	assert(not is_equal_approx(start, wheels[0].rotation.x))
	assert(pivots[0].rotation.y > 0.0)
	print("APEX CAR MODEL TEST OK: model parts, four wheels, steering, spin")
	quit(0)
