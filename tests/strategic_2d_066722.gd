extends SceneTree
## Checks Auto camera policy, manual overrides and real CanvasItem static caching.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(4): await process_frame
	host.set_process(false)
	host._start_race()
	assert(host.visual_setting == 0 and host.visual_picker.selected == 0)
	assert(host.render_mode == 1 and host.world_container.visible)
	assert(host.sim_speed == 1.0)
	for index in [0,1,2]:
		host._change_speed(index)
		assert(host.render_mode == 1 and host.world_container.visible, "1x/2x/5x Auto -> 3D")
	for index in [3,4,5]:
		host._change_speed(index)
		assert(host.render_mode == 0 and host.map_view.visible, "10x/16x/32x Auto -> 2D")
		assert(not host.world_container.visible, "No 3D viewport when strategic map active")
	assert(host.map_view.static_layer != null)
	# Manual camera always wins, including when speed crosses the 10x boundary.
	host._change_visual_setting(2)
	host._change_speed(0)
	assert(host.render_mode == 1)
	host._change_speed(5)
	assert(host.render_mode == 1 and host.world_container.visible, "Manual 3D 32x")
	host._change_visual_setting(1)
	host._change_speed(0)
	assert(host.render_mode == 0 and host.map_view.visible, "Manual 2D 1x")
	host.race_hud_0620._choose_auto_view_window()
	assert(host.visual_setting == 0 and host.render_mode == 1, "HUD restores Auto 3D at 1x")
	host._change_speed(3)
	assert(host.render_mode == 0)
	for i in range(4): await process_frame
	var layer = host.map_view.static_layer
	var base_count: int = layer.draw_count
	var dyn_before: int = host.map_view.dynamic_draw_count
	for i in range(12):
		var cars: Array = [{"id":-i-1,"progress":0.01 * float(i),"player":false,"color":"#ffffff"}]
		host.map_view.set_race_cars(cars,-i-1)
		await process_frame
	assert(host.map_view.dynamic_draw_count > dyn_before, "Cars still redraw in 2D")
	assert(layer.draw_count == base_count, "Track should not redraw for moving cars")
	# Track changes are the only expensive cache invalidation.
	host.map_view.set_track_data(host.race.track)
	await process_frame
	assert(layer.draw_count > base_count, "New circuit invalidates static cache")
	var after_track: int = layer.draw_count
	host.map_view.set_view_mode(1)
	await process_frame
	assert(layer.draw_count > after_track, "Explicit map mode invalidates cache")
	host.map_view.set_view_mode(0)
	await process_frame
	assert(layer.draw_count > after_track + 1)
	# 32x still advances deterministic sporting ticks; do not skip calculations.
	host.race.running = true
	host._change_speed(5)
	var start: int = Time.get_ticks_msec()
	var tick_before: int = host.replay_session.tick
	for i in range(10): host._process(1.0/60.0)
	var actual_ticks: int = host.replay_session.tick - tick_before
	# 066723: high-speed CPU work is budgeted. The selected 32x is a target;
	# the frame scheduler can run fewer ticks when the machine is saturated.
	assert(actual_ticks >= 10 and actual_ticks <= 27, "Budgeted 32x must simulate real ticks without skipping")
	assert(host.replay_session.accumulator <= 1.200001, "No runaway backlog in high speed")
	assert(host.replay_session.hashes.size() == host.replay_session.tick, "Every sporting tick hashed")
	assert(host.render_mode == 0)
	var report: Dictionary = {"pass":true,"track_static_draws":layer.draw_count,"dynamic_draws":host.map_view.dynamic_draw_count,"cached_car_updates":12,"sporting_ticks_32x":actual_ticks,"wall_ms_10_frames_32x":Time.get_ticks_msec()-start,"auto_fast_map":true,"manual_overrides":true}
	print("STRATEGIC_2D_066722_PASS ",JSON.stringify(report))
	quit(0)
