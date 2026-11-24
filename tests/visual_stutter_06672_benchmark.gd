extends SceneTree
const R = preload("res://scripts/apex_racecraft_0654.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(5): await process_frame
	host.set_process(false)
	var selected_seed := int(OS.get_environment("APEX_MOTION_SEED")) if OS.has_environment("APEX_MOTION_SEED") else 42
	host.seed_picker.value = selected_seed
	var results: Array = []
	for code in ["GBR", "MON", "BEL", "SIN"]:
		for i in range(host.season_tracks.size()):
			if str(host.season_tracks[i].code) == code: host.selected_track_index = i
		host._start_race()
		host.race.running = true
		# Record the actual fixture state: FAST shares user saves with earlier tests.
		var fixture: Dictionary = {"track":code,"requested_seed":selected_seed,"picker_seed":int(host.seed_picker.value),"championship":host.championship_mode,"team":host.selected_team,"weather":host.race.weather_snapshot(),"levels":host.garage.get_team(host.selected_team)["levels"].duplicate(true),"staff":host.garage.effective_staff_levels(host.selected_team),"crew":host.garage.effective_crew_levels(host.selected_team),"initial_hash":Codec.sporting_hash(host.race,{})}
		print("RACE_MOTION_FIXTURE ",JSON.stringify(fixture))
		# Reconstruct the same official grid using the original visual envelope.
		var grid: Array = host.race.cars.duplicate(true)
		for car in grid:
			car.route_point = host.map_view.point_on_track(car.progress)
			car.route_direction = host.map_view.direction_on_track(car.progress)
		host.world_view.pose_anchors.clear()
		var baseline: Dictionary = R.solve(grid,{},0.0,host.world_view._sample_occupied_pose_legacy,INF,false)
		var worst_jump: Dictionary = {}
		var baseline_max_step := 0.0
		var baseline_max_resync_step := 0.0
		var baseline_resync := 0
		var baseline_held := 0
		var baseline_stationary := 0
		var baseline_longest := 0
		var baseline_collisions := 0
		var baseline_runs: Dictionary = {}
		var times: Array = []
		var held: int = 0
		var longest: int = 0
		var runs: Dictionary = {}
		var collisions: int = 0
		var collisions_detail: Array = []
		var max_lag: float = 0.0
		var lag_count: int = 0
		var reported: Array = []
		var stationary_runs: Dictionary = {}
		var previous_positions: Dictionary = {}
		var max_stationary := 0
		var stationary_samples := 0
		var resynced_samples := 0
		var max_frame_distance := 0.0
		var max_resync_distance := 0.0
		var motion_distances: Array = []
		for tick in range(125):
			host.race.step(.5)
			var cars: Array = host.race.cars.duplicate(true)
			for c in cars:
				c.route_point = host.map_view.point_on_track(c.progress)
				c.route_direction = host.map_view.direction_on_track(c.progress)
			var before := JSON.stringify(cars)
			var start := Time.get_ticks_usec()
			host.world_view.set_race_cars(cars,-1,.5)
			times.append(Time.get_ticks_usec() - start)
			if JSON.stringify(cars) != before: failures += 1
			var poses: Dictionary = host.world_view.occupation
			# Exactly the same authoritative snapshots and geometry for both solvers.
			var prior_baseline := baseline
			baseline = R.solve(cars,prior_baseline,.5,host.world_view._sample_occupied_pose_legacy,INF,false)
			for id in baseline:
				var legacy_pose: Dictionary = baseline[id]
				for other in baseline:
					if int(id) < int(other) and R.overlaps(legacy_pose,baseline[other]): baseline_collisions += 1
				if bool(legacy_pose.get("resynced",false)): baseline_resync += 1
				if bool(legacy_pose.get("held",false)):
					baseline_held += 1
					baseline_runs[id] = int(baseline_runs.get(id,0))+1
					baseline_longest = maxi(baseline_longest,int(baseline_runs[id]))
				else: baseline_runs[id] = 0
				if tick > 0 and prior_baseline.has(id):
					var legacy_step := Vector2(legacy_pose.position).distance_to(Vector2(prior_baseline[id].position))
					baseline_max_step = maxf(baseline_max_step,legacy_step)
					if bool(legacy_pose.get("resynced",false)):
						baseline_max_resync_step = maxf(baseline_max_resync_step,legacy_step)
					if legacy_step < 0.015: baseline_stationary += 1
			for id in poses:
				var p: Dictionary = poses[id]
				if bool(p.get("resynced",false)): resynced_samples += 1
				if previous_positions.has(id):
					var displacement: float = Vector2(p.position).distance_to(previous_positions[id])
					if displacement > max_frame_distance:
						max_frame_distance = displacement
						worst_jump = {"tick":tick,"id":id,"step":displacement,"pose":str(p)}
					motion_distances.append(displacement)
					if bool(p.get("resynced",false)): max_resync_distance = maxf(max_resync_distance,displacement)
				if previous_positions.has(id) and Vector2(p.position).distance_to(previous_positions[id]) < 0.015:
					stationary_runs[id] = int(stationary_runs.get(id,0)) + 1
					stationary_samples += 1
					max_stationary = maxi(max_stationary,int(stationary_runs[id]))
				else: stationary_runs[id] = 0
				previous_positions[id] = p.position
				if bool(p.get("held",false)):
					held += 1
					runs[id] = int(runs.get(id, 0)) + 1
					longest = maxi(longest, int(runs[id]))
					if int(runs[id]) == 20:
						reported.append({"tick": tick, "id": id, "progress": p.get("progress"), "position": str(p.get("position"))})
				else: runs[id] = 0
				for other in poses:
					if id < other and R.overlaps(p,poses[other]):
						collisions += 1
						collisions_detail.append({"tick":tick,"id":id,"other":other,"p":str(p.position),"q":str(poses[other].position),"prog_a":p.progress,"prog_b":poses[other].progress,"old_a":p.get("resynced"),"old_b":poses[other].get("resynced")})
			for c in cars:
				var id: int = int(c.id)
				if poses.has(id):
					var lag: float = float(c.progress)-float(poses[id].progress)
					max_lag=maxf(max_lag,lag)
					if lag>.001: lag_count += 1
		# Deterministic acceptance gates. Timing remains observational: no FPS promises.
		if collisions != 0 or max_stationary > 2 or (code in ["MON","BEL"] and stationary_samples >= 120):
			failures += 1
			printerr("VISUAL_STUTTER_FAIL ", code, " collisions=", collisions, " stationary=", stationary_samples, " longest=", max_stationary)
		times.sort()
		motion_distances.sort()
		var total: int = 0
		for t in times: total += int(t)
		results.append({"code":code,"seed":int(host.seed_picker.value),"ticks":times.size(),"mean_us":float(total)/float(times.size()),"p95_us":times[int(floor(float(times.size()-1)*.95))],"p99_us":times[int(floor(float(times.size()-1)*.99))],"max_us":times[-1],"held":held,"stationary_samples":stationary_samples,"max_stationary":max_stationary,"max_step_meters":max_frame_distance,"max_resync_step_meters":max_resync_distance,"p95_step_meters":motion_distances[int(floor(float(motion_distances.size()-1)*.95))] if not motion_distances.is_empty() else 0.0,"resynced":resynced_samples,"baseline_max_step":baseline_max_step,"worst_jump":worst_jump,"baseline_max_resync_step":baseline_max_resync_step,"baseline_resynced":baseline_resync,"baseline_held":baseline_held,"baseline_stationary":baseline_stationary,"baseline_longest_held":baseline_longest,"baseline_collisions":baseline_collisions,"longest_held_consecutive":longest,"collisions":collisions,"collisions_detail":collisions_detail,"max_progress_lag":max_lag,"lag_count":lag_count,"long_holds":reported})
	# Paired quality gate: no new collisions or old stationary violations;
	# Actual improvement must occur in Monaco and the worst jump must not grow.
	# Other venues must not regress in worst jump (small float tolerance).
	var quality_failures: Array[String] = []
	for row in results:
		if float(row.max_step_meters) > float(row.baseline_max_step) + 0.01:
			quality_failures.append(str(row.code)+": worst visual jump increased")
		if str(row.code) == "MON":
			if selected_seed == 42 and int(row.resynced) >= int(row.baseline_resynced) and float(row.max_step_meters) >= float(row.baseline_max_step)-0.01:
				quality_failures.append("MON: no reduction in emergency resyncs or worst jump")
			if int(row.stationary_samples) > int(row.baseline_stationary):
				quality_failures.append("MON: stationary samples increased")
			if int(row.longest_held_consecutive) > int(row.baseline_longest_held):
				quality_failures.append("MON: consecutive visual lag increased")
	for reason in quality_failures:
		printerr("RACE_MOTION_09173_QUALITY_FAIL ",reason)
	failures += quality_failures.size()
	print("VISUAL_STUTTER_06672_BENCHMARK ",JSON.stringify({"results":results,"failures":failures,"quality_failures":quality_failures}))
	quit(0 if failures == 0 else 1)
