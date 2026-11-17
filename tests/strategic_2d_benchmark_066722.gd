extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m = load("res://scripts/track_map.gd").new()
	root.add_child(m)
	for k in range(5): await process_frame
	assert(not m.route.is_empty())
	var frames: int = 180
	var begin: int = Time.get_ticks_usec()
	for k in range(frames):
		var cars: Array = []
		for i in range(24):
			cars.append({"id": i,"progress":fposmod(float(i)/24.0 + float(k)*0.0002,1.0),"color":"#ffffff","player":i<2})
		m.set_race_cars(cars,k%24)
		await process_frame
	var elapsed: int = Time.get_ticks_usec() - begin
	print("STRATEGIC_2D_BENCH ", JSON.stringify({"frames":frames,"wall_ms":float(elapsed)/1000.0,"static_draw_count":m.get("static_layer").draw_count if m.get("static_layer") != null else -1,"dynamic_draw_count":int(m.get("dynamic_draw_count")) if m.get("dynamic_draw_count") != null else -1,"route_points":m.route.size()}))
	quit()
