extends SceneTree
const Adapter = preload("res://experimental/hyper22/longitudinal_adapter.gd")
var checks: int = 0
var failures: int = 0

func verify(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("HYPER22_FAIL " + label)

func observation(speed: float, target: float, grip: float = 1.0) -> Dictionary:
	return {"stage": "TRACK", "launch_active": false, "speed_mps": speed,
		"target_mps": target, "traction": grip, "driving_dt_s": 0.2, "previews": []}

func _initialize() -> void:
	var input: Dictionary = observation(20.0, 80.0)
	var before: Dictionary = input.duplicate(true)
	var p: Dictionary = Adapter.propose(input)
	verify(bool(p.ok), "valid proposal")
	verify(input == before, "observation immutable")
	verify(is_equal_approx(float(p.speed_mps), 21.7), "constant acceleration oracle")
	verify(is_equal_approx(float(p.distance_m), 4.17), "trapezoidal distance oracle")
	var cruise: Dictionary = Adapter.propose(observation(50.0, 50.0))
	verify(is_equal_approx(float(cruise.distance_m), 10.0), "cruise")
	var brake: Dictionary = Adapter.propose(observation(60.0, 20.0))
	var wet: Dictionary = Adapter.propose(observation(60.0, 20.0, 0.5))
	verify(float(brake.speed_mps) < 60.0 and float(brake.speed_mps) > 20.0, "finite braking")
	verify(float(wet.speed_mps) > float(brake.speed_mps), "wet braking limit")
	var preview: Dictionary = observation(70.0, 90.0, 0.6)
	preview.previews = [{"distance_m": 25.0, "speed_mps": 30.0}]
	var approaching: Dictionary = Adapter.propose(preview)
	verify(float(approaching.target_mps) < 50.0, "forward braking preview")
	verify(float(approaching.speed_mps) > float(approaching.target_mps), "preview not teleport")
	preview.previews = [{"distance_m": 25.0, "speed_mps": 30.0}, {"distance_m": 0.0, "speed_mps": 20.0}]
	verify(is_equal_approx(float(Adapter.propose(preview).target_mps), 20.0), "strictest constraint")
	var settled: Dictionary = Adapter.settle(p, float(p.distance_m), "TRACK")
	verify(is_equal_approx(float(settled.speed_mps), float(p.speed_mps)), "unrestricted terminal speed")
	var blocked: Dictionary = Adapter.settle(p, 0.4, "TRACK")
	verify(bool(blocked.solver_restricted) and is_equal_approx(float(blocked.speed_mps), 2.0), "solver authority")
	verify(not bool(Adapter.settle(p, float(p.distance_m) + 0.1, "TRACK").ok), "reject extra progress")
	verify(bool(Adapter.settle(p, float(p.distance_m) + 0.0005, "TRACK").ok), "mm rounding allowance")
	verify(not bool(Adapter.settle(p, -0.1, "TRACK").ok), "reject reverse")
	verify(bool(Adapter.settle(p, 0.0, "PIT").bypass), "pit transition bypass")
	var launch: Dictionary = observation(0.0, 50.0)
	launch.launch_active = true
	verify(bool(Adapter.propose(launch).bypass), "launch bypass")
	launch.launch_active = false
	launch.stage = "FINISHED"
	verify(bool(Adapter.propose(launch).bypass), "finished bypass")
	verify(not bool(Adapter.propose(observation(NAN, 20.0)).ok), "reject NaN")
	verify(not bool(Adapter.propose(observation(20.0, 101.0)).ok), "reject excess target")
	verify(not bool(Adapter.propose(observation(20.0, 50.0, 0.0)).ok), "reject invalid grip")
	var zero: Dictionary = observation(20.0, 80.0)
	zero.driving_dt_s = 0.0
	verify(is_zero_approx(float(Adapter.propose(zero).distance_m)), "zero driving interval")
	var trial_a: Array = run_fixture()
	var trial_b: Array = run_fixture()
	verify(trial_a == trial_b, "24-car isolated fixture deterministic")
	verify(trial_a.size() == 24, "24 actors, not a full GP")
	if failures == 0:
		print("HYPER22_LONGITUDINAL_PASS checks=%d" % checks)
	quit(0 if failures == 0 else 1)

func run_fixture() -> Array:
	var output: Array = []
	for actor in range(24):
		var speed: float = 20.0 + float(actor) * 0.5
		var distance: float = 0.0
		for tick in range(100):
			var target: float = 75.0 if tick < 60 else 35.0
			var p: Dictionary = Adapter.propose(observation(speed, target, 0.55 if actor % 2 == 0 else 1.0))
			var accepted: Dictionary = Adapter.settle(p, float(p.distance_m), "TRACK")
			speed = float(accepted.speed_mps)
			distance += float(accepted.distance_m)
		output.append([speed, distance])
	return output
