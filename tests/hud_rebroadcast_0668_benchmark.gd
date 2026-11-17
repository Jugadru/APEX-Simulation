extends SceneTree
## Apples-to-apples HEADLESS CPU HUD workload; fixed seed, fixed race state.
## Deliberately no FPS claim: runs against 200 read-only HUD refreshes.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1600,900)
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await process_frame
	host.set_process(false)
	host.seed_picker.value = 1208
	for i in range(host.season_tracks.size()):
		if str(host.season_tracks[i].get("code","")) == "GBR":
			host.selected_track_index = i
			break
	if host.weather_mode_picker != null:
		for i in range(host.weather_mode_picker.item_count):
			if host.weather_mode_picker.get_item_text(i) == "Seco":
				host.weather_mode_picker.select(i)
				break
	host._start_race()
	var hud = host.race_hud_0620
	var cars_before: Array = host.race.cars.duplicate(true)
	for i in range(8): hud.refresh_hud()
	var start: int = Time.get_ticks_usec()
	for i in range(200): hud.refresh_hud()
	var elapsed_usec: int = Time.get_ticks_usec() - start
	if host.race.cars != cars_before:
		printerr("FAIL: HUD refresh mutated sporting cars")
		quit(1); return
	var flavor: String = OS.get_environment("APEX_BENCH_FLAVOR")
	print("HUD_BENCH_RESULT ", JSON.stringify({
		"flavor": flavor, "seed":1208, "track":"GBR", "weather":"dry", "resolution":"1600x900",
		"hud_refreshes":200, "microseconds_total":elapsed_usec,
		"microseconds_per_refresh":float(elapsed_usec)/200.0,
		"memory_static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"sporting_unchanged":true
	}))
	quit(0)
