extends SceneTree
## Run: godot --headless --path . --script res://tests/car_model_smoke_test.gd
## 06686 QA maintenance: assert current precision mesh nodes, not removed 0653 names.
const CarModelScript = preload("res://scripts/car_model_3d.gd")

func _initialize() -> void:
	call_deferred("_run")

func _mesh_extent(node: Node3D, relative: Transform3D, current: Vector2) -> Vector2:
	# Root-local transforms include wheel spin, steering and body attitude.
	# Exclude graphical annotations, never exclude physical geometry.
	if str(node.name) in ["FocusDisc","PlayerRing","NumberTag"]:
		return current
	var local := relative * node.transform
	if node is MeshInstance3D and node.mesh != null:
		var bounds: AABB = node.mesh.get_aabb()
		for i in range(8):
			var corner := local * bounds.get_endpoint(i)
			current.x = maxf(current.x,absf(corner.x))
			current.y = maxf(current.y,absf(corner.z))
	for child in node.get_children():
		if child is Node3D:
			current = _mesh_extent(child,local,current)
	return current

func _run() -> void:
	var car: Node3D = CarModelScript.new("#d62f30", "Ferrari", 5)
	root.add_child(car)
	await process_frame
	assert(car.get_node_or_null("ChassisVisual/SculptedNose") != null)
	assert(car.get_node_or_null("ChassisVisual/DriverHelmet") != null)
	assert(car.get_node_or_null("ChassisVisual/FrontWingMain") != null)
	assert(car.get_node_or_null("ChassisVisual/RearWingPrimary") != null)
	assert(car.get_node_or_null("FrontLeft/WheelSpin/RoundedSlick") != null)
	assert(car.get_node_or_null("FrontRight/WheelSpin/RoundedSlick") != null)
	assert(car.get_node_or_null("RearLeft/WheelSpin/RoundedSlick") != null)
	assert(car.get_node_or_null("RearRight/WheelSpin/RoundedSlick") != null)
	var wheels: Array = car.get("wheel_spins")
	var pivots: Array = car.get("steering_pivots")
	assert(wheels.size() == 4)
	assert(pivots.size() == 2)
	var start: float = wheels[0].rotation.x
	car.call("update_motion", 0.42, 0.18, 0.12)
	assert(not is_equal_approx(start, wheels[0].rotation.x))
	assert(pivots[0].rotation.y > 0.0)
	# Conservative mesh box over sampled animation extremes, including
	# independently varying wheel rotation, steering and body attitude.
	car.scale = Vector3.ONE * CarModelScript.PRESENTATION_SCALE
	var extent := Vector2.ZERO
	var body: Node3D = car.chassis
	var flap: Node3D = car.drs_flap
	for steering in [-0.27,0.0,0.27]:
		for pitch in [-0.0225,0.0225]:
			for roll in [-0.0297,0.0297]:
				for drs in [-0.48,0.0]:
					for spin_index in range(16):
						for pivot in pivots: pivot.rotation.y = steering
						for wheel in wheels: wheel.rotation.x = TAU*float(spin_index)/16.0
						body.rotation = Vector3(pitch,0,roll)
						body.position.y = 0.009
						flap.rotation.x = drs
						extent = _mesh_extent(car,Transform3D.IDENTITY,extent)
	var margin := Vector2(CarModelScript.OCCUPATION_HALF_WIDTH,CarModelScript.OCCUPATION_HALF_LENGTH)-extent
	print("RACE_MOTION_MESH_BOUNDS ",JSON.stringify({"half_width":extent.x,"half_length":extent.y,"margin_width":margin.x,"margin_length":margin.y}))
	if margin.x < 0.10 or margin.y < 0.10:
		printerr("RACE_MOTION_MESH_BOUNDS_FAIL: padded envelope does not cover sampled geometry")
		quit(1)
		return
	print("APEX CAR MODEL TEST OK: model parts, four wheels, steering, spin")
	quit(0)
