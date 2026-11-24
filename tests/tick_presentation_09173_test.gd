extends SceneTree
const Snapshot = preload("res://scripts/race_view_snapshot_0658.gd")
class Route extends RefCounted:
	func point_on_track(progress: float) -> Vector2: return Vector2(progress*1000.0,0.0)
	func direction_on_track(_progress: float) -> Vector2: return Vector2.RIGHT
	func geometry_revision() -> int: return 1
var failures := 0
func check(ok: bool, reason: String) -> void:
	if not ok:
		failures+=1
		printerr("TICK_PRESENTATION_09173_FAIL ",reason)
func _initialize() -> void: call_deferred("run")
func car(progress: float,lane: float,stage: String="none") -> Dictionary:
	return {"id":1,"team":"Ferrari","progress":progress,"race_lane":lane,"pit_stage":stage,"pit_left":0.0,"finished":false}
func run() -> void:
	var route := Route.new()
	var snap := Snapshot.new()
	var cars: Array = [car(0.0,0.0)]
	snap.capture_completed_tick(cars)
	snap.build(cars,"Ferrari",route,0.0,false,0.0)
	for i in range(1,4):
		cars=[car(float(i)*0.01,float(i)*0.2)]
		snap.capture_completed_tick(cars)
	var before := var_to_bytes(cars)
	var view := snap.build(cars,"Ferrari",route,0.5,true,0.5)
	check(is_equal_approx(float(view[0].progress),0.025),"three ticks: use tick 2 and 3, not render 0 and 3")
	check(is_equal_approx(float(view[0].race_lane),0.5),"lane interpolation uses real adjacent ticks")
	check(var_to_bytes(cars)==before,"input immutable")
	var paused := snap.build(cars,"Ferrari",route,1.0,false,0.5)
	check(is_equal_approx(float(paused[0].progress),0.025),"pause preserves pose")
	cars=[car(0.04,0.8,"entry")]
	snap.capture_completed_tick(cars)
	view=snap.build(cars,"Ferrari",route,0.1,true,0.1)
	check(is_equal_approx(float(view[0].progress),0.04),"pit discontinuity not interpolated")
	snap.reset()
	check(snap.completed_targets.is_empty() and snap.preceding_completed_targets.is_empty(),"reset discards both ticks")
	print("TICK_PRESENTATION_09173_REPORT ",JSON.stringify({"failures":failures,"checks":6}))
	if failures==0: print("TICK_PRESENTATION_09173_PASS")
	quit(0 if failures==0 else 1)
