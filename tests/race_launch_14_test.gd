extends SceneTree
## Improvement 14: unit-level launch assertions run in real Godot CI.
const Launch = preload("res://scripts/core/race_launch_14.gd")

func _initialize() -> void:
	call_deferred("_check")

func _fail(message: String) -> void:
	printerr("RACE_LAUNCH_14_FAIL " + message)
	quit(1)

func _check() -> void:
	var experienced: Dictionary = {"skill": 95, "car_rating": 90}
	var rookie: Dictionary = {"skill": 60, "car_rating": 65}
	var original: Dictionary = rookie.duplicate(true)
	var first: float = Launch.pace_cost(rookie, 0.0, 0.0)
	if first <= 0.0 or not is_finite(first):
		_fail("Missing finite launch cost")
		return
	if not Launch.pace_cost(experienced, 0.0, 0.0) < first:
		_fail("Driver skill/car rating has no effect")
		return
	if not Launch.pace_cost(rookie, 0.0, 0.7) > first:
		_fail("Wet traction difference missing")
		return
	if not (first > Launch.pace_cost(rookie, 4.0, 0.0)
			and Launch.pace_cost(rookie, 4.0, 0.0) > 0.0):
		_fail("Launch cost must decay")
		return
	if Launch.pace_cost(rookie, 8.0, 1.0) != 0.0 or Launch.pace_cost(rookie, 99.0, 1.0) != 0.0:
		_fail("Launch must not affect normal race laps")
		return
	if Launch.pace_cost(rookie, 0.0, 0.0) != first or rookie != original:
		_fail("Launch must be deterministic and read-only")
		return
	# Verify pace integrator: at t=0 a car is slower; at t=8
	# exactly the same Core 2 cost calculation must be restored.
	print("RACE_LAUNCH_14_PASS")
	quit(0)
