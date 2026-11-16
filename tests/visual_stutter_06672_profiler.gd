extends SceneTree
const Perf = preload("res://scripts/debug/apex_perf_trace_0657.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(4): await process_frame
	host.set_process(false)
	for i in range(host.season_tracks.size()):
		if host.season_tracks[i].code == "MON": host.selected_track_index = i
	host._start_race()
	host.race.running = true
	Perf.reset({"scenario":"MON 24-car visual recovery"})
	Perf.set_enabled(true)
	for tick in range(100):
		host.race.step(.5)
		var cars: Array = host.race.cars.duplicate(true)
		for c in cars:
			c.route_point = host.map_view.point_on_track(c.progress)
			c.route_direction = host.map_view.direction_on_track(c.progress)
		host.world_view.set_race_cars(cars,-1,.5)
	Perf.set_enabled(false)
	var snap: Dictionary = Perf.snapshot()
	var stalled: int = int(snap.counters.get("visual.occupancy_stalled_car_frames",0))
	var recovered: int = int(snap.counters.get("visual.occupancy_recovered_car_frames",0))
	var calls: int = int(snap.sections.get("visual.occupancy",{}).get("calls",0))
	if calls != 100 or stalled <= 0 or recovered <= 0:
		printerr("VISUAL_06672_PROFILER_FAIL ", {"calls":calls,"stalled":stalled,"recovered":recovered})
		quit(1)
		return
	print("VISUAL_06672_PROFILER_PASS ",JSON.stringify({"calls":calls,"stalled_car_frames":stalled,"recovered_car_frames":recovered}))
	quit(0)
