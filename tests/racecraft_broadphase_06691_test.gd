extends SceneTree
## APEX 0.6.6.9.1 — equivalence to pre-optimization visual sweep.
## No RaceEngine writes, no global RNG and no saved state changes.
const R = preload("res://scripts/apex_racecraft_0654.gd")
const SEED := 66091
const RANDOM_CASES := 16000
var tested: int = 0
var positives: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _pose(point: Vector2, angle: float) -> Dictionary:
	return {"position": point, "direction": Vector2(cos(angle), sin(angle)), "lane": 0.0}

func _reference_swept(a0: Dictionary,a1: Dictionary,b0: Dictionary,b1: Dictionary) -> bool:
	# Unmodified v0.6.6.9.0 algorithm; this test guards bit-for-bit booleans.
	if R.overlaps(a0,b0): return R.overlaps(a1,b1)
	var start: Vector2 = a0.position-b0.position
	var velocity: Vector2 = (a1.position-b1.position)-start
	var closest := clampf(-start.dot(velocity)/maxf(.000001,velocity.length_squared()),0,1)
	if (start+velocity*closest).length_squared()>40.0: return false
	var enter := 0.0
	var leave := 1.0
	for axis in [a0.direction,R.normal(a0.direction),b0.direction,R.normal(b0.direction),a1.direction,R.normal(a1.direction),b1.direction,R.normal(b1.direction)]:
		var extent0 := R.radius(a0,axis)+R.radius(b0,axis)
		var extent1 := R.radius(a1,axis)+R.radius(b1,axis)
		var growth := extent1-extent0
		var d := start.dot(axis)
		var v := velocity.dot(axis)
		for side in [-1.0,1.0]:
			var origin: float = side*d-extent0
			var speed: float = side*v-growth
			if absf(speed)<.00001:
				if origin>=0: return false
			elif speed>0:
				leave = minf(leave,-origin/speed)
			else:
				enter = maxf(enter,-origin/speed)
			if enter>=leave: return false
	return enter<leave and leave>0 and enter<1

func _compare(a0: Dictionary, a1: Dictionary, b0: Dictionary, b1: Dictionary, name: String) -> void:
	var reference: bool = _reference_swept(a0,a1,b0,b1)
	var candidate: bool = R.swept(a0,a1,b0,b1)
	tested += 1
	if reference: positives += 1
	if reference != candidate:
		failures += 1
		if failures <= 6:
			printerr("RACECRAFT_BROADPHASE_06691_MISMATCH ", name, " reference=",reference," candidate=",candidate, " a0=",a0.position," a1=",a1.position," b0=",b0.position," b1=",b1.position)

func _run() -> void:
	# High-speed crossing and intersecting-path edge cases must NOT be culled.
	_compare(_pose(Vector2(-45, 0), 0), _pose(Vector2(45, 0), 0),
		_pose(Vector2.ZERO, 0), _pose(Vector2.ZERO, 0), "crossing_x")
	_compare(_pose(Vector2(0, -45), PI / 2), _pose(Vector2(0, 45), PI / 2),
		_pose(Vector2.ZERO, 0), _pose(Vector2.ZERO, 0), "crossing_y")
	_compare(_pose(Vector2(-45, -45), PI / 4), _pose(Vector2(45, 45), PI / 4),
		_pose(Vector2(25, 0), 0), _pose(Vector2(25, 0), 0), "diagonal")
	_compare(_pose(Vector2(50, 50), PI / 3), _pose(Vector2(55, 50), PI / 3),
		_pose(Vector2(-50, -50), 0), _pose(Vector2(-55, -50), 0), "far")
	_compare(_pose(Vector2.ZERO, 0), _pose(Vector2(1, 0), 0),
		_pose(Vector2(2.5, 0), PI / 2), _pose(Vector2(2.0, 0), PI / 2), "near")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for i in range(RANDOM_CASES):
		var mode: int = i % 4
		var span: float = 7.5 if mode == 0 else (45.0 if mode == 1 else 105.0)
		var speed: float = 1.5 if mode == 0 else (25.0 if mode == 1 else 110.0)
		var a_start := Vector2(rng.randf_range(-span,span),rng.randf_range(-span,span))
		var b_start := Vector2(rng.randf_range(-span,span),rng.randf_range(-span,span))
		var a_finish := a_start + Vector2(rng.randf_range(-speed,speed),rng.randf_range(-speed,speed))
		var b_finish := b_start + Vector2(rng.randf_range(-speed,speed),rng.randf_range(-speed,speed))
		_compare(
			_pose(a_start,rng.randf_range(-PI,PI)),
			_pose(a_finish,rng.randf_range(-PI,PI)),
			_pose(b_start,rng.randf_range(-PI,PI)),
			_pose(b_finish,rng.randf_range(-PI,PI)),
			"seeded_%d" % i
		)
	if failures > 0:
		printerr("RACECRAFT_BROADPHASE_06691_FAIL ",JSON.stringify({"seed":SEED,"tested":tested,"positives":positives,"failures":failures}))
		quit(1)
		return
	print("RACECRAFT_BROADPHASE_06691_PASS ",JSON.stringify({"seed":SEED,"tested":tested,"positives":positives,"mismatches":0}))
	quit(0)
