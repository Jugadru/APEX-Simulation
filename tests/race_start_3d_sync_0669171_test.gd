extends SceneTree
## v0.6.6.9.17.1 - fail-closed first-lap presentation regression.
## Same native 24-car / .5-second / 125-frame fixture as visual_stutter_06672.
## Only presentation state is measured. No RaceEngine write or physics tuning.
const BattleMotion = preload("res://scripts/apex_racecraft_0654.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")

const CIRCUITS := ["GBR", "MON", "BEL", "SIN"]
const FRAMES := 125
const STEP := 0.5

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, reason: String) -> void:
	checks += 1
	if not condition:
		failures.append(reason)
		printerr("RACE_START_3D_SYNC_09171_FAIL " + reason)

func _run() -> void:
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(5):
		await process_frame
	host.set_process(false)
	var summary: Array[Dictionary] = []
	for code in CIRCUITS:
		for i in range(host.season_tracks.size()):
			if str(host.season_tracks[i].get("code", "")) == code:
				host.selected_track_index = i
		host._start_race()
		host.race.running = true
		var base_hash: String = ""
		var max_stationary := 0
		var previous_positions: Dictionary = {}
		var stationary_runs: Dictionary = {}
		var overlaps_found := 0
		var recovered := 0
		var stats: Dictionary = {}
		var duplicate_frame: Dictionary = {}
		_assert(host.race.cars.size() == 24, code + ": exactly 24 official cars")
		for tick in range(FRAMES):
			host.race.step(STEP)
			var cars: Array = host.race.cars.duplicate(true)
			for car in cars:
				car.route_point = host.map_view.point_on_track(car.progress)
				car.route_direction = host.map_view.direction_on_track(car.progress)
			var pre_input: PackedByteArray = var_to_bytes(cars)
			base_hash = Codec.sporting_hash(host.race, {})
			var before: Dictionary = host.world_view.occupation.duplicate(true)
			host.world_view.set_race_cars(cars, -1, STEP)
			var poses: Dictionary = host.world_view.occupation
			_assert(poses.size() == 24, "%s tick %d: exactly 24 visual poses" % [code, tick])
			if var_to_bytes(cars) != pre_input:
				_assert(false, "%s tick %d: input race dictionaries were mutated" % [code, tick])
			if Codec.sporting_hash(host.race, {}) != base_hash:
				_assert(false, "%s tick %d: visual presentation altered sporting hash" % [code, tick])
			for id in poses:
				var pose: Dictionary = poses[id]
				_assert(bool(pose.get("visible", false)),
					"%s tick %d id %s: car hidden" % [code, tick, str(id)])
				if bool(pose.get("resynced",false)):
					recovered += 1
				if previous_positions.has(id):
					if Vector2(pose.position).distance_to(previous_positions[id]) < 0.015:
						stationary_runs[id] = int(stationary_runs.get(id, 0)) + 1
					else:
						stationary_runs[id] = 0
					max_stationary = maxi(max_stationary, int(stationary_runs[id]))
				else:
					stationary_runs[id] = 0
				previous_positions[id] = pose.position
				for other in poses:
					if int(id) >= int(other):
						continue
					if BattleMotion.overlaps(pose, poses[other]):
						overlaps_found += 1
						var a: Dictionary = before.get(id, {})
						var b: Dictionary = before.get(other, {})
						var report := {"track":code,"tick":tick,
							"id":id,"other":other,
							"pose_a":str(pose),"pose_b":str(poses[other]),
							"old_a":str(a),"old_b":str(b),
							"car_a":str(cars.filter(func(c): return int(c.id)==id)[0].get("race_lane", 0.0)),
							"car_b":str(cars.filter(func(c): return int(c.id)==other)[0].get("race_lane", 0.0))}
						printerr("APEX_3D_SYNC_COLLISION ", JSON.stringify(report))
		_assert(overlaps_found == 0, code + ": no 3D car model overlaps (%d)" % overlaps_found)
		_assert(max_stationary <= 2, code + ": no visual holds >2 frames (%d)" % max_stationary)
		stats = {"track":code,"frames":FRAMES,"cars":24,
			"overlaps":overlaps_found,"max_stationary":max_stationary,"resynced":recovered}
		summary.append(stats)
	print("APEX_START_3D_SYNC_09171_REPORT ",JSON.stringify(summary))
	if failures.is_empty():
		print("RACE_START_3D_SYNC_09171_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)
