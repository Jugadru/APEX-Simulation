extends SceneTree
const Snapshot = preload("res://scripts/race_view_snapshot_0658.gd")
class Route extends RefCounted:
	var calls := 0
	func point_on_track(p: float) -> Vector2:
		calls += 1
		return Vector2(fposmod(p, 1), 0)
	func direction_on_track(_p: float) -> Vector2: return Vector2.RIGHT
func _initialize() -> void:
	var state := Snapshot.new()
	var route := Route.new()
	var cars := [{"id":1,"team":"Ferrari","progress":0.999,"race_lane":0.0,"pit_stage":"none","pit_left":0.0,"finished":false,"history":[{"a":1}]}]
	var initial := state.build(cars,"Ferrari",route,1.0/60,true)
	assert(initial.is_read_only() and initial[0].is_read_only())
	assert(not initial[0].has("history"))
	var revision := state.revision
	state.build(cars,"Ferrari",route,1.0/60,false)
	assert(state.revision == revision and route.calls == 1)
	cars[0].progress = 1.001
	cars[0].race_lane = 2.5
	var source := JSON.stringify(cars)
	var frames := state.build(cars,"Ferrari",route,1.0/60,true)
	assert(float(frames[0].progress)>0.999 and float(frames[0].progress)<1.001)
	assert(float(frames[0].race_lane)>0 and float(frames[0].race_lane)<2.5)
	assert(JSON.stringify(cars)==source and initial[0].progress==0.999)
	var frozen: float = frames[0].progress
	for i in range(10):
		assert(state.build(cars,"Ferrari",route,1.0/60,false)[0].progress==frozen)
	cars[0].pit_stage="entry"
	cars[0].pit_left=30.0
	assert(state.build(cars,"Ferrari",route,1.0/60,true)[0].progress==1.001)
	cars[0].progress=0.1 # seek/new session resets, never lerp backwards across circuit
	assert(state.build(cars,"Ferrari",route,1.0/60,true)[0].progress==0.1)
	assert(state.build([],"Ferrari",route,1.0/60,true).is_empty())
	state.reset()
	assert(state.by_id.is_empty() and state.targets.is_empty())
	print("VIEW_UNIT_PASS detached immutable contract, wrap, pause, pit discontinuity, seek, removal, reset")
	quit()
