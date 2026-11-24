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
		var slots: Dictionary = h.world_view.grid_slots
		var poses: Dictionary = h.world_view.occupation
		var max_error := 0.0
		var max_model_error := 0.0
		var misaligned: Array = []
		var overlaps := 0
		for car in h.race.cars:
			var id := int(car.id)
			var slot := int(car.grid)
			if not slots.has(slot) or not poses.has(id) or not h.world_view.live_cars.has(id):
				failures += 1
				continue
			var pose: Dictionary = poses[id]
			var error := Vector2(pose.position).distance_to(Vector2(slots[slot].position))
			var model: Node3D = h.world_view.live_cars[id]
			var model_error := Vector2(model.position.x,model.position.z).distance_to(Vector2(slots[slot].position))
			max_error = maxf(max_error,error)
			max_model_error = maxf(max_model_error,model_error)
			if error > 0.05 or model_error > 0.05:
				misaligned.append({"slot":slot,"id":id,"error":error,"model_error":model_error,"official_lane":car.race_lane,"visual_lane":pose.lane})
			for other in poses:
				if id < int(other) and R.overlaps(pose,poses[other]): overlaps += 1
		if slots.size()!=24 or poses.size()!=24 or not misaligned.is_empty() or overlaps>0:
			failures += 1
		reports.append({"track":code,"slots":slots.size(),"poses":poses.size(),"max_slot_error":max_error,"max_model_error":max_model_error,"overlaps":overlaps,"misaligned":misaligned,"pole_progress":h.race.get_sorted()[0].progress})
	print("GRID_PLACEMENT_09173_REPORT ",JSON.stringify({"cases":reports,"failures":failures}))
	if failures==0: print("GRID_PLACEMENT_09173_PASS")
	quit(0 if failures==0 else 1)
