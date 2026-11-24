extends SceneTree
const R = preload("res://scripts/apex_racecraft_0654.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var h = load("res://scenes/main.tscn").instantiate()
	root.add_child(h)
	for i in range(5): await process_frame
	h.set_process(false)
	var reports: Array = []
	for code in ["GBR","MON","ITA","BEL","SIN"]:
		for i in range(h.season_tracks.size()):
			if h.season_tracks[i].code==code: h.selected_track_index=i
		h._start_race()
		h.race.running=false
		h._process(0.0)
		var draw: Array = h.presentation.build(h.race.cars,h.selected_team,h.map_view,0.0,false)
		h.world_view.set_race_cars(draw,-1,0.0)
		var slots: Dictionary = h.world_view.grid_slots
		var poses: Dictionary = h.world_view.occupation
		var max_error := 0.0
		var max_model_error := 0.0
		var max_mark_error := 0.0
		var max_lane_error := 0.0
		var max_progress_error := 0.0
		var misaligned: Array = []
		var overlaps := 0
		for car in h.race.cars:
			var id := int(car.id)
			var slot := int(car.grid)
			if not slots.has(slot) or not poses.has(id) or not h.world_view.live_cars.has(id):
				failures += 1
				continue
			var pose: Dictionary = poses[id]
			var mark: Node3D = h.world_view.course_root.get_node_or_null("StartingGrid/P%02d" % slot)
			if mark == null:
				failures += 1
				continue
			max_mark_error = maxf(max_mark_error,Vector2(mark.position.x,mark.position.z).distance_to(Vector2(slots[slot].position)))
			max_lane_error = maxf(max_lane_error,absf(float(pose.lane)-float(car.race_lane)))
			max_progress_error = maxf(max_progress_error,absf(float(pose.progress)-float(car.progress)))
			var error := Vector2(pose.position).distance_to(Vector2(slots[slot].position))
			var model: Node3D = h.world_view.live_cars[id]
			var model_error := Vector2(model.position.x,model.position.z).distance_to(Vector2(slots[slot].position))
			max_error = maxf(max_error,error)
			max_model_error = maxf(max_model_error,model_error)
			if error > 0.05 or model_error > 0.05:
				misaligned.append({"slot":slot,"id":id,"error":error,"model_error":model_error,"official_lane":car.race_lane,"visual_lane":pose.lane})
			for other in poses:
				if id < int(other) and R.overlaps(pose,poses[other]): overlaps += 1
		# Check the painted stripe itself, including pole nose and both front corners.
		var stripe: MeshInstance3D = h.world_view.course_root.get_node_or_null("StartFinishLine")
		var clearance := -1.0
		if stripe != null and slots.has(1):
			var pole: Dictionary = slots[1]
			var forward := Vector2(-stripe.basis.z.x,-stripe.basis.z.z).normalized()
			var center := Vector2(stripe.position.x,stripe.position.z)
			var direction := Vector2(pole.direction)
			var side := R.normal(direction)
			var min_gap := INF
			for lateral in [-1.0,1.0]:
				var nose := Vector2(pole.position)+direction*float(pole.half_length)+side*float(pole.half_width)*lateral
				min_gap=minf(min_gap,(center-nose).dot(forward)-(stripe.mesh as BoxMesh).size.z*0.5)
			clearance=min_gap
		if clearance<0.10: failures+=1
		if slots.size()!=24 or poses.size()!=24 or not misaligned.is_empty() or overlaps>0 or max_mark_error>0.05:
			failures += 1
		reports.append({"track":code,"slots":slots.size(),"poses":poses.size(),"max_slot_error":max_error,"max_model_error":max_model_error,"max_mark_error":max_mark_error,"max_lane_error":max_lane_error,"max_progress_error":max_progress_error,"overlaps":overlaps,"misaligned":misaligned,"pole_nose_clearance":clearance,"pole_progress":h.race.get_sorted()[0].progress})
	print("GRID_PLACEMENT_09173_REPORT ",JSON.stringify({"cases":reports,"failures":failures}))
	if failures==0: print("GRID_PLACEMENT_09173_PASS")
	quit(0 if failures==0 else 1)
