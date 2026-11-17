extends SceneTree
# Ensures the optimized fast path and the fallback sort have identical results
# when callers send sorted / shuffled / tied or inactive sporting snapshots.
const Race = preload("res://scripts/race_engine.gd")
const Space = preload("res://scripts/core/race_space_0655.gd")
var checks := 0
func _initialize() -> void:
	call_deferred("_run")
func _check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		push_error("06686_SORT_CONTRACT_FAIL: " + why)
		quit(1)
func _run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for t in data.tracks:
		if str(t.code) == "ITA": track = t
	var engine = Race.new(data.teams,"Ferrari",660,{},track,{})
	var cars: Array = engine.get_sorted()
	var metrics: Dictionary = {}
	for c in cars: metrics[int(c.id)] = {"target": 84.0}
	var baseline: Dictionary = Space.plan(cars,metrics,0.2,track,engine.space_profile,{})
	var reversed: Array = cars.duplicate()
	reversed.reverse()
	var unordered: Dictionary = Space.plan(reversed,metrics,0.2,track,engine.space_profile,{})
	_check(baseline == unordered,"unordered grid changed resolved positions")
	var tied: Array = cars.duplicate(true)
	for n in range(5): tied[n].progress = 0.15
	var tied_metrics: Dictionary = {}
	for c in tied: tied_metrics[int(c.id)]={"target":84.0}
	tied.sort_custom(func(a,b): return float(a.progress)>float(b.progress) if a.progress!=b.progress else int(a.id)<int(b.id))
	var tied_expected: Dictionary = Space.plan(tied,tied_metrics,0.2,track,engine.space_profile,{})
	tied.reverse()
	_check(tied_expected == Space.plan(tied,tied_metrics,0.2,track,engine.space_profile,{}),"equal progress / tie ordering differs")
	var inactive: Array = cars.duplicate(true)
	inactive[2].finished = true
	inactive[4].pit_left = 2.0
	var active_metrics: Dictionary = {}
	for c in inactive: active_metrics[int(c.id)]={"target":84.0}
	var expected: Dictionary = Space.plan(inactive,active_metrics,0.2,track,engine.space_profile,{})
	inactive.reverse()
	_check(expected == Space.plan(inactive,active_metrics,0.2,track,engine.space_profile,{}),"inactive cars reorder unexpectedly")
	_check(baseline.size()==24,"expected 24 original cars")
	print("CORE2_06686_SORT_CONTRACT_PASS checks=%d" % checks)
	quit(0)
