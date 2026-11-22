extends SceneTree
## v9.9 regression: Monaco fixed-seed narrow-lane traffic must never freeze
## two side-by-side cars at the same progress. Synthetic spatial contract only.
const RaceSpace = preload("res://scripts/core/race_space_0655.gd")
var errors: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func verify(ok: bool, detail: String) -> void:
	if not ok:
		errors.append(detail)
		printerr("APEX_MONACO_DEADLOCK_099_FAIL " + detail)
func _run() -> void:
	var season: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/season_2012.json"))
	verify(season is Dictionary, "season data is required")
	if not (season is Dictionary):
		quit(1)
		return
	var track: Dictionary = {}
	for candidate in season["tracks"]:
		if str(candidate.get("code", "")) == "MON":
			track = candidate.duplicate(true)
			break
	verify(not track.is_empty(), "real 2012 Monaco track must exist")
	if track.is_empty():
		quit(1)
		return
	var shape: Dictionary = RaceSpace.profile(track)
	var start: float = 7.0936
	# The real failure had car 6 and car 8 exactly tied at progress 7.0936,
	# lanes +1.555/-1.555, a narrowing track ahead and 22 blocked followers.
	var cars: Array = [
		{"id":6, "progress":start, "race_lane":1.555,
			"finished":false, "pit_left":0.0, "combat_hesitation_s":0.0},
		{"id":8, "progress":start, "race_lane":-1.555,
			"finished":false, "pit_left":0.0, "combat_hesitation_s":0.0},
	]
	var immutable: PackedByteArray = var_to_bytes(cars)
	var metrics: Dictionary = {6:{"target":100.0},8:{"target":100.0}}
	var forward: Dictionary = RaceSpace.plan(cars,metrics,0.2,track,shape,{},false,false)
	var reverse: Dictionary = RaceSpace.plan([cars[1],cars[0]],metrics,0.2,track,shape,{},false,false)
	verify(forward == reverse, "car array order cannot change tie resolution")
	verify(immutable == var_to_bytes(cars), "planner cannot mutate input snapshot")
	verify(forward.has(6) and forward.has(8), "both cars must have a real spatial plan")
	if forward.has(6) and forward.has(8):
		verify(float(forward[6]["progress"]) > start
			and is_equal_approx(float(forward[8]["progress"]),start),
			"one deterministic ID wins the tie; other driver yields")
		verify(float(forward[6]["progress"]) <= start + 0.2 / 100.0 + 0.000001,
			"priority cannot teleport the winning car")
		verify(absf(float(forward[6]["states"]["race_lane"]) -
			float(forward[8]["states"]["race_lane"])) >= RaceSpace.WIDTH,
			"priority preserves lateral separation")
	var repeat_final: Array = []
	for repetition in range(2):
		var live: Array = cars.duplicate(true)
		for tick in range(30):
			var result: Dictionary = RaceSpace.plan(live,metrics,0.2,track,shape,{},false,false)
			for car in live:
				var key: int = int(car["id"])
				car["progress"] = float(result[key]["progress"])
				car["race_lane"] = float(result[key]["states"]["race_lane"])
		var final_state: Array = [float(live[0]["progress"]),float(live[1]["progress"])]
		repeat_final.append(final_state)
		verify(final_state[0] > start and final_state[1] > start,
			"both drivers must advance after the deterministic tie is released")
	verify(repeat_final.size() == 2 and repeat_final[0] == repeat_final[1],
		"two independent spatial traces must be deterministic")
	if errors.is_empty():
		print("APEX_MONACO_DEADLOCK_099_PASS cars=2 repeat=2")
		quit(0)
	else:
		quit(1)
